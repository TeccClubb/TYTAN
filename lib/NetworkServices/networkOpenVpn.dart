import 'dart:developer';

import 'package:openvpn_flutter/openvpn_flutter.dart';

const String appName = "Safer World VPN";
const String pkgName = "com.koona.surfvpn";
const String bundleIdentifierOVPN = "$pkgName.VPNExtension";
const String bundleIdentifierWG = "$pkgName.WGExtension";

class OVPNEngine {
  static final OpenVPN openEngine = OpenVPN();
  static bool _initialized = false;

  Future<void> initialize() async {
    if (!_initialized) {
      await openEngine.initialize(
        groupIdentifier: 'group.${pkgName}',
        providerBundleIdentifier: bundleIdentifierOVPN,
        localizedDescription: appName,
      );
      _initialized = true;
    }
  }

  Future<bool> connectopenvpn({
    required String config,
    required String username,
    required String password,
  }) async {
    try {
      // Request VPN permission
      // Connect with config

      await initialize();
      log("Username: $username, Password: $password");
      openEngine.connect(
        config,
        "Safe Surf VPN",
        username: username,
        password: password,
        certIsRequired: true,
      );

      return true;
    } catch (e) {
      log("VPN Connection Error: $e");
      return false;
    }
  }

  // Disconnect from OpenVPN
  Future<void> disconnectOpenVpn() async {
    try {
      openEngine.disconnect();
    } catch (e) {
      log("VPN Disconnection Error: $e");
    }
  }
}