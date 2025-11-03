// ignore_for_file: prefer_conditional_assignment

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tytan/Defaults/utils.dart' show VPS_API_KEY;

class VlessApiService {
  /// Base URL will be provided dynamically
  final String baseUrl;

  VlessApiService({required this.baseUrl});

  /// Fetch user configuration from the server
  /// Returns null if user doesn't exist (404)
  /// Throws exception for other errors
  Future<VlessUserConfig?> fetchUserConfig(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$username'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Token': VPS_API_KEY,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VlessUserConfig.fromJson(data);
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
  Future<VlessUserConfig> createUser(String username) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Token': VPS_API_KEY,
        },
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return VlessUserConfig.fromJson(data);
      } else {
        throw Exception('Failed to create user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  /// Get or create user configuration
  /// First tries to fetch existing user, if not found creates a new one
  Future<VlessUserConfig> getOrCreateUser(String username) async {
    // Try to fetch existing user
    VlessUserConfig? config = await fetchUserConfig(username);

    // If user doesn't exist, create one
    if (config == null) {
      config = await createUser(username);
    }

    return config;
  }
}

/// Model class for VLESS user configuration
class VlessUserConfig {
  final String username;
  final String port;
  final String publicKey;
  final String serverIp;
  final String shortId;
  final String sni;
  final String uuid;
  final String vlessUrl;
  final String? message; // For create response
  final bool? success; // For create response

  VlessUserConfig({
    required this.username,
    required this.port,
    required this.publicKey,
    required this.serverIp,
    required this.shortId,
    required this.sni,
    required this.uuid,
    required this.vlessUrl,
    this.message,
    this.success,
  });

  factory VlessUserConfig.fromJson(Map<String, dynamic> json) {
    return VlessUserConfig(
      username: json['username'] ?? json['name'] ?? '',
      port: json['port']?.toString() ?? '443',
      publicKey: json['public_key'] ?? '',
      serverIp: json['server_ip'] ?? '',
      shortId: json['short_id'] ?? '',
      sni: json['sni'] ?? '',
      uuid: json['uuid'] ?? '',
      vlessUrl: json['vless_url'] ?? '',
      message: json['message'],
      success: json['success'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'port': port,
      'public_key': publicKey,
      'server_ip': serverIp,
      'short_id': shortId,
      'sni': sni,
      'uuid': uuid,
      'vless_url': vlessUrl,
      if (message != null) 'message': message,
      if (success != null) 'success': success,
    };
  }

  @override
  String toString() {
    return 'VlessUserConfig(username: $username, serverIp: $serverIp, port: $port, uuid: $uuid)';
  }
}
