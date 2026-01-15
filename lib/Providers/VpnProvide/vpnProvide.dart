// ignore_for_file: file_names, use_build_context_synchronously, unnecessary_brace_in_string_interps, unused_field, deprecated_member_use
import 'package:get/get.dart';
import 'dart:math' show Random;
import 'dart:async' show Timer;
import 'dart:developer' show log;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tytan/Defaults/utils.dart';
import 'package:tytan/Defaults/extensions.dart';
import 'package:tytan/DataModel/userModel.dart';
import '../../NetworkServices/networkVless.dart';
import 'package:tytan/DataModel/plansModel.dart';
import 'dart:convert' show jsonDecode, jsonEncode;
import 'package:tytan/Screens/welcome/welcome.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tytan/DataModel/serverDataModel.dart';
import 'package:provider/provider.dart' show Provider;
import 'dart:io' show Platform, InternetAddress, Socket;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:tytan/Defaults/singboxConfigs.dart' show SingboxConfig;
import 'package:tytan/NetworkServices/networkVmess.dart' show VmessService;
import 'package:flutter_singbox_vpn/flutter_singbox.dart' show FlutterSingbox;
import 'package:tytan/NetworkServices/networkSingbox.dart' show NetworkSingbox;
import 'package:tytan/Providers/AuthProvide/authProvide.dart' show AuthProvide;
import 'package:tytan/ReusableWidgets/customSnackBar.dart'
    show showCustomSnackBar;
import 'package:tytan/NetworkServices/networkVmessService.dart'
    show VmessUserConfig;

enum Protocol { vless, vmess }

enum VpnStatusConnectionStatus {
  connected,
  disconnected,
  connecting,
  disconnecting,
  reconnecting,
}

class VpnProvide with ChangeNotifier {
  var vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;
  // final Wireguardservices _wireguardService = Wireguardservices();
  // OVPNEngine openVPN = OVPNEngine();
  // final NetworkSingbox _singboxService = NetworkSingbox();
  var selectedProtocol = Protocol.vmess;
  final NetworkSingbox singboxService = NetworkSingbox();
  final FlutterSingbox _singbox = FlutterSingbox();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  var isloading = false;
  var selectedServerIndex = 0;
  var selectedSubServerIndex = 0;
  var servers = <Server>[];
  var filterServers = <Server>[];
  var isPremium = false;
  var plans = <PlanModel>[];
  var bottomBarIndex = 0.obs;
  var dnsLeakProtection = true;
  //make the user varaible type user

  var user = <UserModel>{};
  var downloadSpeed = "0.0";
  var uploadSpeed = "0.0";
  var pingSpeed = "0.0";

  // Data usage tracking
  double totalUsageBytes = 0.0;
  static const double dataLimit5GB = 5.0 * 1024 * 1024 * 1024;
  static const String totalUsagePrefsKey = 'total_data_usage_bytes';
  bool get isDataLimitReached => !isPremium && totalUsageBytes >= dataLimit5GB;

  String? _lastStatusReceived;
  DateTime? _lastStatusTime;

  /// Platform channel for kill switch native communication
  final MethodChannel _killSwitchChannel = MethodChannel(
    'com.yallavpn.android/killswitch',
  );

  /// Flag to track connection in progress
  var isConnecting = false;

  /// Flag to track disconnection in progress
  var isDisconnecting = false;

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
  bool adBlockerEnabled = false;

  chnageBottomBarIndex(int index) {
    bottomBarIndex.value = index;
    notifyListeners();
  }

