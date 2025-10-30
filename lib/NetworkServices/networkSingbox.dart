
// import 'package:flutter_singbox/flutter_singbox.dart';

 class NetworkSingbox {
//   static final NetworkSingbox _instance = NetworkSingbox._internal();
//   factory NetworkSingbox() => _instance;
//   NetworkSingbox._internal();

//   final FlutterSingbox _singbox = FlutterSingbox();

//   // States
//   String platformVersion = 'Unknown';
//   String vpnStatus = 'Stopped';

//   // Traffic stats
//   String uploadSpeed = '0 B/s';
//   String downloadSpeed = '0 B/s';
//   String uploadTotal = '0 B';
//   String downloadTotal = '0 B';
//   String sessionTotal = '0 B';
//   int connectionsIn = 0;
//   int connectionsOut = 0;

//   bool _initialized = false;

//   Stream<Map<String, dynamic>> get onStatusChanged => _singbox.onStatusChanged;
//   Stream<Map<String, dynamic>> get onTrafficUpdate => _singbox.onTrafficUpdate;

//   /// Initialize Singbox plugin safely
//   Future<void> init() async {
//     if (_initialized) {
//       log('Singbox already initialized.');
//       return;
//     }

//     try {
//       log('Initializing Singbox plugin...');

//       platformVersion =
//           await _singbox.getPlatformVersion() ?? 'Unknown platform version';
//       vpnStatus = await _singbox.getVPNStatus();
//       log('Platform: $platformVersion');
//       log('VPN Status: $vpnStatus');

//       await _singbox.getConfig();

//       // Optional live listeners (uncomment if you want real-time updates)
//       /*
//       _singbox.onStatusChanged.listen((event) {
//         final status = event['status'] ?? 'Unknown';
//         vpnStatus = status;
//         log('VPN Status changed: $status');
//       });

//       _singbox.onTrafficUpdate.listen((data) {
//         uploadSpeed = data['formattedUplinkSpeed'] ?? '0 B/s';
//         downloadSpeed = data['formattedDownlinkSpeed'] ?? '0 B/s';
//         uploadTotal = data['formattedUplinkTotal'] ?? '0 B';
//         downloadTotal = data['formattedDownlinkTotal'] ?? '0 B';
//         sessionTotal = data['formattedSessionTotal'] ?? '0 B';
//         connectionsIn = data['connectionsIn'] ?? 0;
//         connectionsOut = data['connectionsOut'] ?? 0;
//       });
//       */

//       _initialized = true;
//       log('Singbox initialized successfully.');
//     } on PlatformException catch (e) {
//       log('PlatformException: ${e.message}');
//     } catch (e) {
//       log('Unexpected error initializing Singbox: $e');
//     }
//   }

//   /// Connect VPN
//   Future<void> connect() async {
//     try {
//       await init();
//       log('Saving config...');

//       await _singbox.saveConfig(_formatJson(sampleConfig));
//       log(' Starting VPN...');
//       await _singbox.startVPN();
//       vpnStatus = 'Connected';
//      // log('VPN started successfully');
//     } catch (e) {
//       log('Error connecting VPN: $e');
//       rethrow;
//     }
//   }

//   /// Disconnect VPN
//   Future<void> disconnect() async {
//     try {
//       log('Stopping VPN...');
//       await _singbox.stopVPN();
//       vpnStatus = 'Stopped';
//       log('VPN stopped successfully.');
//     } catch (e) {
//       log('❌ Error disconnecting VPN: $e');
//       rethrow;
//     }
//   }

//   /// Get current VPN status
//   Future<String> getVPNStatus() async {
//     vpnStatus = await _singbox.getVPNStatus();
//     log('Current VPN status: $vpnStatus');
//     return vpnStatus;
//   }

//   /// Helper: pretty-format JSON
//   String _formatJson(String jsonStr) {
//     try {
//       var jsonObj = json.decode(jsonStr);
//       return const JsonEncoder.withIndent('  ').convert(jsonObj);
//     } catch (_) {
//       return jsonStr;
//     }
//   }

//   String sampleConfig = '''
// {
//   "dns": {
//     "final": "local-dns",
//     "rules": [
//       {
//         "clash_mode": "Global",
//         "server": "proxy-dns",
//         "source_ip_cidr": ["172.19.0.0/30"]
//       },
//       {
//         "server": "proxy-dns",
//         "source_ip_cidr": ["172.19.0.0/30"]
//       },
//       {
//         "clash_mode": "Direct",
//         "server": "direct-dns"
//       }
//     ],
//     "servers": [
//       {
//         "address": "tls://208.67.222.123",
//         "address_resolver": "local-dns",
//         "detour": "proxy",
//         "tag": "proxy-dns"
//       },
//       {
//         "address": "local",
//         "detour": "direct",
//         "tag": "local-dns"
//       },
//       {
//         "address": "rcode://success",
//         "tag": "block"
//       },
//       {
//         "address": "local",
//         "detour": "direct",
//         "tag": "direct-dns"
//       }
//     ],
//     "strategy": "prefer_ipv4"
//   },
//   "inbounds": [
//     {
//       "inet4_address": "172.19.0.1/30",
//       "inet6_address": "fdfe:dcba:9876::1/126",
//       "auto_route": true,
//       "endpoint_independent_nat": false,
//       "mtu": 9000,
//       "platform": {
//         "http_proxy": {
//           "enabled": true,
//           "server": "127.0.0.1",
//           "server_port": 2080
//         }
//       },
//       "sniff": true,
//       "stack": "system",
//       "strict_route": false,
//       "type": "tun"
//     },
//     {
//       "listen": "127.0.0.1",
//       "listen_port": 2080,
//       "sniff": true,
//       "type": "mixed",
//       "users": []
//     }
//   ],
//   "outbounds": [
//     {
//       "tag": "proxy",
//       "type": "selector",
//       "outbounds": ["auto", "vless-0b7630b3", "direct"]
//     },
//     {
//       "tag": "auto",
//       "type": "urltest",
//       "outbounds": ["vless-0b7630b3"],
//       "url": "http://www.gstatic.com/generate_204",
//       "interval": "10m",
//       "tolerance": 50
//     },
//     {
//       "tag": "direct",
//       "type": "direct"
//     },
//     {
//       "tag": "dns-out",
//       "type": "dns"
//     },
//     {
//       "type": "vless",
//       "tag": "vless-0b7630b3",
//       "server": "singa.tecclubx.com",
//       "server_port": 443,
//       "uuid": "b656cd02-61a3-49ae-8007-74fbbcf8e0cc",
//       "flow": "",
//       "transport": {
//         "path": "/sing-box",
//         "headers": {
//           "Host": "singa.tecclubx.com"
//         },
//         "type": "ws"
//       },
//       "tls": {
//         "enabled": true,
//         "server_name": "singa.tecclubx.com",
//         "insecure": true
//       }
//     }
//   ],
//   "route": {
//     "auto_detect_interface": true,
//     "final": "proxy",
//     "rules": [
//       {
//         "clash_mode": "Direct",
//         "outbound": "direct"
//       },
//       {
//         "clash_mode": "Global",
//         "outbound": "proxy"
//       },
//       {
//         "protocol": "dns",
//         "outbound": "dns-out"
//       }
//     ]
//   }
// }

// ''';
 }
