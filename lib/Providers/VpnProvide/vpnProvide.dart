// ignore_for_file: file_names, use_build_context_synchronously, unnecessary_brace_in_string_interps, unused_field, deprecated_member_use
import 'package:get/get.dart';
import 'dart:math' show Random;
import 'dart:async' show Timer;
import 'dart:developer' show log;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tytan/Defaults/utils.dart';
import 'dart:io' show Platform, InternetAddress;
import 'package:tytan/DataModel/userModel.dart';
import '../../NetworkServices/networkVless.dart';
import 'package:tytan/DataModel/plansModel.dart';
import 'dart:convert' show jsonDecode, jsonEncode;
import 'package:tytan/Screens/welcome/welcome.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tytan/DataModel/serverDataModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:tytan/Defaults/singboxConfigs.dart' show SingboxConfig;
import 'package:tytan/NetworkServices/networkVmess.dart' show VmessService;
import 'package:flutter_singbox_vpn/flutter_singbox.dart' show FlutterSingbox;
import 'package:tytan/NetworkServices/networkSingbox.dart' show NetworkSingbox;
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
    _singbox.onTrafficUpdate.listen(
      (event) {
        log("Traffic update received: $event");

        String downSpeed =
            event['formattedDownlinkSpeed']?.toString() ?? "0 B/s";
        String upSpeed = event['formattedUplinkSpeed']?.toString() ?? "0 B/s";

        // Ignore invalid speeds (containing negative values)
        // if (downSpeed.contains('-') || upSpeed.contains('-')) {
        //   return;
        // }
        // if (downSpeed.isEmpty) {
        //   downSpeed = "0 kB/s";
        // }
        // if (upSpeed.isEmpty) {
        //   upSpeed = "0 kB/s";
        // }

        downloadSpeed = downSpeed;
        uploadSpeed = upSpeed;
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
      log("Connecting to new server at index: $value");
      await toggleVpn();
    } else {
      await toggleVpn();
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
        return 'Turbo Mode';
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
    }
  }

  // getRequiredServerDomain() {
  //   return servers[selectedServerIndex]
  //       .subServers![selectedSubServerIndex]
  //       .vpsGroup!
  //       .serfvers![0]
  //       .domain;
  // }

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

  // listenStage() async {
  //   if (isloading) {
  //     log("OpenVPN is getting config, skipping stage check");
  //     // If OpenVPN is currently getting config set stage to connecting
  //     vpnConnectionStatus = VpnStatusConnectionStatus.connecting;
  //     return;
  //   }
  //   OpenVPN().stage().then((value) {
  //     log("OpenVPN Stage: ${value.name}");
  //     if (value.name == "connected") {
  //       vpnConnectionStatus = VpnStatusConnectionStatus.connected;
  //     } else if (value.name == "disconnected") {
  //       vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;
  //     } else if (value.name == "connecting") {
  //       vpnConnectionStatus = VpnStatusConnectionStatus.connecting;
  //     } else if (value.name == "disconnecting") {
  //       vpnConnectionStatus = VpnStatusConnectionStatus.disconnecting;
  //     } else if (value.name == "wait_connection") {
  //       vpnConnectionStatus = VpnStatusConnectionStatus.connecting;
  //     } else if (value.name == "getting_config") {
  //       vpnConnectionStatus = VpnStatusConnectionStatus.connecting;
  //     } else if (value.name == "authenticating") {
  //       vpnConnectionStatus = VpnStatusConnectionStatus.connecting;
  //     } else if (value.name == "waiting_for_server") {
  //       vpnConnectionStatus = VpnStatusConnectionStatus.connecting;
  //     } else if (value.name == "waiting_for_client") {
  //       vpnConnectionStatus = VpnStatusConnectionStatus.connecting;
  //     } else if (value.name == "get_config") {
  //       vpnConnectionStatus = VpnStatusConnectionStatus.connecting;
  //     } else if (value.name == "vpn_generate_config") {
  //       vpnConnectionStatus = VpnStatusConnectionStatus.connecting;
  //     } else {
  //       vpnConnectionStatus = VpnStatusConnectionStatus.disconnected;
  //     }
  //   });
  // }

  // Future<bool> registerUserInVps(String serverUrl) async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final String? name = prefs.getString('name');
  //     final String? password = prefs.getString('password');

  //     if (_cancelRequested) {
  //       log("Registration aborted before start on $serverUrl");
  //       return false;
  //     }

  //     log("Name is $name");
  //     log("Password is $password");

  //     if (name == null || password == null) {
  //       log("Name or password is missing");
  //       return false;
  //     }

  //     final String platform = Platform.isAndroid
  //         ? 'android'
  //         : Platform.isIOS
  //         ? 'ios'
  //         : Platform.isLinux
  //         ? 'linux'
  //         : 'desktop';

  //     const headers = {
  //       'Content-Type': 'application/json',
  //       'Accept': 'application/json',
  //       'X-API-Token': 'a3f7b9c2-d1e5-4f68-8a0b-95c6e7f4d8a1',
  //     };

  //     log("Name_platform is that ${name}_$platform");
  //     log("Password is that $password");

  //     final firstResponse = await http
  //         .post(
  //           Uri.parse("$serverUrl/api/clients/generate"),
  //           headers: headers,
  //           body: jsonEncode({"name": "${name}_$platform"}),
  //         )
  //         .timeout(const Duration(seconds: 10));

  //     if (_cancelRequested) {
  //       log("Registration aborted after initial request on $serverUrl");
  //       return false;
  //     }

  //     final thirdResponse = await http
  //         .post(
  //           Uri.parse("$serverUrl/api/openvpn/clients/${name}_$platform"),
  //           headers: headers,
  //           body: jsonEncode({"password": password}),
  //         )
  //         .timeout(const Duration(seconds: 10));

  //     if (_cancelRequested) {
  //       log("Registration aborted after OpenVPN request on $serverUrl");
  //       return false;
  //     }

  //     log(
  //       "Initial registration response ${firstResponse.statusCode}: ${firstResponse.body}",
  //     );

  //     final Map<String, dynamic>? firstBody = _parseJsonBody(
  //       firstResponse,
  //       "WireGuard registration",
  //     );
  //     final Map<String, dynamic>? thirdBody = _parseJsonBody(
  //       thirdResponse,
  //       "OpenVPN registration",
  //     );

  //     final bool initialSuccess =
  //         firstResponse.statusCode == 200 &&
  //         firstBody != null &&
  //         (firstBody["error"] == null) &&
  //         (firstBody["success"] == true || firstBody.containsKey("config"));

  //     if (initialSuccess) {
  //       log("Registered successfully on $serverUrl (initial attempt)");
  //       return true;
  //     }

  //     if (firstBody == null || firstBody["error"] == null) {
  //       log("Registration failed on $serverUrl: unexpected response");
  //     }

  //     final deleteResponse = await http
  //         .delete(
  //           Uri.parse("$serverUrl/api/clients/${name}_$platform"),
  //           headers: headers,
  //         )
  //         .timeout(const Duration(seconds: 10));
  //     log("Status wireguard ${deleteResponse.statusCode}");
  //     log("Status body ${deleteResponse.body}");

  //     if (deleteResponse.statusCode != 200) {
  //       log("Unable to delete existing client on $serverUrl");
  //       return false;
  //     }

  //     if (_cancelRequested) {
  //       log("Registration aborted before retry on $serverUrl");
  //       return false;
  //     }

  //     final newResponse = await http
  //         .post(
  //           Uri.parse("$serverUrl/api/clients/generate"),
  //           headers: headers,
  //           body: jsonEncode({
  //             "name": "${name}_$platform",
  //             "password": password,
  //           }),
  //         )
  //         .timeout(const Duration(seconds: 10));
  //     log("Response is that ${newResponse.body}");

  //     final Map<String, dynamic>? responseBody = _parseJsonBody(
  //       newResponse,
  //       "WireGuard re-registration",
  //     );

  //     final bool registrationSuccess =
  //         newResponse.statusCode == 200 &&
  //         responseBody != null &&
  //         (responseBody["success"] == true ||
  //             responseBody.containsKey("config"));

  //     if (registrationSuccess) {
  //       log("Registered successfully on $serverUrl");
  //       return true;
  //     }

  //     if (thirdBody != null) {
  //       log("Third body is that ${thirdBody["error"]}");
  //     }
  //     if (_cancelRequested) {
  //       log("Registration aborted before OpenVPN cleanup on $serverUrl");
  //       return false;
  //     }

  //     if (thirdBody != null &&
  //         (thirdBody["error"] != null || thirdBody["error"] == "")) {
  //       log("OpenVPN error: ${thirdBody["error"]}");
  //       log(
  //         "Deleting existing OpenVPN client for ${name}_$platform on $serverUrl",
  //       );
  //       final deleteResponse = await http
  //           .delete(
  //             Uri.parse("$serverUrl/api/openvpn/clients/${name}_$platform"),
  //             headers: headers,
  //           )
  //           .timeout(const Duration(seconds: 10));

  //       if (deleteResponse.statusCode == 200) {
  //         if (_cancelRequested) {
  //           log(
  //             "Registration aborted before OpenVPN re-register on $serverUrl",
  //           );
  //           return false;
  //         }

  //         final newResponse = await http
  //             .post(
  //               Uri.parse("$serverUrl/api/openvpn/clients/${name}_$platform"),
  //               headers: headers,
  //               body: jsonEncode({"password": password}),
  //             )
  //             .timeout(const Duration(seconds: 10));

  //         log("Response is that ${newResponse.body}");

  //         final Map<String, dynamic>? newOpenVpnResponse = _parseJsonBody(
  //           newResponse,
  //           "OpenVPN re-registration",
  //         );
  //         if (newOpenVpnResponse != null &&
  //             newOpenVpnResponse["success"] == true) {
  //           log("Registered successfully on $serverUrl");
  //           return true;
  //         } else {
  //           log("❌ Registration failed on $serverUrl");
  //           return false;
  //         }
  //       }
  //     }

  //     log("Registration failed on $serverUrl");
  //     return false;
  //   } on TimeoutException catch (e) {
  //     log("Registration timed out on $serverUrl: $e");
  //     return false;
  //   } catch (e) {
  //     log("Exception during registration on $serverUrl: $e");
  //     return false;
  //   }
  // }

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

  toggleVpn() async {
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
      await prefs.remove('user');
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.remove('name');
      // Then clear everything else
      await prefs.clear();

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
          "As a guest user u can't add feedback",
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
