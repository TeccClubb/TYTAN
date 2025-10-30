// ignore_for_file: file_names
import 'dart:developer';
import 'package:wireguard_flutter/wireguard_flutter.dart';

class Wireguardservices {
  var wireguard = WireGuardFlutter.instance;
  String config = '';

  Future initWireguard() async {
    await wireguard.initialize(interfaceName: 'wg0');
  }

  Future<bool> startWireguard({
    required String server,
    required String serverName,
    required String wireguardConfig,
  }) async {
    try {
      await initWireguard();

      if (wireguardConfig.isEmpty) {
        log('WireGuard configuration is empty');
      }

      log("Server $server");
      log("WireguardConfig $wireguardConfig");

      await wireguard.startVpn(
        serverAddress: server,
        wgQuickConfig: wireguardConfig,
        providerBundleIdentifier: "come.saferworldvpn.wireguard",
      );
      log('WireGuard started successfully with server: $serverName');

      return true;
    } catch (e) {
      log('Error starting WireGuard: $e');
      return Future.error('Error starting WireGuard: $e');
    }
  }

  Future<bool> stopWireguard() async {
    try {
      await wireguard.stopVpn();
      return true;
    } catch (e) {
      log('Error stopping WireGuard: $e');
      return Future.error('Error stopping WireGuard: $e');
    }
  }
}
