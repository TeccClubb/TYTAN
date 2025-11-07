// ignore_for_file: file_names
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tytan/Defaults/utils.dart' show VPS_API_KEY;

class HysteriaApiService {
  /// Base URL will be provided dynamically
  final String baseUrl;

  HysteriaApiService({required this.baseUrl});

  /// Verify user credentials
  /// Returns true if credentials are valid, false otherwise
  Future<bool> verifyUser(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/verify'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Token': VPS_API_KEY
        },
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] == true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Error verifying user: $e');
    }
  }

  /// Delete a user by username
  /// Returns true if successful, false otherwise
  /// Note: We don't care about the response, just attempt to delete
  Future<bool> deleteUser(String username) async {
    try {
      await http.delete(
        Uri.parse('$baseUrl/api/users/$username'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Token': VPS_API_KEY,
        },
      );
      // Return true regardless of response as per requirement
      return true;
    } catch (e) {
      // Still return true as we don't care about the response
      return true;
    }
  }

  /// Add a new user
  /// Returns the user configuration including server details
  Future<HysteriaUserConfig> addUser(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Token': VPS_API_KEY,
        },
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return HysteriaUserConfig.fromJson({
          "username": username,
          "password": password,
          "server_port": 443,
          "server_address": baseUrl
              .replaceAll("http://", '')
              .replaceAll(":5000", ''),
        });
      } else {
        throw Exception(
          'Failed to add user: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error adding user: $e');
    }
  }

  /// Get or create user with credentials
  /// 1. Verify if user exists
  /// 2. If not, delete (just in case) and create new user
  /// 3. Return user configuration
  Future<HysteriaUserConfig> getOrCreateUser(
    String username,
    String password,
  ) async {
    // Try to verify existing user
    bool userExists = await verifyUser(username, password);

    if (!userExists) {
      // User doesn't exist or invalid credentials
      // Delete user (don't care about response)
      await deleteUser(username);

      // Add new user
      return await addUser(username, password);
    } else {
      // User exists and credentials are valid
      // We still need to get the configuration, so we'll add the user
      // (API should handle existing users)
      return await addUser(username, password);
    }
  }
}

/// Model class for Hysteria user configuration
class HysteriaUserConfig {
  final String username;
  final String password;
  final String serverAddress;
  final int serverPort;
  final String? message;
  final bool? success;

  HysteriaUserConfig({
    required this.username,
    required this.password,
    required this.serverAddress,
    required this.serverPort,
    this.message,
    this.success,
  });

  factory HysteriaUserConfig.fromJson(Map<String, dynamic> json) {
    return HysteriaUserConfig(
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      serverAddress: json['server_address'] ?? json['serverAddress'] ?? '',
      serverPort: json['server_port'] ?? json['serverPort'] ?? 443,
      message: json['message'],
      success: json['success'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'server_address': serverAddress,
      'server_port': serverPort,
      if (message != null) 'message': message,
      if (success != null) 'success': success,
    };
  }

  @override
  String toString() {
    return 'HysteriaUserConfig(username: $username, serverAddress: $serverAddress, serverPort: $serverPort)';
  }
}