  init() {
    loadTotalUsage(); // Added: Load usage on init
    _singbox.onTrafficUpdate.listen(
      (event) {
        log("Traffic update received: $event");

        String downSpeed =
            event['formattedDownlinkSpeed']?.toString() ?? "0 B/s";
        String upSpeed = event['formattedUplinkSpeed']?.toString() ?? "0 B/s";

        // Update speeds for UI
        downloadSpeed = downSpeed;
        uploadSpeed = upSpeed;

        // Track data usage
        // Expecting uplinkTotal and downlinkTotal in bytes as per user request
        final double currentUpTotal =
            double.tryParse(event['uplinkTotal']?.toString() ?? "0") ?? 0.0;
        final double currentDownTotal =
            double.tryParse(event['downlinkTotal']?.toString() ?? "0") ?? 0.0;

        _handleDataUsageUpdate(currentUpTotal, currentDownTotal);

        notifyListeners();
      },
      onError: (error) {
        log("Traffic update error: $error");
      },
    );

    _singbox.onStatusChanged.listen((event) {
      if (event['status'] != null) {
        String status = event['status'].toString().toLowerCase();

        // Debounce duplicate status updates (within 500ms) to prevent rapid rebuilds
        final now = DateTime.now();
        if (_lastStatusReceived == status &&
            _lastStatusTime != null &&
            now.difference(_lastStatusTime!).inMilliseconds < 500) {
          log('Singbox VPN status: duplicate $status ignored (debounced)');
          return;
        }

        // record last seen status after the debounce check
        _lastStatusReceived = status;
        _lastStatusTime = now;

        // Ignore ALL status updates while we're actively connecting/disconnecting
        // The connect/disconnect methods will manage the state transitions
        if (isConnecting == true) {
          log('Singbox VPN status: $status ignored (currently connecting)');
          return;
        }
        if (isDisconnecting == true) {
          log('Singbox VPN status: $status ignored (currently disconnecting)');
          return;
        }

        // Ignore stale "started" status if we recently disconnected
        if (status == 'started' &&
            vpnConnectionStatus == VpnStatusConnectionStatus.disconnected) {
          log('Singbox VPN status: started ignored (we are disconnected)');
          return;
        }

        // Ignore stale "stopped" status if we recently connected
        if (status == 'stopped' &&
            vpnConnectionStatus == VpnStatusConnectionStatus.connected) {
          log('Singbox VPN status: stopped ignored (we are connected)');
          return;
        }

        log('Singbox VPN status update: $status');
        // Update connection status based on Singbox status
        switch (status) {
          case 'started':
            if (vpnConnectionStatus != VpnStatusConnectionStatus.connected) {
              vpnConnectionStatus = VpnStatusConnectionStatus.connected;
              // start connection duration timer when we first become connected
              startConnectionTimer();

              log('VPN Connected');
              notifyListeners();
            }
            break;
          case 'stopped':
            if (vpnConnectionStatus != VpnStatusConnectionStatus.disconnected) {
              vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;
              // stop and reset the connection duration timer on disconnect
              stopConnectionTimer();

              log('VPN Disconnected');
              notifyListeners();
            }
            break;
          case 'starting':
            // Only update to connecting if we're not already controlling the animation
            if (!isConnecting &&
                vpnConnectionStatus != VpnStatusConnectionStatus.connecting) {
              vpnConnectionStatus = VpnStatusConnectionStatus.connecting;
              log('Connecting to VPN...');
              notifyListeners();
            } else {
              log('Singbox VPN status: starting (animation in progress)');
            }
            break;
          case 'stopping':
            if (vpnConnectionStatus !=
                VpnStatusConnectionStatus.disconnecting) {
              vpnConnectionStatus = VpnStatusConnectionStatus.disconnecting;
              log('Disconnecting from VPN...');
              notifyListeners();
            }
            break;
          default:
            log('Unknown status: $status');
        }
      }
    });

    // Check if VPN was connected before app restart
    checkAndRestoreTimer();
  }

  // Check if VPN is still connected after app restart and restore timer
  Future<void> checkAndRestoreTimer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedTime = prefs.getString('connectTime');

      log('checkAndRestoreTimer: storedTime = $storedTime');

