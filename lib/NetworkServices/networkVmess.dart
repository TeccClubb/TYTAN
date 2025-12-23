// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tytan/Defaults/singboxConfigs.dart' show SingboxConfig;
import 'package:tytan/NetworkServices/networkVmessService.dart' show VmessUserConfig, VmessApiService;
import 'package:uuid/uuid.dart';

class VmessService {
  // Generate Uuid for Vless and Store in Shared Preferences
  static Future<String> generateAndStoreUuid() async {
    final uuid = Uuid().v4();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('vmess_uuid', uuid);
    return uuid;
  }

  // Retrieve Adblock status from Shared Preferences
  static Future<bool> isAdblockEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('adBlockerEnabled') ?? false;
  }

  // Retrieve Uuid from Shared Preferences or Generate if not exists
  static Future<String> getUuid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString('vmess_uuid');
    if (uuid == null || uuid.isEmpty) {
      uuid = await generateAndStoreUuid();
    }
    return uuid;
  }

  // Get Username from shared preferences for Vless
  static Future<String> getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('name');
    String platform = Platform.operatingSystem;
    if (username == null || username.isEmpty) {
      username = 'user_${Uuid().v4().substring(0, 8)}';
      await prefs.setString('name', username);
    }
    return username + '_$platform';
  }

  // Get Server Configs
  static Future<Map<String, String?>> getServerConfigs(String serverUrl) async {
    var username = await getUsername();
    return {'server_address': serverUrl, 'username': username};
  }

  /// Fetch or create VMESS user configuration from the server
  /// Returns the complete user configuration with all necessary parameters
  static Future<VmessUserConfig> fetchOrCreateUserConfig({
    String? serverBaseUrl,
  }) async {
    // Get username from local preferences
    String username = await getUsername();

    String apiUsername = username;

    VmessApiService apiService = VmessApiService(
      baseUrl: serverBaseUrl ?? "http://profile.tecclubx.com:5000",
    );

    // Fetch or create user configuration from the API
    VmessUserConfig config = await apiService.getOrCreateUser(apiUsername);

    return config;
  }

  /// Generate complete VMESS configuration JSON for Singbox
  /// Uses the user configuration from the server to create a properly formatted config
  static Future<String> generateVmessConfig({String? serverBaseUrl}) async {
    // Fetch or create user configuration
    VmessUserConfig userConfig = await fetchOrCreateUserConfig(
      serverBaseUrl: serverBaseUrl,
    );

    // Get ad blocker status from SharedPreferences
    bool adBlockerEnabled = await isAdblockEnabled();

    // Generate and return the Singbox VMESS configuration
    return SingboxConfig.getVmessConfig(
      uuid: userConfig.uuid,
      serverAddress: userConfig.serverIp,
      path: userConfig.path,
      serverPort: int.tryParse(userConfig.port) ?? 443,
      isAdblock: adBlockerEnabled,
    );
  }

  /// Get VMESS configuration as a JSON string with optional custom server URL
  /// If serverBaseUrl is provided, it will be used to construct the API endpoint
  /// Otherwise, the default base URL from VmessApiService will be used
  static Future<String> getVmessConfigJson({String? serverBaseUrl}) async {
    return await generateVmessConfig(serverBaseUrl: serverBaseUrl);
  }

  /// Get the complete user configuration object
  /// Useful for accessing individual configuration parameters
  static Future<VmessUserConfig> getUserConfig({String? serverBaseUrl}) async {
    return await fetchOrCreateUserConfig(serverBaseUrl: serverBaseUrl);
  }
}
