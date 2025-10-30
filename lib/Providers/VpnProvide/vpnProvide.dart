// ignore_for_file: file_names, use_build_context_synchronously, unnecessary_brace_in_string_interps
import 'dart:developer' show log;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform, InternetAddress;
import 'dart:async' show Timer, TimeoutException;
import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:tytan/DataModel/plansModel.dart';
import 'package:tytan/DataModel/serverDataModel.dart';
import 'package:tytan/DataModel/userModel.dart';
import 'package:tytan/Defaults/utils.dart';
import 'package:tytan/NetworkServices/networkOpenVpn.dart';
import 'package:tytan/NetworkServices/networkWireguard.dart';
import 'package:tytan/ReusableWidgets/customSnackBar.dart';
import 'package:tytan/screens/auth/auth_screen.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart' show OpenVPN;
// import 'package:latestyallavpn/ReusableWidgets/customSnackBar.dart';
// import 'package:latestyallavpn/DataModel/serverDataModel.dart' show Server;
// import 'package:latestyallavpn/NetworkServices/networkOpenVpn.dart'
// show OVPNEngine;
// import 'package:latestyallavpn/NetworkServices/networkSingbox.dart' show NetworkSingbox;
// import 'package:latestyallavpn/NetworkServices/networkWireguard.dart'
// show Wireguardservices;
import 'package:wireguard_flutter/wireguard_flutter_platform_interface.dart'
    show WireGuardFlutterInterface;

enum Protocol { openvpn, wireguard, singbox }

enum VpnStatusConnectionStatus {
  connected,
  disconnected,
  connecting,
  disconnecting,
  reconnecting,
}

class VpnProvide with ChangeNotifier {
  var vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;