      // If we have a stored connection time, check if VPN is still connected
      if (storedTime != null) {
        // Wait a bit for singbox to initialize
        await Future.delayed(const Duration(milliseconds: 500));

        // Check VPN status
        final vpnStatus = await _singbox.getVPNStatus();
        log('checkAndRestoreTimer: VPN status = $vpnStatus');

        if (vpnStatus.toLowerCase() == 'started') {
          // VPN is still connected, restore timer with elapsed time
          final startTime = DateTime.parse(storedTime);
          final elapsed = DateTime.now().difference(startTime);

          log(
            'checkAndRestoreTimer: Restoring timer with elapsed time: ${elapsed.inSeconds} seconds',
          );

          connectedDuration = elapsed;
          _connectionDurationTimer?.cancel();
          _connectionDurationTimer = Timer.periodic(
            const Duration(seconds: 1),
            (timer) {
              connectedDuration = Duration(
                seconds: connectedDuration.inSeconds + 1,
              );
              notifyListeners();
            },
          );

          vpnConnectionStatus = VpnStatusConnectionStatus.connected;
          log('checkAndRestoreTimer: Timer restored successfully');
          notifyListeners();
        } else {
          // VPN is not connected, clear stored time
          log('checkAndRestoreTimer: VPN not connected, clearing stored time');
          await prefs.remove('connectTime');
        }
      } else {
        log('checkAndRestoreTimer: No stored connection time found');
      }
    } catch (e) {
      log('checkAndRestoreTimer: Error - $e');
    }
  }

  requestCancellation() {
    if (_cancelRequested) {
      return;
    }
    _cancelRequested = true;
    if (vpnConnectionStatus != VpnStatusConnectionStatus.disconnected) {
      vpnConnectionStatus = VpnStatusConnectionStatus.disconnecting;
      notifyListeners();
    }
  }

  toggleDnsLeakProtection() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dnsLeakProtection = !dnsLeakProtection;
    await prefs.setBool('dnsLeakProtection', dnsLeakProtection);
    log("DNS Leak Protection toggled: $dnsLeakProtection");
    notifyListeners();
  }

  /// Load DNS leak protection setting from storage
  loadDnsLeakProtection() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dnsLeakProtection = prefs.getBool('dnsLeakProtection') ?? true;
    notifyListeners();
  }

  toggleAdBlocker() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    adBlockerEnabled = !adBlockerEnabled;
    await prefs.setBool('adBlockerEnabled', adBlockerEnabled);
    log("Ad Blocker toggled: $adBlockerEnabled");
    notifyListeners();
  }

  /// Load ad blocker setting from storage
  loadAdBlocker() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    adBlockerEnabled = prefs.getBool('adBlockerEnabled') ?? false;
    notifyListeners();
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

  toggleKillSwitchState(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // If kill switch is currently ON, just turn it OFF
    if (killSwitchOn) {
      killSwitchOn = false;
      await prefs.setBool('killSwitchOn', false);
      notifyListeners();
      log("Kill Switch turned OFF");

      // if (context.mounted) {
      //   showCustomSnackBar(
      //     context,
      //     Icons.shield_outlined,
      //     'Kill Switch',
      //     'Kill Switch disabled',
      //     const Color(0xFF6B7280),
      //   );
      // }
      return;
    }

    // If kill switch is OFF, toggle it ON
    killSwitchOn = true;
    await prefs.setBool('killSwitchOn', true);
    notifyListeners();
    log("Kill Switch turned ON");

    // Check if platform supports native kill switch
    if (Platform.isAndroid) {
      final bool isSupported = await _isKillSwitchSupported();

      if (isSupported) {
        // Open Android VPN Settings for user to enable kill switch
        await _openKillSwitchSettings(context);
      } else {
        // Show info that kill switch requires Android 7.0+
        if (context.mounted) {
          _showKillSwitchUnsupportedDialog(context);
        }
      }
    } else {
      // For iOS or other platforms, show feedback
      if (context.mounted) {
        showCustomSnackBar(
          context,
          Icons.shield_rounded,
          'Kill Switch',
          'Kill Switch enabled - Internet will be blocked when VPN disconnects',
          const Color(0xFF10B981),
        );
      }
    }
  }

  /// Check if device supports native kill switch (Android 7.0+)
  Future<bool> _isKillSwitchSupported() async {
    try {
      final bool? isSupported = await _killSwitchChannel.invokeMethod(
        'isKillSwitchSupported',
      );
      return isSupported ?? false;
    } catch (e) {
      log('Error checking kill switch support: $e');
      return false;
    }
  }

  Future<void> _openKillSwitchSettings(BuildContext context) async {
    try {
      final bool? result = await _killSwitchChannel.invokeMethod(
        'openKillSwitchSettings',
      );

      if (result == true && context.mounted) {
        // Show instructions dialog
        _showKillSwitchInstructionsDialog(context);
      }
    } catch (e) {
      log('Error opening kill switch settings: $e');
      if (context.mounted) {
        showCustomSnackBar(
          context,
          Icons.error_outline_rounded,
          'Error',
          'Failed to open VPN settings',
          const Color(0xFFEF4444),
        );
      }
    }
  }

  /// Show dialog when kill switch is not supported
  void _showKillSwitchUnsupportedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF8F9FA)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 60,
                  color: Color(0xFFF59E0B),
                ),
                SizedBox(height: 16),
                Text(
                  'Kill Switch Unavailable',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Kill Switch requires Android 7.0 or higher. Your device is running an older version.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showKillSwitchInstructionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          backgroundColor: const Color(0xFF1A1A1A), // Updated to 0xFF1A1A1A,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: const Color(0xFF1A1A1A),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.deepOrange,
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: Color(0xFF10B981).withOpacity(0.3),
                    //     blurRadius: 20,
                    //     offset: Offset(0, 10),
                    //   ),
                    // ],
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),

                SizedBox(height: 24),

                // Title
                Text(
                  'Enable Kill Switch',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                    letterSpacing: 0.5,
                  ),
                ),

                SizedBox(height: 16),

                // Instructions
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInstructionStep(
                        '1',
                        'Select "Tytan VPN" from the list',
                      ),
                      SizedBox(height: 12),
                      _buildInstructionStep('2', 'Enable "Always-on VPN"'),
                      SizedBox(height: 12),
                      _buildInstructionStep(
                        '3',
                        'Enable "Block connections without VPN"',
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Info text
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: Colors.deepOrange,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will block all internet when VPN is disconnected',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Close button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Got it',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.deepOrange,

            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // Load kill switch state from storage
  Future<void> loadKillSwitchState() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      killSwitchOn = prefs.getBool('killSwitchOn') ?? false;
      log('Kill switch state loaded: $killSwitchOn');
      notifyListeners();
    } catch (e) {
      log('Error loading kill switch state: $e');
    }
  }

  myAutoConnect() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    autoConnectOn = prefs.getBool('autoConnect') ?? false;
    notifyListeners();
  }

  changeServer(int value, int val, BuildContext context) async {
    // Check if this server is premium
    // final server = servers[value]; // assuming srvList list is available here
    // if (server.type.toLowerCase() == "premium") {
    //   Navigator.of(
    //     context,
    //   ).push(MaterialPageRoute(builder: (context) => PremiumScreen()));
    //   return;
    // }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    log("Changing server to index: $value, sub-index: $val");
    bottomBarIndex.value = 0;

    // Store whether we were connected before changing server
    final wasConnected =
        vpnConnectionStatus == VpnStatusConnectionStatus.connected ||
        vpnConnectionStatus == VpnStatusConnectionStatus.connecting;

    // If VPN is connected, disconnect first
    if (wasConnected) {
      log("Disconnecting from current server before switching...");
      await disconnectVmessVlessWireGuard();
      // Wait for clean disconnection
      await Future.delayed(Duration(milliseconds: 300));
      log("Disconnected from previous server");
    }

    // Update server selection
    selectedServerIndex = value;
    selectedSubServerIndex = val;

    await prefs.setInt('selectedServer', value);
    await prefs.setInt('selectedSubServer', val);

    notifyListeners();

    // Wait for values to properly reflect
    await Future.delayed(Duration(milliseconds: 500));

    // If we were connected before, reconnect to the new server
    if (wasConnected) {
      // Check data limit before reconnecting
      if (isDataLimitReached) {
        log("Data limit reached during server change. Stopping.");
        if (context.mounted) {
          showCustomSnackBar(
            context,
            Icons.data_usage_rounded,
            'Data Limit Reached',
            'You have used your 5GB free limit. Upgrade to Premium for unlimited data!',
            Colors.red,
          );
        }
        await disconnectVmessVlessWireGuard();
        return;
      }
      log("Connecting to new server at index: $value");
      await toggleVpn(context);
    } else {
      await toggleVpn(context);
    }
  }

  Future<void> selectFastestServerByHealth({bool freeOnly = false}) async {
    if (servers.isEmpty) {
      log("No servers available to analyze.");
      return;
    }

    isloading = true;
    notifyListeners();

    int fastestIndex = 0;
    double highestScore = -1.0;

    for (int i = 0; i < servers.length; i++) {
      // If only free servers should be considered, skip premium ones
      if (freeOnly) {
        final t = servers[i].type.trim().toLowerCase();
        if (t == 'premium') {
          continue;
        }
      }
      try {
        // Each server can have multiple subServers, so find the best among them
        final subServers = servers[i].subServers;
        for (var sub in subServers) {
          final vpsServer = sub.vpsServer;
          if (vpsServer != null) {
            final score = double.tryParse(vpsServer.createdAt) ?? 0.0;
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

    // If no free server matched and we were filtering for free, fall back to first non-premium if exists
    if (highestScore < 0 && freeOnly) {
      for (int i = 0; i < servers.length; i++) {
        final t = servers[i].type.trim().toLowerCase();
        if (t != 'premium') {
          fastestIndex = i;
          highestScore = 0; // mark as selected
          break;
        }
      }
    }

    // If still nothing found, keep current index 0 safely bounded
    if (highestScore < 0) {
      fastestIndex = servers.isNotEmpty ? 0 : 0;
    }

    selectedServerIndex = fastestIndex;
    await _saveSelectedServerIndex();

    isloading = false;
    notifyListeners();

    if (servers.isNotEmpty) {
      final picked = servers[fastestIndex];
      log(
        "Fastest ${freeOnly ? 'free ' : ''}server selected: ${picked.name} (Health Score: $highestScore, Type: ${picked.type})",
      );
    }
  }

  Future<bool> setProtocol(Protocol protocol, {BuildContext? context}) async {
    if (selectedProtocol == protocol) {
      return true;
    }

    if (vpnConnectionStatus != VpnStatusConnectionStatus.disconnected) {
      log('Protocol change blocked: VPN must be disconnected.');
      if (context != null && context.mounted) {
        showCustomSnackBar(
          context,
          Icons.warning_amber_rounded,
          'Disconnect First',
          'Please disconnect VPN before changing protocol',
          Colors.orange,
        );
      }
      notifyListeners();
      return false;
    }

    // Show loading dialog if context is provided
    bool? dialogShown = false;
    if (context != null && context.mounted) {
      dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return WillPopScope(
            onWillPop: () async => false,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              backgroundColor: Colors.white,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color(0xFFF8F9FA)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Icon with gradient background
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF00417B), Color(0xFF0066CC)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF00417B).withOpacity(0.3),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Title
                    Text(
                      'Switching Protocol',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                        letterSpacing: 0.5,
                      ),
                    ),

                    SizedBox(height: 12),

                    // Protocol badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF00417B).withOpacity(0.1),
                            Color(0xFF0066CC).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color(0xFF00417B).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            size: 18,
                            color: Color(0xFF00417B),
                          ),
                          SizedBox(width: 8),
                          Text(
                            getProtocolDisplayName(protocol).toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00417B),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Description
                    Text(
                      'Loading servers...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'Please wait a moment',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    selectedProtocol = protocol;
    notifyListeners();
    log('Protocol set to: ${protocol.name}');
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedProtocol', protocol.name);

    await getServersPlease(true);

    // Close loading dialog
    if (dialogShown == true && context != null && context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    notifyListeners();
    return true;
  }

  String getProtocolDisplayName(Protocol protocol) {
    switch (protocol) {
      case Protocol.vmess:
        return 'VMess';
      default:
        return 'Turbo Mode';
      // case Protocol.vless:
      //   return 'Stealth Mode';
    }
  }

  // Future<bool> setAutoSelectProtocol(bool value) async {
  //   if (value &&
  //       vpnConnectionStatus != VpnStatusConnectionStatus.disconnected) {
  //     log('Auto-select requires the VPN to be disconnected.');
  //     notifyListeners();
  //     return false;
  //   }

  //   if (autoSelectProtocol == value) {
  //     return true;
  //   }

  //   autoSelectProtocol = value;
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setBool('autoSelectProtocol', value);

  //   if (value) {
  //     final applied = await setProtocol(Protocol.vless);
  //     if (!applied) {
  //       autoSelectProtocol = false;
  //       await prefs.setBool('autoSelectProtocol', false);
  //       notifyListeners();
  //       return false;
  //     }
  //   }

  //   notifyListeners();
  //   return true;
  // }

  Future<void> lProtocolFromStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? proto = prefs.getString('selectedProtocol');
    bool autoSelect = prefs.getBool('autoSelectProtocol') ?? false;
    log("Auto select protocol: $autoSelect");
    log("Saved protocol from storage: $proto");

    // Map string protocol name to enum
    if (proto != null) {
      switch (proto.replaceFirst('Protocol.', '')) {
        case 'vmess':
          selectedProtocol = Protocol.vmess;
          break;
        case 'vless':
          selectedProtocol = Protocol.vless;
          break;
        default:
          selectedProtocol = Protocol.vmess;
          break;
      }
    } else {
      selectedProtocol = Protocol.vmess;
    }

    autoSelectProtocol = autoSelect;
    if (autoSelectProtocol) {
      selectedProtocol = Protocol.vmess;
    }

    log("Restored protocol: ${selectedProtocol}");
    notifyListeners();
  }

  // make me a function to load the selectedserverindex from sharedpreference
  Future<void> loadSelectedServerIndex() async {
    final prefs = await SharedPreferences.getInstance();
    selectedServerIndex = prefs.getInt('selectedServer') ?? 0;
    notifyListeners();
  }

  void setSelectedServerIndex(int index) {
    selectedServerIndex = index;
    _saveSelectedServerIndex();
    notifyListeners();
  }

  Future<void> _saveSelectedServerIndex() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedServer', selectedServerIndex);
  }

  // Set query text and filter list
  void setQueryText(String text) {
    queryText = text;
    filterSrvList();
  }

  // Filter by search query only
  void filterSrvList() {
    // Filter out servers with N/A ping or inactive status first
    List<Server> results = servers.where((s) {
      final isNA =
          (s.ping?.toUpperCase() == 'N/A') || (s.name.toUpperCase() == 'N/A');
      return !isNA && s.status == true;
    }).toList();

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

  // bool _shouldAbortConnection() {
  //   if (!_cancelRequested) {
  //     return false;
  //   }
  //   _cancelRequested = false;
  //   log("Connection cancelled by user");
  //   vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;
  //   notifyListeners();
  //   return true;
  // }

  // Map<String, dynamic>? _parseJsonBody(http.Response response, String label) {
  //   try {
  //     final dynamic decoded = jsonDecode(response.body);
  //     if (decoded is Map<String, dynamic>) {
  //       return decoded;
  //     }
  //     log("$label returned unexpected JSON: ${decoded.runtimeType}");
  //   } catch (e) {
  //     final body = response.body;
  //     final preview = body.length > 120 ? body.substring(0, 120) : body;
  //     log(
  //       "$label returned non JSON (${response.statusCode}): ${preview.replaceAll('\n', ' ')}",
  //     );
  //   }
  //   return null;
  // }

  Future<void> getServersPlease(bool net) async {
    isloading = true;
    notifyListeners();
    // Simulate a network call or data fetching
    try {
      lProtocolFromStorage();
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

      var protocol = selectedProtocol == Protocol.vless
          ? "vless"
          : "hysteria_v2";
      log("loaded protocol: $protocol");

      if (net) {
        var headers = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        };
        var response = await http.get(
          Uri.parse(
            "${UUtils.getServers}?platform=$platform&protocol=$protocol",
          ),
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
      // Calculate pings after fetching servers
      calculateAllServerPings();
    }
  }

  Future<void> calculateAllServerPings() async {
    for (var server in servers) {
      int bestPing = 9999;
      for (var sub in server.subServers) {
        if (sub.vpsServer != null) {
          final pingResult = await _pingServer(
            sub.vpsServer!.ipAddress,
            sub.vpsServer!.port,
          );
          sub.vpsServer!.pingValue = pingResult;
          sub.vpsServer!.ping = "${pingResult}ms";
          if (pingResult < bestPing) {
            bestPing = pingResult;
          }
        }
      }
      if (bestPing != 9999) {
        server.pingValue = bestPing;
        server.ping = "${bestPing}ms";
      } else {
        server.ping = "N/A";
        server.pingValue = 10000;
      }
    }
    filterSrvList();
    notifyListeners();
  }

  Future<int> _pingServer(String host, int port) async {
    final sw = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 2),
      );
      await socket.close();
      sw.stop();
      return sw.elapsedMilliseconds;
    } catch (e) {
      log("Ping error for $host: $e");
      return 10000; // Return high value for failed pings
    }
  }

  Future<VmessUserConfig?> registerVmess(String serverIp) async {
    try {
      final headers = {"Accept": "application/json"};
      // 2. Ensure username is safe (no spaces)
      final rawName = user.isNotEmpty ? user.first.name : "guest";
      final username =
          "${rawName.toLowerCase().replaceAll(' ', '_')}_${Random().nextInt(1000)}";
      log("Username $username");
      final body = {"ip": serverIp, "username": username};
      log("Body vmess: $body");

      log("Response vmess: ${UUtils.baseUrl}vpn/register-client");
      final response = await http.post(
        Uri.parse("${UUtils.baseUrl}vpn/register-client"),
        headers: headers,
        body: body,
      );

      log("Response vmess123: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

        log("Parsed body: $responseBody");
        log("Status check: ${responseBody['status']}");
        log(
          "Data check: ${responseBody['data'] != null ? 'data exists' : 'data is null'}",
        );

        if (responseBody['status'] == true && responseBody['data'] != null) {
          final data = responseBody['data'];

          // Create VmessUserConfig from the response data
          VmessUserConfig config = VmessUserConfig(
            username: data['username'] ?? '',
            port: data['port']?.toString() ?? '443',
            path: data['ws_path'] ?? '',
            serverIp: data['domain'] ?? data['server_ip'] ?? '',
            uuid: data['uuid'] ?? '',
            vmessUrl: data['vmess_url'] ?? '',
            message: data['message'],
            success: data['success'],
          );

          log("Created VmessUserConfig: ${config.toString()}");
          return config;
        } else {
          log("VMess data not found in response");
          return null;
        }
      } else {
        log("Request failed with status: ${response.statusCode}");
        return null;
      }
    } catch (error, stackTrace) {
      log(
        "Exception during registration on $serverIp",
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  double _lastUplinkTotal = 0.0;
  double _lastDownlinkTotal = 0.0;

  /// Load total usage from storage
  Future<void> loadTotalUsage() async {
    final prefs = await SharedPreferences.getInstance();
    totalUsageBytes = prefs.getDouble(totalUsagePrefsKey) ?? 0.0;
    log(
      "Loaded total usage: ${(totalUsageBytes / (1024 * 1024)).toStringAsFixed(2)} MB",
    );
    notifyListeners();
  }

  /// Handle cumulative data usage updates
  void _handleDataUsageUpdate(double uplinkTotal, double downlinkTotal) async {
    // If it's a new connection or reset, initialize last totals
    // Usually totals from native side reset on connection, so if they are smaller than last seen, we treat as new connection
    if (uplinkTotal < _lastUplinkTotal || downlinkTotal < _lastDownlinkTotal) {
      _lastUplinkTotal = 0.0;
      _lastDownlinkTotal = 0.0;
    }

    // Calculate the delta (what was transferred since the last update)
    double deltaUp = uplinkTotal - _lastUplinkTotal;
    double deltaDown = downlinkTotal - _lastDownlinkTotal;

    if (deltaUp < 0) deltaUp = 0;
    if (deltaDown < 0) deltaDown = 0;

    totalUsageBytes += (deltaUp + deltaDown);
    _lastUplinkTotal = uplinkTotal;
    _lastDownlinkTotal = downlinkTotal;

    // Check if limit reached
    if (isDataLimitReached &&
        vpnConnectionStatus == VpnStatusConnectionStatus.connected) {
      log("Data limit (5GB) reached! Disconnecting...");
      await disconnectVmessVlessWireGuard();
    }

    // Save periodically (e.g., every 1MB or so) to minimize storage writes
    // or just save every time for simplicity in this implementation
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(totalUsagePrefsKey, totalUsageBytes);
  }

  toggleVpn([BuildContext? context]) async {
    // Prevent rapid toggle calls while connecting or disconnecting
    if (isConnecting) {
      log('toggleVpn called but already connecting, ignoring');
      return;
    }
    if (isDisconnecting) {
      log('toggleVpn called but already disconnecting, ignoring');
      return;
    }

    // Prevent connecting to premium servers when user is not premium
    if (servers.isEmpty) {
      log('toggleVpn called but servers list is empty');
      return;
    }

    final selServer = servers[selectedServerIndex];
    if (selServer.type.toLowerCase() == 'premium' && !isPremium) {
      log(
        'User is not premium; cannot connect to premium server: ${selServer.name}',
      );
      return;
    }

    // Check data limit
    if (isDataLimitReached) {
      log('Data limit reached. Cannot connect.');
      if (context != null && context.mounted) {
        showCustomSnackBar(
          context,
          Icons.data_usage_rounded,
          'Data Limit Reached',
          'You have used your 5GB free limit. Upgrade to Premium for unlimited data!',
          Colors.red,
        );
      }
      return;
    }

    var domain = servers[selectedServerIndex]
        .subServers[selectedSubServerIndex]
        .vpsServer!
        .ipAddress;
    log("Domain: $domain");

    if (selectedProtocol == Protocol.vless ||
        selectedProtocol == Protocol.vmess) {
      if (vpnConnectionStatus == VpnStatusConnectionStatus.disconnected) {
        connectVmessVlessWireGuard(domain);
      } else if (vpnConnectionStatus == VpnStatusConnectionStatus.connected) {
        disconnectVmessVlessWireGuard();
      } else {
        log(
          'toggleVpn called but VPN is in transition state: $vpnConnectionStatus',
        );
      }
    }
  }

  connectVmessVlessWireGuard(String serverUrl) async {
    log("Starting Singbox connection for ${selectedProtocol.name}");

    // Prevent rapid connection attempts
    if (vpnConnectionStatus == VpnStatusConnectionStatus.connecting) {
      log("Already connecting, ignoring duplicate request");
      return;
    }

    try {
      // Always stop/reset any previous duration timer before a new connect.
      // This prevents duplicated timers and "6 + 6" style jumps after reconnect.
      await stopConnectionTimer();

      // Reset speeds to 0 at the start of connection
      downloadSpeed = "0.0 B/s";
      uploadSpeed = "0.0 B/s";
      pingSpeed = "0 B/s";

      // Set status to connecting
      isConnecting = true;
      vpnConnectionStatus = VpnStatusConnectionStatus.connecting;
      notifyListeners();

      // Add initial delay to make the connecting state visible

      //Get Singbox Status to know if connected or not
      var status = await _singbox.getVPNStatus();
      if (status.toLowerCase() == "started") {
        _singbox.stopVPN();
      }

      // Fetch the configuration based on the selected protocol
      String? config;

      log("Selected Protocol ${selectedProtocol}");
      log("Server url for config $serverUrl");
      if (selectedProtocol == Protocol.vless) {
        config = await VlessService.getVlessConfigJson(
          serverBaseUrl: "http://$serverUrl:5000",
        );
      } else if (selectedProtocol == Protocol.vmess) {
        log("Hello from vmess");
        VmessUserConfig? vmessConfig = await registerVmess(serverUrl);
        log("Vmess config received: ${vmessConfig?.toString()}");
        if (vmessConfig != null) {
          // Check if ad blocker is enabled
          bool adBlockerEnabled = await VmessService.isAdblockEnabled();

          // Generate config directly using the values from VmessUserConfig
          config = SingboxConfig.getVmessConfig(
            uuid: vmessConfig.uuid,
            serverAddress: vmessConfig.serverIp,
            path: vmessConfig.path,
            serverPort: int.tryParse(vmessConfig.port) ?? 443,
            isAdblock: adBlockerEnabled,
          );
        }
        log("Vmess config generated: $config");
      }

      // else if (selectedProtocol == Protocol.wireguard) {
      //   config = await WireguardService.getWireguardConfigJson(
      //     serverUrl: 'http://$serverUrl:5000',
      //   );
      // }

      if (config != null) {
        await singboxService.connect(config);
      } else {
        isConnecting = false;
        notifyListeners();
        throw Exception("Failed to retrieve configuration");
      }

      // Keep the "Connecting" state visible a bit longer.
      // This does not delay the actual VPN start; it only delays our UI/status check.
      await Future.delayed(const Duration(seconds: 3));

      // Check if VPN actually started
      var finalStatus = await _singbox.getVPNStatus();
      if (finalStatus.toLowerCase() == "started") {
        vpnConnectionStatus = VpnStatusConnectionStatus.connected;
        startConnectionTimer();
        log('VPN Connected');
      }

      isConnecting = false;
      notifyListeners();

      log("Singbox VPN start command sent successfully!");
      //    speedMonitor();
      // Status will be updated by the onStatusChanged listener
    } catch (error) {
      log("Error connecting Singbox: $error");
      isConnecting = false;
      vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;
      notifyListeners();
    }
  }

  disconnectVmessVlessWireGuard() async {
    // Prevent rapid disconnect attempts
    if (vpnConnectionStatus == VpnStatusConnectionStatus.disconnecting) {
      log("Already disconnecting, ignoring duplicate request");
      return;
    }

    try {
      isDisconnecting = true;
      vpnConnectionStatus = VpnStatusConnectionStatus.disconnecting;
      notifyListeners();

      // Stop timer immediately so it can't keep incrementing while disconnecting.
      await stopConnectionTimer();

      // Ensure the native stop is actually requested/completed.
      await singboxService.disconnect();

      // Poll status briefly to confirm stop (some devices take longer than 300ms).
      // final DateTime deadline = DateTime.now().add(const Duration(seconds: 5));
      // while (DateTime.now().isBefore(deadline)) {
      //   final s = (await _singbox.getVPNStatus()).toLowerCase();
      //   if (s == 'stopped') {
      //     break;
      //   }
      //   await Future.delayed(const Duration(milliseconds: 250));
      // }

      log('VPN Disconnected');

      vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;
      isDisconnecting = false;
      notifyListeners();

      log('Singbox disconnected successfully');
    } catch (e) {
      log('Error disconnecting Singbox: $e');
      isDisconnecting = false;
      vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;
      notifyListeners();
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      // FORCE Google logout and disconnect to prevent silent re-authentication
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint("Google signOut error: $e");
      }
      // Revoke access completely to ensure user must sign in again
      try {
        await _googleSignIn.disconnect();
      } catch (e) {
        // disconnect may fail if user wasn't signed in with Google, ignore
        debugPrint("Google disconnect: $e");
      }

      // Clear local storage - explicitly remove critical keys first
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('app_account_token');
      await prefs.remove('isLoggedIn');
      await prefs.remove('isGuest');
      await prefs.remove('user');
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.remove('name');
      // Then clear everything else
      await prefs.clear();
      var authProvide = Provider.of<AuthProvide>(context, listen: false);
      authProvide.setGuest(false);

      debugPrint(
        "SharedPreferences cleared. Token: ${prefs.getString('token')}, AppAccountToken: ${prefs.getString('app_account_token')}",
      );

      // Reset provider state
      servers = [];
      filterServers = [];
      selectedServerIndex = 0;
      selectedSubServerIndex = 0;
      bottomBarIndex.value = 0;
      user = {};
      isPremium = false;
      favoriteServerIds = {};
      plans = [];
      isloading = false;
      vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;

      notifyListeners();

      // Clear navigation stack and go to WelcomeScreen
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Logout failed: $e");
    }
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
    log("User Response body: ${response.body}");
    log("User Response status code: ${response.statusCode}");

    var data = jsonDecode(response.body);
    if (data['status'] == true || response.statusCode == 200) {
      log('User data: ${data['user']}');

      user = {UserModel.fromJson(data['user'])};
      await prefs.setString('user', jsonEncode(data['user']));
    } else {
      log('Error: ${data['message']}');
    }
  }

  Future<void> getPremium(BuildContext context) async {
    log("premium function called");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(
      Uri.parse(UUtils.subscription),
      headers: headers,
    );

    log("Response body: ${response.body}");
    log("Response status code: ${response.statusCode}");

    try {
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final subscription = data['subscription'];

        if (subscription != null) {
          final subStatus = subscription['status'] ?? '';

          // Treat user as premium if they have active or trial subscription
          final activeStatuses = ['active', 'trialing', 'grace_period'];

          isPremium = activeStatuses.contains(subStatus.toLowerCase());

          log("User subscription status: $subStatus");
          log("Computed isPremium: $isPremium");
        } else {
          // No subscription object → not premium
          isPremium = false;
          log("No subscription found -> isPremium: false");
        }

        notifyListeners();
      } else {
        log(
          "Subscription endpoint error: ${data['message'] ?? response.reasonPhrase}",
        );
        isPremium = false;
        notifyListeners();
      }
    } catch (e) {
      log("Error parsing subscription response: $e");
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
      // We append the subject to the message instead
      var body = {
        'email': emailController.text,
        'message': '[${subjectController.text}] ${messageController.text}',
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
          TranslationExtension('feedback_success').tr(context),
          Colors.green,
        );
      } else {
        log('Error submitting feedback: ${data['message']}');
        showCustomSnackBar(
          context,
          Icons.error,
          'Error',
          TranslationExtension('guest_feedback_error').tr(context),
          Colors.red,
        );
      }
    } catch (error) {
      log('Exception in addFeedback: $error');
      showCustomSnackBar(
        context,
        Icons.error,
        'Error',
        TranslationExtension('feedback_failed').tr(context) + ': $error',
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
  void startConnectionTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final existingTime = prefs.getString('connectTime');

    // If timer is already running (restored from app restart), don't reset it
    if (_connectionDurationTimer != null && existingTime != null) {
      log('startConnectionTimer: Timer already running, skipping reset');
      return;
    }

    connectedDuration = Duration.zero;
    _connectionDurationTimer?.cancel();

    // Save connection start time to SharedPreferences
    await prefs.setString('connectTime', DateTime.now().toString());
    log('startConnectionTimer: Saved new connection time');

    _connectionDurationTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      connectedDuration = Duration(seconds: connectedDuration.inSeconds + 1);
      notifyListeners();
    });
  }

  // Stop connection duration timer
  Future<void> stopConnectionTimer() async {
    _connectionDurationTimer?.cancel();
    _connectionDurationTimer = null;
    connectedDuration = Duration.zero;

    // Clear connection start time from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('connectTime');

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
