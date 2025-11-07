// ignore_for_file: prefer_interpolation_to_compose_strings
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'networkHysteriaService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tytan/Defaults/singboxConfigs.dart' show SingboxConfig;

class HysteriaService {
  /// Generate and store username in SharedPreferences
  static Future<String> generateAndStoreUsername() async {
    final username = 'user_${Uuid().v4().substring(0, 8)}';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('hysteria_username', username);
    return username;
  }

  /// Get username from SharedPreferences or generate if not exists
  static Future<String> getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('name');
    if (username == null || username.isEmpty) {
      username = await generateAndStoreUsername();
    }
    return username;
  }

  /// Generate and store password in SharedPreferences
  static Future<String> generateAndStorePassword() async {
    final password = Uuid().v4();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('hysteria_password', password);
    return password;
  }

  /// Get password from SharedPreferences or generate if not exists
  static Future<String> getPassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? password = prefs.getString('hysteria_password');
    if (password == null || password.isEmpty) {
      password = await generateAndStorePassword();
    }
    return password;
  }

  /// Get username with platform suffix for identification
  static Future<String> getUsernameWithPlatform() async {
    String username = await getUsername();
    String platform = Platform.operatingSystem;
    return username + '_$platform';
  }

  /// Fetch or create Hysteria user configuration from the server
  /// Returns the complete user configuration with all necessary parameters
  static Future<HysteriaUserConfig> fetchOrCreateUserConfig({
    required String serverUrl,
  }) async {
    // Get username and password from local preferences
    String username = await getUsernameWithPlatform();
    String password = await getPassword();

    // Initialize API service with provided server URL
    HysteriaApiService apiService = HysteriaApiService(baseUrl: serverUrl);

    // Get or create user configuration from the API
    HysteriaUserConfig config = await apiService.getOrCreateUser(
      username,
      password,
    );

    return config;
  }

  /// Generate complete Hysteria configuration JSON for Singbox
  /// Uses the user configuration from the server to create a properly formatted config
  static Future<String> generateHysteriaConfig({
    required String serverUrl,
    String? serverAddress,
  }) async {
    // Fetch or create user configuration
    HysteriaUserConfig userConfig = await fetchOrCreateUserConfig(
      serverUrl: serverUrl,
    );

    // Use provided serverAddress or fall back to config's serverAddress
    String finalServerAddress = serverAddress ?? userConfig.serverAddress;

    // Get ad blocker status from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool adBlockerEnabled = prefs.getBool('adBlockerEnabled') ?? false;

    // Generate and return the Singbox Hysteria configuration
    return SingboxConfig.getHysteriaConfig(
      serverAddress: finalServerAddress,
      serverPort: userConfig.serverPort,
      password: userConfig.password,
      isAdblock: adBlockerEnabled,
    );
  }

  /// Get Hysteria configuration as a JSON string
  /// @param serverUrl: Base URL for the API (e.g., "http://profile.tecclubx.com:5000")
  /// @param serverAddress: Optional server address for connection (if different from API response)
  static Future<String> getHysteriaConfigJson({
    required String serverUrl,
    String? serverAddress,
  }) async {
    return await generateHysteriaConfig(
      serverUrl: serverUrl,
      serverAddress: serverAddress,
    );
  }

  /// Get the complete user configuration object
  /// Useful for accessing individual configuration parameters
  static Future<HysteriaUserConfig> getUserConfig({
    required String serverUrl,
  }) async {
    return await fetchOrCreateUserConfig(serverUrl: serverUrl);
  }

  /// Verify if user credentials are valid
  static Future<bool> verifyCredentials({required String serverUrl}) async {
    String username = await getUsernameWithPlatform();
    String password = await getPassword();

    HysteriaApiService apiService = HysteriaApiService(baseUrl: serverUrl);
    return await apiService.verifyUser(username, password);
  }

  /// Reset user credentials (generate new username and password)
  static Future<void> resetCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('hysteria_username');
    await prefs.remove('hysteria_password');
  }

  /// Get stored credentials
  static Future<Map<String, String>> getCredentials() async {
    String username = await getUsernameWithPlatform();
    String password = await getPassword();
    return {'username': username, 'password': password};
  }
}
