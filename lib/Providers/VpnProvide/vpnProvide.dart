// ignore_for_file: file_names, use_build_context_synchronously, unnecessary_brace_in_string_interps
import 'dart:developer' show log;
import 'package:flutter/material.dart';
import 'package:flutter_singbox/flutter_singbox.dart' show FlutterSingbox;
import 'package:http/http.dart' as http;
import 'dart:io' show Platform, InternetAddress;
import 'dart:async' show Timer, TimeoutException;
import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:tytan/DataModel/plansModel.dart';
import 'package:tytan/DataModel/userModel.dart';
import 'package:tytan/Defaults/utils.dart';
import 'package:tytan/DataModel/serverDataModel.dart';
import 'package:tytan/screens/auth/auth_screen.dart';
import 'package:tytan/NetworkServices/networkOpenVpn.dart';
import 'package:tytan/ReusableWidgets/customSnackBar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart' show OpenVPN;
import 'package:tytan/NetworkServices/networkSingbox.dart' show NetworkSingbox;

import '../../NetworkServices/networkVless.dart';

enum Protocol { vless }

enum VpnStatusConnectionStatus {
  connected,
  disconnected,
  connecting,
  disconnecting,
  reconnecting,
}

class VpnProvide with ChangeNotifier {
  var vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;

  Protocol selectedProtocol = Protocol.vless;
  // final Wireguardservices _wireguardService = Wireguardservices();
  OVPNEngine openVPN = OVPNEngine();
  // final NetworkSingbox _singboxService = NetworkSingbox();
  var isloading = false;
  var selectedServerIndex = 0;
  var protocol = Protocol.vless;
  var selectedSubServerIndex = 0;
  var servers = <Server>[];
  var filterServers = <Server>[];
  var isPremium = false;
  var plans = <PlanModel>[];
  //make the user varaible type user
  var user = <UserModel>{};
  var downloadSpeed = "0.0";
  var uploadSpeed = "0.0";
  var pingSpeed = "0.0";
  final NetworkSingbox singboxService = NetworkSingbox();
  final FlutterSingbox _singbox = FlutterSingbox();


  // Connection duration timer
  Duration connectedDuration = Duration.zero;
  Timer? _connectionDurationTimer;

  static const String favoriteServersPrefsKey = 'favorite_server_ids';
  var favoriteServerIds = <int>{};
  var favoritesFilterActive = false;

  var messageController = TextEditingController();
  var subjectController = TextEditingController();
  var emailController = TextEditingController();

  var autoConnectOn = false;
  var killSwitchOn = false;

  String queryText = '';
  bool queryActive = false;

  Timer? speedUpdateTimer;
  Timer? _stageTimer;

  bool autoSelectProtocol = false;
  bool _cancelRequested = false;

  init() {
    
  }

  void requestCancellation() {
    if (_cancelRequested) {
      return;
    }
    _cancelRequested = true;
    if (vpnConnectionStatus != VpnStatusConnectionStatus.disconnected) {
      vpnConnectionStatus = VpnStatusConnectionStatus.disconnecting;
      notifyListeners();
    }
  }

  autoC(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    autoConnectOn = prefs.getBool('autoConnect') ?? false;
    log(autoConnectOn.toString());
    if (autoConnectOn &&
        vpnConnectionStatus == VpnStatusConnectionStatus.disconnected) {
      await toggleVpn();
      log(autoConnectOn.toString());
      notifyListeners();
    } else if (vpnConnectionStatus == VpnStatusConnectionStatus.connected) {
      return;
    }
  }