  final WireGuardFlutterInterface _wireguardEngine = WireGuardFlutter.instance;
  Protocol selectedProtocol = Protocol.openvpn;
  final Wireguardservices _wireguardService = Wireguardservices();
  OVPNEngine openVPN = OVPNEngine();
  // final NetworkSingbox _singboxService = NetworkSingbox();
  var isloading = false;
  var selectedServerIndex = 0;
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
    startGettingStages();
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
      final applied = await setProtocol(Protocol.wireguard);
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
        case 'wireguard':
          selectedProtocol = Protocol.wireguard;
          break;
        case 'openvpn':
          selectedProtocol = Protocol.openvpn;
          break;
        case 'singbox':
          selectedProtocol = Protocol.singbox;
          break;
        default:
          selectedProtocol = Protocol.wireguard;
          break;
      }
    } else {
      selectedProtocol = Protocol.wireguard;
    }

    autoSelectProtocol = autoSelect;
    if (autoSelectProtocol) {
      selectedProtocol = Protocol.wireguard;
    }

    log("Restored protocol: ${selectedProtocol}");
    notifyListeners();
    startGettingStages();
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
          Uri.parse("${UUtils.getServers}?platform=$platform"),
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

  startGettingStages() {
    log("Starting stage monitoring for ${selectedProtocol}");
    // Avoid spawning multiple timers
    _stageTimer ??= Timer.periodic(const Duration(seconds: 1), (Timer t) async {
      if (selectedProtocol == Protocol.wireguard) {
        await listenWireguard();
      } else if (selectedProtocol == Protocol.openvpn) {
        await listenStage();
      } else if (selectedProtocol == Protocol.singbox) {}
    });
  }

  Future<VpnStatusConnectionStatus> listenWireguard() async {
    try {
      VpnStatusConnectionStatus newStage = vpnConnectionStatus;
      final value = await _wireguardEngine.stage();
      if (value == VpnStage.connected) {
        newStage = VpnStatusConnectionStatus.connected;
      } else if (value == VpnStage.connecting || isloading) {
        newStage = VpnStatusConnectionStatus.connecting;
      } else if (value == VpnStage.disconnected) {
        newStage = VpnStatusConnectionStatus.disconnected;
      } else if (value == VpnStage.disconnecting) {
        newStage = VpnStatusConnectionStatus.disconnecting;
      } else {
        newStage = VpnStatusConnectionStatus.disconnected;
      }
      vpnConnectionStatus = newStage;
      log("WireGuard Stage: $vpnConnectionStatus");

      return newStage;
    } catch (e) {
      log("Error getting WireGuard stage: $e");
      vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;
      return VpnStatusConnectionStatus.disconnected;
    }
  }

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

    log("Protocol: ${selectedProtocol}");
    log("State: ${vpnConnectionStatus}");
    if (selectedProtocol == Protocol.wireguard) {
      if (vpnConnectionStatus == VpnStatusConnectionStatus.connected ||
          vpnConnectionStatus == VpnStatusConnectionStatus.connecting) {
        if (vpnConnectionStatus == VpnStatusConnectionStatus.connecting) {
          requestCancellation();
        }
        await disconnectWireguard();
      } else if (vpnConnectionStatus ==
          VpnStatusConnectionStatus.disconnected) {
        log("Wireguard Called!");
        await connectWireguard(domain);
      }
    } else if (selectedProtocol == Protocol.openvpn) {
      if (vpnConnectionStatus == VpnStatusConnectionStatus.connected ||
          vpnConnectionStatus == VpnStatusConnectionStatus.connecting) {
        if (vpnConnectionStatus == VpnStatusConnectionStatus.connecting) {
          requestCancellation();
        }
        await disconnectOpenVpn();
      } else if (vpnConnectionStatus ==
          VpnStatusConnectionStatus.disconnected) {
        log("OpenVPN Called");
        var domainforoepnvpn = "eu-ch001.easyguard.app";
        await connectOpenVpn(domainforoepnvpn);
      }
    } else if (selectedProtocol == Protocol.singbox) {
      // Implement Singbox connection logic here
      log("Singbox protocol selected - functionality not implemented yet.");
      connectSingbox();
    }
  }

  connectSingbox() async {
    // Implement Singbox connection logic here
    log("Singbox connection - functionality not implemented yet.");
  }

  disconnectWireguard() async {
    try {
      if (vpnConnectionStatus != VpnStatusConnectionStatus.disconnected) {
        vpnConnectionStatus = VpnStatusConnectionStatus.disconnecting;
        notifyListeners();
      }
      await _wireguardEngine.stopVpn().timeout(const Duration(seconds: 5));
      stopMonitor();
      stopConnectionTimer();
      vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;
      notifyListeners();
      log('WireGuard disconnected successfully');
    } on TimeoutException catch (e) {
      log('WireGuard disconnect timed out: $e');
      stopConnectionTimer();
      vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;
      notifyListeners();
    } catch (e) {
      log('Error disconnecting WireGuard: $e');
    }
  }

  Future<String?> selectedWirVPNConfig(String serverUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? name = prefs.getString('name');

      final String platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : Platform.isWindows
          ? 'windows'
          : 'macos';

      if (_cancelRequested) {
        log("Config fetch aborted before request on $serverUrl");
        return null;
      }

      const headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-Token': 'a3f7b9c2-d1e5-4f68-8a0b-95c6e7f4d8a1',
      };

      final response = await http
          .get(
            Uri.parse("$serverUrl/api/clients/${name}_$platform"),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (_cancelRequested) {
        log("Config fetch aborted after response on $serverUrl");
        return null;
      }

      log("Response status code: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        final String wireguardConfig = responseData['config'];
        final String ipAddress = responseData['ip'];
        final String clientName = responseData['name'];
        final String qrCode = responseData['qr_code'];

        await prefs.setString('current_wireguard_config', wireguardConfig);
        await prefs.setString('current_wireguard_ip', ipAddress);
        await prefs.setString('current_wireguard_client', clientName);
        await prefs.setString('current_wireguard_qr', qrCode);
        await prefs.setString('current_wireguard_server_url', serverUrl);

        log("WireGuard config received: $wireguardConfig");
        log("WireGuard config saved successfully");

        return wireguardConfig;
      } else {
        log("Failed to get WireGuard config: ${response.statusCode}");
        return null;
      }
    } on TimeoutException catch (e) {
      log("WireGuard config request timed out on $serverUrl: $e");
      return null;
    } catch (e) {
      log("Error getting WireGuard config: $e");
      return null;
    }
  }

  Future<bool> connectWireguard(String domain) async {
    try {
      _cancelRequested = false;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('connectTime', DateTime.now().toString());

      isloading = true;
      vpnConnectionStatus = VpnStatusConnectionStatus.connecting;
      notifyListeners();

      if (_shouldAbortConnection()) {
        return false;
      }

      final registered = await registerUserInVps("http://$domain:5000");
      if (_shouldAbortConnection()) {
        return false;
      }
      if (!registered) {
        log("User registration failed");
        vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;
        notifyListeners();
        return false;
      }

      final config = await selectedWirVPNConfig("http://$domain:5000");
      if (_shouldAbortConnection()) {
        return false;
      }
      if (config == null) {
        log("Failed to get WireGuard config");
        vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;
        notifyListeners();
        return false;
      }

      final success = await _wireguardService.startWireguard(
        server: domain,
        serverName: 'United States',
        wireguardConfig: config,
      );

      if (_shouldAbortConnection()) {
        await _wireguardEngine.stopVpn();
        return false;
      }

      speedMonitor();

      vpnConnectionStatus = success
          ? VpnStatusConnectionStatus.connected
          : VpnStatusConnectionStatus.disconnected;

      // Start connection timer if successful
      if (success) {
        startConnectionTimer();
      }

      notifyListeners();
      log(
        success
            ? 'WireGuard connected successfully'
            : 'WireGuard connection failed',
      );
      return success;
    } catch (e) {
      log('Error connecting WireGuard: $e');
      vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;
      notifyListeners();
      return false;
    } finally {
      _cancelRequested = false;
      isloading = false;
      notifyListeners();
    }
  }

  disconnectSingbox() async {
    try {
      //  await _singboxService.disconnect();
      vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;
      notifyListeners();
      log('Singbox disconnected successfully');
    } catch (e) {
      log('Error disconnecting Singbox: $e');
    }
  }

  Future<String?> getSelectedOpenVpnConfig(String domain) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? name = prefs.getString('name');

      if (name == null) {
        log("Name is missing");
        return null;
      }

      String platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : Platform.isWindows
          ? 'windows'
          : 'macos';

      const headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-Token': 'a3f7b9c2-d1e5-4f68-8a0b-95c6e7f4d8a1',
      };

      final url = '$domain/api/openvpn/clients/${name}_${platform}/config';
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        log("Config fetched successfully");
        return response.body; // This is the .ovpn config
      } else {
        log("Failed to fetch VPN config. Status: ${response.statusCode}");
        return null;
      }
    } catch (error) {
      log("Error getting OpenVPN config: $error");
      return null;
    }
  }

  Future<bool> connectOpenVpn(String domain) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('connectTime', DateTime.now().toString());

      isloading = true;
      vpnConnectionStatus = VpnStatusConnectionStatus.connecting;
      notifyListeners();

      final registered = await registerUserInVps("http://$domain:5000");
      if (!registered) {
        log("User registration failed");
        vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;
        notifyListeners();
        return false;
      }

      final String? name = prefs.getString('name');
      String? password = prefs.getString('password');

      var platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : Platform.isWindows
          ? 'windows'
          : 'macos';

      if (name == null || password == null) {
        log("Name or password is missing");
        return false;
      }

      prefs.setString('connectTime', DateTime.now().toString());
      isloading = true;
      // Fetch VPN config from server
      final ovpnConfig = await getSelectedOpenVpnConfig("http://$domain:5000");
      log("OpenVPN Config: $ovpnConfig");
      isloading = false;

      if (ovpnConfig != null && ovpnConfig.isNotEmpty) {
        isloading = false;
        await openVPN.connectopenvpn(
          config: ovpnConfig,
          username: name + "_$platform",
          password: password,
        );

        speedMonitor();
        startConnectionTimer();

        log("OpenVPN connected successfully");
        return true;
      } else {
        log("Empty or null VPN config");
        return false;
      }
    } catch (error) {
      log("Error connecting OpenVPN: $error");

      return false;
    }
  }

  disconnectOpenVpn() async {
    try {
      log("Disconnecting OpenVPN");
      await openVPN.disconnectOpenVpn();
      stopMonitor();
      stopConnectionTimer();
      vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;

      log("OpenVPN disconnected successfully");
    } catch (e) {
      log("Error disconnecting OpenVPN: $e");
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
      };

      log('Submitting feedback with email: ${emailController.text}');
      log('Message: ${messageController.text}');

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
