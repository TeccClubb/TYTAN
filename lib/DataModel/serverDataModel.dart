class ServersResponse {
  final bool status;
  final List<Server> servers;

  ServersResponse({
    required this.status,
    required this.servers,
  });

  factory ServersResponse.fromJson(Map<String, dynamic> json) {
    return ServersResponse(
      status: json['status'] ?? false,
      servers: (json['servers'] as List<dynamic>? ?? [])
          .map((e) => Server.fromJson(e))
          .toList(),
    );
  }
}

class Server {
  final int id;
  final String? image; // nullable
  final String name;
  final Platforms platforms;
  final String type;
  final bool status;
  final String createdAt;
  final List<SubServer> subServers;

  Server({
    required this.id,
    required this.image,
    required this.name,
    required this.platforms,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.subServers,
  });

  factory Server.fromJson(Map<String, dynamic> json) {
    return Server(
      id: json['id'] ?? 0,
      image: json['image'],
      name: json['name'] ?? '',
      platforms: Platforms.fromJson(json['platforms'] ?? {}),
      type: json['type'] ?? '',
      status: json['status'] ?? false,
      createdAt: json['created_at'] ?? '',
      subServers: (json['sub_servers'] as List<dynamic>? ?? [])
          .map((e) => SubServer.fromJson(e))
          .toList(),
    );
  }
}

class Platforms {
  final bool android;
  final bool ios;
  final bool macos;
  final bool windows;

  Platforms({
    required this.android,
    required this.ios,
    required this.macos,
    required this.windows,
  });

  factory Platforms.fromJson(Map<String, dynamic> json) {
    return Platforms(
      android: json['android'] ?? false,
      ios: json['ios'] ?? false,
      macos: json['macos'] ?? false,
      windows: json['windows'] ?? false,
    );
  }
}

class SubServer {
  final int id;
  final int serverId;
  final String name;
  final bool status;
  final VpsServer? vpsServer; // Matches JSON EXACTLY

  SubServer({
    required this.id,
    required this.serverId,
    required this.name,
    required this.status,
    required this.vpsServer,
  });

  factory SubServer.fromJson(Map<String, dynamic> json) {
    return SubServer(
      id: json['id'] ?? 0,
      serverId: json['server_id'] ?? 0,
      name: json['name'] ?? '',
      status: json['status'] ?? false,
      vpsServer: json['vps_server'] != null
          ? VpsServer.fromJson(json['vps_server'])
          : null,
    );
  }
}

class VpsServer {
  final int id;
  final String name;
  final String ipAddress;
  final String domain;
  final int port;
  final bool status;
  final String createdAt;

  VpsServer({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.domain,
    required this.port,
    required this.status,
    required this.createdAt,
  });

  factory VpsServer.fromJson(Map<String, dynamic> json) {
    return VpsServer(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      ipAddress: json['ip_address'] ?? '',
      domain: json['domain'] ?? '',
      port: json['port'] ?? 0,
      status: json['status'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}