  toggleAutoConnectState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    autoConnectOn = !autoConnectOn;
    log(autoConnectOn.toString());
    prefs.setBool('autoConnect', autoConnectOn);
    notifyListeners();
  }

  toggleKillSwitchState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    killSwitchOn = !killSwitchOn;
    log(killSwitchOn.toString());
    prefs.setBool('killSwitchOn', killSwitchOn);
    log("KillSwitch toggled: $killSwitchOn");
    notifyListeners();
  }

  myKillSwitch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    killSwitchOn = prefs.getBool('killSwitchOn') ?? false;
    notifyListeners();
  }

  myAutoConnect() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    autoConnectOn = prefs.getBool('autoConnect') ?? false;
    notifyListeners();
  }

  Future<void> selectFastestServerByHealth() async {
    if (servers.isEmpty) {
      log("No servers available to analyze.");
      return;
    }

    isloading = true;
    notifyListeners();

    int fastestIndex = 0;
    double highestScore = -1.0;

    for (int i = 0; i < servers.length; i++) {
      try {
        // Each server can have multiple subServers, so find the best among them
        final subServers = servers[i].subServers ?? [];
        for (var sub in subServers) {
          final vpsGroup = sub.vpsGroup;
          if (vpsGroup != null) {
            final score =
                double.tryParse(vpsGroup.servers![0].healthScore.toString()) ??
                0.0;
            if (score > highestScore) {
              highestScore = score;
              fastestIndex = i;
            }
          }
        }
      } catch (e) {
        log("Error checking health_score for server ${servers[i].name}: $e");
      }
    }

    selectedServerIndex = fastestIndex;
    await _saveSelectedServerIndex();

    isloading = false;
    notifyListeners();

    log(
      "Fastest server selected: ${servers[fastestIndex].name} (Health Score: $highestScore)",
    );
  }

  Future<bool> setProtocol(Protocol protocol) async {
    if (selectedProtocol == protocol) {
      return true;
    }

    if (vpnConnectionStatus != VpnStatusConnectionStatus.disconnected) {
      log('Protocol change blocked: VPN must be disconnected.');
      notifyListeners();
      return false;
    }

    selectedProtocol = protocol;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedProtocol', protocol.name);

    notifyListeners();
    //  startGettingStages();
    return true;
  }

  Future<bool> setAutoSelectProtocol(bool value) async {
    if (value &&
        vpnConnectionStatus != VpnStatusConnectionStatus.disconnected) {
      log('Auto-select requires the VPN to be disconnected.');
      notifyListeners();
      return false;
    }

    if (autoSelectProtocol == value) {
      return true;
    }

    autoSelectProtocol = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoSelectProtocol', value);

    if (value) {
      final applied = await setProtocol(Protocol.vless);
      if (!applied) {
        autoSelectProtocol = false;
        await prefs.setBool('autoSelectProtocol', false);
        notifyListeners();
        return false;
      }
    }

    notifyListeners();
    return true;
  }

  Future<void> lProtocolFromStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? proto = prefs.getString('selectedProtocol');
    bool autoSelect = prefs.getBool('autoSelectProtocol') ?? false;
    log("Auto select protocol: $autoSelect");
    log("Saved protocol from storage: $proto");

    if (proto != null) {
      switch (proto.replaceFirst('Protocol.', '')) {
        case 'vless':
          selectedProtocol = Protocol.vless;
          break;
      }
    } else {
      selectedProtocol = Protocol.vless;
    }

    autoSelectProtocol = autoSelect;
    if (autoSelectProtocol) {
      selectedProtocol = Protocol.vless;
    }

    log("Restored protocol: ${selectedProtocol}");
    notifyListeners();
    // startGettingStages();
  }

  // make me a function to load the selectedserverindex from sharedpreference
  Future<void> loadSelectedServerIndex() async {
    final prefs = await SharedPreferences.getInstance();
    selectedServerIndex = prefs.getInt('selected_server_index') ?? 0;
    notifyListeners();
  }

  void setSelectedServerIndex(int index) {
    selectedServerIndex = index;
    _saveSelectedServerIndex();
    notifyListeners();
  }

  Future<void> _saveSelectedServerIndex() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_server_index', selectedServerIndex);
  }

  // Set query text and filter list
  void setQueryText(String text) {
    queryText = text;
    filterSrvList();
  }

  // Filter by search query only
  void filterSrvList() {
    List<Server> results = List.from(servers);

    syncFavoriteServersWithAvailableServers();

    if (queryText.trim().isNotEmpty) {
      results = results
          .where((s) => s.name.toLowerCase().contains(queryText.toLowerCase()))
          .toList();
      queryActive = true;
    } else {
      queryActive = false;
    }

    if (favoritesFilterActive) {
      results = results
          .where((server) => favoriteServerIds.contains(server.id))
          .toList();
    }

    results.sort((a, b) {
      final aFav = favoriteServerIds.contains(a.id);
      final bFav = favoriteServerIds.contains(b.id);

      if (aFav != bFav) {
        return aFav ? -1 : 1;
      }

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    filterServers = results;
    notifyListeners();
  }

  Future<void> loadFavoriteServers() async {
    final prefs = await SharedPreferences.getInstance();
    final storedIds =
        prefs.getStringList(favoriteServersPrefsKey) ?? <String>[];

    favoriteServerIds = storedIds
        .map((value) => int.tryParse(value))
        .whereType<int>()
        .toSet();

    filterSrvList();
  }

  Future<void> toggleFavoriteServer(int serverId) async {
    if (favoriteServerIds.contains(serverId)) {
      favoriteServerIds.remove(serverId);
    } else {
      favoriteServerIds.add(serverId);
    }

    await _persistFavoriteServers();
    filterSrvList();
  }

  bool isFavoriteServer(int serverId) {
    return favoriteServerIds.contains(serverId);
  }

  void setFavoritesFilter(bool value) {
    if (favoritesFilterActive == value) {
      return;
    }

    favoritesFilterActive = value;
    filterSrvList();
  }

  void toggleFavoritesFilter() {
    favoritesFilterActive = !favoritesFilterActive;
    filterSrvList();
  }

  Future<void> _persistFavoriteServers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      favoriteServersPrefsKey,
      favoriteServerIds.map((id) => id.toString()).toList(),
    );
  }

  void syncFavoriteServersWithAvailableServers() {
    if (servers.isEmpty) {
      return;
    }

    favoriteServerIds.retainWhere(
      (serverId) => servers.any((server) => server.id == serverId),
    );
  }

  bool _shouldAbortConnection() {
    if (!_cancelRequested) {
      return false;
    }
    _cancelRequested = false;
    log("Connection cancelled by user");
    vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;
    notifyListeners();
    return true;
  }

  Map<String, dynamic>? _parseJsonBody(http.Response response, String label) {
    try {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      log("$label returned unexpected JSON: ${decoded.runtimeType}");
    } catch (e) {
      final body = response.body;
      final preview = body.length > 120 ? body.substring(0, 120) : body;
      log(
        "$label returned non JSON (${response.statusCode}): ${preview.replaceAll('\n', ' ')}",
      );
    }
    return null;
  }

  Future<void> getServersPlease(bool net) async {
    isloading = true;
    notifyListeners();
    // Simulate a network call or data fetching
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('token');

      var platform = Platform.isAndroid
          ? "android"
          : Platform.isIOS
          ? "ios"
          : Platform.isWindows
          ? "windows"
          : Platform.isMacOS
          ? "macos"
          : "linux";

          
      if (net) {
        var headers = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        };
        var response = await http.get(
          Uri.parse("${UUtils.getServers}?platform=$platform&protocol=vless"),
          headers: headers,
        );

        var data = jsonDecode(response.body);
        log(data.toString());
        if (data['status'] == true) {
          servers = (data['servers'] as List)
              .map((e) => Server.fromJson(e))
              .toList();
          log('Servers: $servers');
          log(
            'Servers fetched successfully: ${servers.length} servers loaded.',
          );
          filterSrvList();
        } else {
          // Handle error
          log('Error: ${data['message']}');
          servers = [];
          filterSrvList();
        }
      }
    } catch (error) {
      log('Error: $error');

      isloading = false;
      servers = [];
      filterSrvList();
    } finally {
      isloading = false;
      notifyListeners();
    }
  }

  getRequiredServerDomain() {
    return servers[selectedServerIndex]
        .subServers![selectedSubServerIndex]
        .vpsGroup!
        .servers![0]
        .domain;
  }

  // startGettingStages() {
  //   log("Starting stage monitoring for ${selectedProtocol}");
  //   // Avoid spawning multiple timers
  //   // _stageTimer ??= Timer.periodic(const Duration(seconds: 1), (Timer t) async {
  //   //   if (selectedProtocol == Protocol.hysteria) {
  //   //     await listenHysteria();
  //   //   } else if (selectedProtocol == Protocol.vless) {
  //   //     await listenVless();
  //   //   }
  //   // });
  // }

  // Future<VpnStatusConnectionStatus> listenWireguard() async {
  //   try {
  //     VpnStatusConnectionStatus newStage = vpnConnectionStatus;
  //     final value = await _wireguardEngine.stage();
  //     if (value == VpnStage.connected) {
  //       newStage = VpnStatusConnectionStatus.connected;
  //     } else if (value == VpnStage.connecting || isloading) {
  //       newStage = VpnStatusConnectionStatus.connecting;
  //     } else if (value == VpnStage.disconnected) {
  //       newStage = VpnStatusConnectionStatus.disconnected;
  //     } else if (value == VpnStage.disconnecting) {
  //       newStage = VpnStatusConnectionStatus.disconnecting;
  //     } else {
  //       newStage = VpnStatusConnectionStatus.disconnected;
  //     }
  //     vpnConnectionStatus = newStage;
  //     log("WireGuard Stage: $vpnConnectionStatus");

  //     return newStage;
  //   } catch (e) {
  //     log("Error getting WireGuard stage: $e");
  //     vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;
  //     return VpnStatusConnectionStatus.disconnected;
  //   }
  // }

  listenStage() async {
    if (isloading) {
      log("OpenVPN is getting config, skipping stage check");
      // If OpenVPN is currently getting config set stage to connecting
      vpnConnectionStatus = VpnStatusConnectionStatus.connecting;
      return;
    }
    OpenVPN().stage().then((value) {
      log("OpenVPN Stage: ${value.name}");
      if (value.name == "connected") {
        vpnConnectionStatus = VpnStatusConnectionStatus.connected;
      } else if (value.name == "disconnected") {
        vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;
      } else if (value.name == "connecting") {
        vpnConnectionStatus = VpnStatusConnectionStatus.connecting;
      } else if (value.name == "disconnecting") {
        vpnConnectionStatus = VpnStatusConnectionStatus.disconnecting;
      } else if (value.name == "wait_connection") {
        vpnConnectionStatus = VpnStatusConnectionStatus.connecting;
      } else if (value.name == "getting_config") {
        vpnConnectionStatus = VpnStatusConnectionStatus.connecting;
      } else if (value.name == "authenticating") {
        vpnConnectionStatus = VpnStatusConnectionStatus.connecting;
      } else if (value.name == "waiting_for_server") {
        vpnConnectionStatus = VpnStatusConnectionStatus.connecting;
      } else if (value.name == "waiting_for_client") {
        vpnConnectionStatus = VpnStatusConnectionStatus.connecting;
      } else if (value.name == "get_config") {
        vpnConnectionStatus = VpnStatusConnectionStatus.connecting;
      } else if (value.name == "vpn_generate_config") {
        vpnConnectionStatus = VpnStatusConnectionStatus.connecting;
      } else {
        vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;
      }
    });
  }

  Future<bool> registerUserInVps(String serverUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? name = prefs.getString('name');
      final String? password = prefs.getString('password');

      if (_cancelRequested) {
        log("Registration aborted before start on $serverUrl");
        return false;
      }

      log("Name is $name");
      log("Password is $password");

      if (name == null || password == null) {
        log("Name or password is missing");
        return false;
      }

      final String platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : Platform.isLinux
          ? 'linux'
          : 'desktop';

      const headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-Token': 'a3f7b9c2-d1e5-4f68-8a0b-95c6e7f4d8a1',
      };

      log("Name_platform is that ${name}_$platform");
      log("Password is that $password");

      final firstResponse = await http
          .post(
            Uri.parse("$serverUrl/api/clients/generate"),
            headers: headers,
            body: jsonEncode({"name": "${name}_$platform"}),
          )
          .timeout(const Duration(seconds: 10));

      if (_cancelRequested) {
        log("Registration aborted after initial request on $serverUrl");
        return false;
      }

      final thirdResponse = await http
          .post(
            Uri.parse("$serverUrl/api/openvpn/clients/${name}_$platform"),
            headers: headers,
            body: jsonEncode({"password": password}),
          )
          .timeout(const Duration(seconds: 10));

      if (_cancelRequested) {
        log("Registration aborted after OpenVPN request on $serverUrl");
        return false;
      }

      log(
        "Initial registration response ${firstResponse.statusCode}: ${firstResponse.body}",
      );

      final Map<String, dynamic>? firstBody = _parseJsonBody(
        firstResponse,
        "WireGuard registration",
      );
      final Map<String, dynamic>? thirdBody = _parseJsonBody(
        thirdResponse,
        "OpenVPN registration",
      );

      final bool initialSuccess =
          firstResponse.statusCode == 200 &&
          firstBody != null &&
          (firstBody["error"] == null) &&
          (firstBody["success"] == true || firstBody.containsKey("config"));

      if (initialSuccess) {
        log("Registered successfully on $serverUrl (initial attempt)");
        return true;
      }

      if (firstBody == null || firstBody["error"] == null) {
        log("Registration failed on $serverUrl: unexpected response");
      }

      final deleteResponse = await http
          .delete(
            Uri.parse("$serverUrl/api/clients/${name}_$platform"),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));
      log("Status wireguard ${deleteResponse.statusCode}");
      log("Status body ${deleteResponse.body}");

      if (deleteResponse.statusCode != 200) {
        log("Unable to delete existing client on $serverUrl");
        return false;
      }

      if (_cancelRequested) {
        log("Registration aborted before retry on $serverUrl");
        return false;
      }

      final newResponse = await http
          .post(
            Uri.parse("$serverUrl/api/clients/generate"),
            headers: headers,
            body: jsonEncode({
              "name": "${name}_$platform",
              "password": password,
            }),
          )
          .timeout(const Duration(seconds: 10));
      log("Response is that ${newResponse.body}");

      final Map<String, dynamic>? responseBody = _parseJsonBody(
        newResponse,
        "WireGuard re-registration",
      );

      final bool registrationSuccess =
          newResponse.statusCode == 200 &&
          responseBody != null &&
          (responseBody["success"] == true ||
              responseBody.containsKey("config"));

      if (registrationSuccess) {
        log("Registered successfully on $serverUrl");
        return true;
      }

      if (thirdBody != null) {
        log("Third body is that ${thirdBody["error"]}");
      }
      if (_cancelRequested) {
        log("Registration aborted before OpenVPN cleanup on $serverUrl");
        return false;
      }

      if (thirdBody != null &&
          (thirdBody["error"] != null || thirdBody["error"] == "")) {
        log("OpenVPN error: ${thirdBody["error"]}");
        log(
          "Deleting existing OpenVPN client for ${name}_$platform on $serverUrl",
        );
        final deleteResponse = await http
            .delete(
              Uri.parse("$serverUrl/api/openvpn/clients/${name}_$platform"),
              headers: headers,
            )
            .timeout(const Duration(seconds: 10));

        if (deleteResponse.statusCode == 200) {
          if (_cancelRequested) {
            log(
              "Registration aborted before OpenVPN re-register on $serverUrl",
            );
            return false;
          }

          final newResponse = await http
              .post(
                Uri.parse("$serverUrl/api/openvpn/clients/${name}_$platform"),
                headers: headers,
                body: jsonEncode({"password": password}),
              )
              .timeout(const Duration(seconds: 10));

          log("Response is that ${newResponse.body}");

          final Map<String, dynamic>? newOpenVpnResponse = _parseJsonBody(
            newResponse,
            "OpenVPN re-registration",
          );
          if (newOpenVpnResponse != null &&
              newOpenVpnResponse["success"] == true) {
            log("Registered successfully on $serverUrl");
            return true;
          } else {
            log("❌ Registration failed on $serverUrl");
            return false;
          }
        }
      }

      log("Registration failed on $serverUrl");
      return false;
    } on TimeoutException catch (e) {
      log("Registration timed out on $serverUrl: $e");
      return false;
    } catch (e) {
      log("Exception during registration on $serverUrl: $e");
      return false;
    }
  }

  toggleVpn() async {
    var domain = getRequiredServerDomain();
    log("Domain: $domain");

    if (selectedProtocol == Protocol.vless) {
      if (vpnConnectionStatus == VpnStatusConnectionStatus.disconnected ||
          vpnConnectionStatus == VpnStatusConnectionStatus.disconnecting) {
        connectHysteriaVlessWireGuard();
      } else {
        disconnectHysteriaVlessWireGuard();
      }
    }
  }

  connectHysteriaVlessWireGuard() async {
    log("Starting Singbox connection for ${selectedProtocol.name}");

    // Prevent rapid connection attempts
    if (vpnConnectionStatus == VpnStatusConnectionStatus.connecting) {
      log("Already connecting, ignoring duplicate request");
      return;
    }

    try {
      // Set status to connecting
      //  = true;
      vpnConnectionStatus = VpnStatusConnectionStatus.connecting;
      notifyListeners();

      //Get Singbox Status to know if connected or not
      var status = await _singbox.getVPNStatus();
      if (status.toLowerCase() == "started") {
        _singbox.stopVPN();
        await Future.delayed(Duration(milliseconds: 500));
      }

      // Small delay to ensure any previous disconnection is complete
      await Future.delayed(Duration(milliseconds: 300));

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('connectTime', DateTime.now().toString());

      // Fetch the configuration based on the selected protocol
      String? config;
      String serverUrl = getRequiredServerDomain();
      log("Server url for config $serverUrl");
      if (selectedProtocol == Protocol.vless) {
        config = await VlessService.getVlessConfigJson(
          serverBaseUrl: "http://$serverUrl:5000",
        );
      }
      // } else if (selectedProtocol == Protocol.hysteria) {
      //   config = await HysteriaService.getHysteriaConfigJson(
      //     serverUrl: "http://$serverUrl:5000",
      //     serverAddress: serverUrl,
      //   );
      // } else if (selectedProtocol == Protocol.wireguard) {
      //   config = await WireguardService.getWireguardConfigJson(
      //     serverUrl: 'http://$serverUrl:5000',
      //   );
      // }

      if (config != null) {
        singboxService.connect(config);
      } else {
        // isConnecting = false;
        notifyListeners();
        throw Exception("Failed to retrieve configuration");
      }

      await Future.delayed(Duration(milliseconds: 800));
      // isConnecting = false;
      notifyListeners();

      log("Singbox VPN start command sent successfully!");
      // Status will be updated by the onStatusChanged listener
    } catch (error) {
      log("Error connecting Singbox: $error");
      vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;
      notifyListeners();
    }
  }

  disconnectHysteriaVlessWireGuard() async {
    // Prevent rapid disconnect attempts
    if (vpnConnectionStatus == VpnStatusConnectionStatus.disconnecting) {
      log("Already disconnecting, ignoring duplicate request");
      return;
    }

    try {
      // isDisconnecting = true;
      vpnConnectionStatus = VpnStatusConnectionStatus.disconnecting;
      notifyListeners();

      await Future.delayed(Duration(milliseconds: 400));

      singboxService.disconnect();

      // Small delay to ensure clean shutdown
      await Future.delayed(Duration(milliseconds: 1400));

      vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;
      //isDisconnecting = false;
      notifyListeners();
      stopMonitor();

      log('Singbox disconnected successfully');
    } catch (e) {
      log('Error disconnecting Singbox: $e');
      vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;
      notifyListeners();
    }
  }

  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    servers = [];
    selectedServerIndex = 0;
    selectedSubServerIndex = 0;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => AuthScreen()));
    notifyListeners();
  }

  Future<void> getUser() async {
    log("user function called");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    var headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    var response = await http.get(Uri.parse(UUtils.user), headers: headers);

    var data = jsonDecode(response.body);
    if (data['status'] == true || response.statusCode == 200) {
      log('User data: ${data['user']}');

      user = {UserModel.fromJson(data['user'])};
      await prefs.setString('user', jsonEncode(data['user']));
    } else {
      log('Error: ${data['message']}');
    }
  }

  Future<void> getPremium() async {
    log("premium function called");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    var headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
    var response = await http.get(
      Uri.parse(UUtils.subscription),
      headers: headers,
    );

    log("Response body: ${response.body}");
    var data = jsonDecode(response.body);

    log("Response status code: ${response.statusCode}");
    if (data['status'] == true || response.statusCode == 200) {
      log('Premium plans: ${data['plans']}');
      // await prefs.setString('premium_plans', jsonEncode(data['plans']));
      isPremium = true;
      notifyListeners();
    } else {
      log('Error: ${data['message']}');
      isPremium = false;
      notifyListeners();
    }
  }

  Future<void> getPlans() async {
    try {
      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await http.get(
        Uri.parse(UUtils.plans),
        headers: headers,
      );
      log("Response status code: ${response.statusCode}");
      log("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Parse each plan into a PlanModel
        plans = (data['plans'] as List)
            .map((plan) => PlanModel.fromJson(plan))
            .toList();

        notifyListeners();
      } else {
        log('Failed to load plans: ${response.statusCode}');
      }
    } catch (e) {
      log('Exception in getPlans: $e');
    }
  }

  Future<void> addFeedback(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Only send email and message - backend doesn't allow subject field
      var body = {
        'email': emailController.text,
        'message': messageController.text,
        'subject': subjectController.text,
      };

      log('Submitting feedback with email: ${emailController.text}');
      log('Message: ${messageController.text}');
      log('Subject: ${subjectController.text}');

      var response = await http.post(
        Uri.parse(UUtils.feedback),
        headers: headers,
        body: jsonEncode(body),
      );

      log('Feedback response status: ${response.statusCode}');
      log('Feedback response body: ${response.body}');

      var data = jsonDecode(response.body);
      if (data['status'] == true || response.statusCode == 200) {
        log('Feedback submitted: ${data['message']}');
        // Handle successful feedback submission
        showCustomSnackBar(
          context,
          Icons.check,
          'Success',
          'Feedback submitted successfully',
          Colors.green,
        );
      } else {
        log('Error submitting feedback: ${data['message']}');
        showCustomSnackBar(
          context,
          Icons.error,
          'Error',
          data['message'] ?? 'Failed to submit feedback',
          Colors.red,
        );
      }
    } catch (error) {
      log('Exception in addFeedback: $error');
      showCustomSnackBar(
        context,
        Icons.error,
        'Error',
        'Failed to submit feedback: $error',
        Colors.red,
      );
    }
  }

  // Check network speed
  Future<Map<String, String>> networkSpeed() async {
    var speed = {'download': "0", 'upload': "0"};
    final url = 'https://youtube.com';
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final elapsed = stopwatch.elapsedMilliseconds;
        // Calculate speed in Mbps (Megabits per second)
        final speedInMbps =
            ((response.bodyBytes.length / 1024 / 1024) / (elapsed / 1000)) *
            8 /
            3;
        String download = speedInMbps.toStringAsFixed(2);
        String upload = (speedInMbps + 1.36).toStringAsFixed(2);
        speed = {'download': download, 'upload': upload};
      }
      return speed;
    } catch (e) {
      log(e.toString());
      return speed;
    }
  }

  void speedMonitor() {
    log("Starting speed monitoring");
    stopMonitor(); // Stop any existing timer

    speedUpdateTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (vpnConnectionStatus == VpnStatusConnectionStatus.connected) {
        log("Monitoring speeds...");
        var speeds = await networkSpeed();
        log("Speeds (Mbps): $speeds");

        // Convert Mbps to Kbps
        double downloadMbps =
            double.tryParse(speeds['download'] ?? "0.0") ?? 0.0;
        double uploadMbps = double.tryParse(speeds['upload'] ?? "0.0") ?? 0.0;

        downloadSpeed = (downloadMbps * 1000).toStringAsFixed(2); // kbps
        uploadSpeed = (uploadMbps * 1000).toStringAsFixed(2); // kbps

        // Log the speeds in kbps
        log("Download Speed: $downloadSpeed Kbps");
        log("Upload Speed: $uploadSpeed Kbps");

        // Get ping measurement
        try {
          final result = await InternetAddress.lookup('google.com');
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            final stopwatch = Stopwatch()..start();
            await http.get(Uri.parse('https://google.com'));
            stopwatch.stop();
            pingSpeed = stopwatch.elapsedMilliseconds.toString();
          }
        } catch (_) {
          pingSpeed = "0";
        }
        log("Ping Speed: $pingSpeed ms");
        notifyListeners();
        // Ensure UI updates to reflect new speeds
      } else {
        // Reset values when not connected
        downloadSpeed = "0.0";
        uploadSpeed = "0.0";
        pingSpeed = "0";
        // Notify UI of reset values
        notifyListeners();
      }
    });
  }

  // Method to stop monitoring when disconnected
  void stopMonitor() {
    speedUpdateTimer?.cancel();
    speedUpdateTimer = null;
  }

  // Start connection duration timer
  void startConnectionTimer() {
    connectedDuration = Duration.zero;
    _connectionDurationTimer?.cancel();
    _connectionDurationTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      connectedDuration = Duration(seconds: connectedDuration.inSeconds + 1);
      notifyListeners();
    });
  }

  // Stop connection duration timer
  void stopConnectionTimer() {
    _connectionDurationTimer?.cancel();
    _connectionDurationTimer = null;
    connectedDuration = Duration.zero;
    notifyListeners();
  }

  // Format duration for display
  String getFormattedDuration() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(connectedDuration.inHours);
    String minutes = twoDigits(connectedDuration.inMinutes.remainder(60));
    String seconds = twoDigits(connectedDuration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }
}
