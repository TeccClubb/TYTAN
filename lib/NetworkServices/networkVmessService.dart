// ignore_for_file: prefer_conditional_assignment

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tytan/Defaults/utils.dart' as FFixed show VPS_API_KEY;

class VmessApiService {
  /// Base URL will be provided dynamically
  final String baseUrl;

  VmessApiService({required this.baseUrl});

  /// Fetch user configuration from the server
  /// Returns null if user doesn't exist (404)
  /// Throws exception for other errors
  Future<VmessUserConfig?> fetchUserConfig(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$username'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Token':  FFixed.VPS_API_KEY,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VmessUserConfig.fromJson(data);
      } else if (response.statusCode == 404) {
        // User not found, return null to indicate we need to create user
        return null;
      } else {
        throw Exception('Failed to fetch user config: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user config: $e');
    }
  }

  /// Create a new user on the server
  /// Returns the created user configuration
  Future<VmessUserConfig> createUser(String username) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Token': FFixed.VPS_API_KEY,
        },
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return VmessUserConfig.fromJson(data);
      } else {
        throw Exception('Failed to create user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  /// Get or create user configuration
  /// First tries to fetch existing user, if not found creates a new one
  Future<VmessUserConfig> getOrCreateUser(String username) async {
    // Try to fetch existing user
    VmessUserConfig? config = await fetchUserConfig(username);

    // If user doesn't exist, create one
    if (config == null) {
      config = await createUser(username);
    }

    return config;
  }
}

/// Model class for VMESS user configuration
class VmessUserConfig {
  final String username;
  final String port;
  final String path;
  final String serverIp;
  final String uuid;
  final String vmessUrl;
  final String? message; // For create response
  final bool? success; // For create response

  VmessUserConfig({
    required this.username,
    required this.port,
    required this.path,
    required this.serverIp,
    required this.uuid,
    required this.vmessUrl,
    this.message,
    this.success,
  });

  factory VmessUserConfig.fromJson(Map<String, dynamic> json) {
    return VmessUserConfig(
      username: json['username'] ?? json['name'] ?? '',
      port: json['port']?.toString() ?? '443',
      path: json['ws_path'] ?? '',
      serverIp: json['domain'] ?? '',
      uuid: json['uuid'] ?? '',
      vmessUrl: json['vmess_url'] ?? '',
      message: json['message'],
      success: json['success'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'port': port,
      'path': path,
      'server_ip': serverIp,
      'uuid': uuid,
      'vmess_url': vmessUrl,
      if (message != null) 'message': message,
      if (success != null) 'success': success,
    };
  }

  @override
  String toString() {
    return 'VmessUserConfig(username: $username, serverIp: $serverIp, port: $port, uuid: $uuid)';
  }
}
