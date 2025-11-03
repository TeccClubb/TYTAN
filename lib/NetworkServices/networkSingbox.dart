import 'dart:convert';
import 'dart:developer' show log;
import 'package:flutter_singbox/flutter_singbox.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

class NetworkSingbox {
  static final NetworkSingbox _instance = NetworkSingbox._internal();
  factory NetworkSingbox() => _instance;
  NetworkSingbox._internal();

  final FlutterSingbox _singbox = FlutterSingbox();

  bool _initialized = false;
  bool _isConnecting = false;
  bool _isDisconnecting = false;
  String currentStage = 'Unknown';

  Stream<Map<String, dynamic>> get onStatusChanged => _singbox.onStatusChanged;

  Future<void> init() async {
    if (_initialized) return;
    try {
      log('Initializing Singbox...');
      await _singbox.getPlatformVersion();
      await _singbox.getConfig();

      _initialized = true;
      log('Singbox initialized.');
    } on PlatformException catch (e) {
      log('PlatformException: ${e.message}');
    } catch (e) {
      log('Unexpected error: $e');
    }
  }

  Future<void> connect(String config) async {
    // Prevent concurrent connection attempts
    if (_isConnecting) {
      log('Connection already in progress, ignoring...');
      return;
    }

    if (_isDisconnecting) {
      log('Disconnection in progress, waiting...');
      await Future.delayed(Duration(milliseconds: 500));
      if (_isDisconnecting) {
        log('Still disconnecting, aborting connection attempt');
        return;
      }
    }

    _isConnecting = true;

    try {
      log('Saving config...');
      // Connect with config
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? selectedApps = prefs.getStringList('selected_apps');

      await _singbox.setPerAppProxyList(selectedApps);
      await _singbox.saveConfig(_formatJson(config));

      log('Starting VPN...');
      await _singbox.startVPN();

      log('VPN start command sent successfully');
    } catch (e) {
      log('Error connecting: $e');
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> disconnect() async {
    // Prevent concurrent disconnection attempts
    if (_isDisconnecting) {
      log('Disconnection already in progress, ignoring...');
      return;
    }

    if (_isConnecting) {
      log('Connection in progress, waiting...');
      await Future.delayed(Duration(milliseconds: 500));
      if (_isConnecting) {
        log('Still connecting, forcing disconnect');
      }
    }

    _isDisconnecting = true;

    try {
      log('Stopping VPN...');
      await _singbox.stopVPN();
      log('VPN stop command sent successfully');
    } catch (e) {
      log('Error disconnecting: $e');
      rethrow;
    } finally {
      _isDisconnecting = false;
    }
  }

  String _formatJson(String jsonStr) {
    try {
      var jsonObj = json.decode(jsonStr);
      return const JsonEncoder.withIndent('  ').convert(jsonObj);
    } catch (_) {
      return jsonStr;
    }
  }
}
