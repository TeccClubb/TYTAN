// ignore_for_file: prefer_interpolation_to_compose_strings
import 'dart:io';
import 'dart:developer';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tytan/NetworkServices/networkVlessService.dart';
import 'package:tytan/Defaults/singboxConfigs.dart' show SingboxConfig;
class VlessService {
  // Generate Uuid for Vless and Store in Shared Preferences
  static Future<String> generateAndStoreUuid() async {
    final uuid = Uuid().v4();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('vless_uuid', uuid);
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
    String? uuid = prefs.getString('vless_uuid');
    if (uuid == null || uuid.isEmpty) {
      uuid = await generateAndStoreUuid();
    }
    return uuid;
  }

  // Get Username from shared preferences for Vless
  static Future<String> getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('name');
    log("Username $username");
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

  /// Fetch or create VLESS user configuration from the server
  /// Returns the complete user configuration with all necessary parameters
  static Future<VlessUserConfig> fetchOrCreateUserConfig({
    String? serverBaseUrl,
  }) async {
    // Get username from local preferences
    String username = await getUsername();

    String apiUsername = username;

    VlessApiService apiService = VlessApiService(
      baseUrl: serverBaseUrl ?? "http://profile.tecclubx.com:5000",
    );

    // Fetch or create user configuration from the API
    VlessUserConfig config = await apiService.getOrCreateUser(apiUsername);

    return config;
  }

  /// Generate complete VLESS configuration JSON for Singbox
  /// Uses the user configuration from the server to create a properly formatted config
  static Future<String> generateVlessConfig({String? serverBaseUrl}) async {
    // Fetch or create user configuration
    VlessUserConfig userConfig = await fetchOrCreateUserConfig(
      serverBaseUrl: serverBaseUrl,
    );

    // Get ad blocker status from SharedPreferences
    bool adBlockerEnabled = await isAdblockEnabled();

    // Generate and return the Singbox VLESS configuration
    return SingboxConfig.getVlessConfig(
      uuid: userConfig.uuid,
      serverAddress: userConfig.serverIp,
      serverPort: int.tryParse(userConfig.port) ?? 443,
      publicKey: userConfig.publicKey,
      shortId: userConfig.shortId,
      sni: userConfig.sni,
      isAdblock: adBlockerEnabled,
    );
  }

  /// Get VLESS configuration as a JSON string with optional custom server URL
  /// If serverBaseUrl is provided, it will be used to construct the API endpoint
  /// Otherwise, the default base URL from VlessApiService will be used
  static Future<String> getVlessConfigJson({String? serverBaseUrl}) async {
    return await generateVlessConfig(serverBaseUrl: serverBaseUrl);
  }

  /// Get the complete user configuration object
  /// Useful for accessing individual configuration parameters
  static Future<VlessUserConfig> getUserConfig({String? serverBaseUrl}) async {
    return await fetchOrCreateUserConfig(serverBaseUrl: serverBaseUrl);
  }
}
