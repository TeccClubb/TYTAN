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
      servers: (json['servers'] as List<dynamic>?)
              ?.map((e) => Server.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'servers': servers.map((e) => e.toString()).toList(),
    };
  }
}

class Server {
  final int id;
  final String image;
  final String name;
  final Platforms? platforms;
  final String type;
  final bool status;
  final String? createdAt;
  final List<SubServer>? subServers;

  Server({
    required this.id,
    required this.image,
    required this.name,
    this.platforms,
    required this.type,
    required this.status,
    this.createdAt,
    this.subServers,
  });

  factory Server.fromJson(Map<String, dynamic> json) {
    return Server(
      id: json['id'] ?? 0,
      image: json['image'] ?? '',
      name: json['name'] ?? '',
      platforms: json['platforms'] != null
          ? Platforms.fromJson(json['platforms'])
          : null,
      type: json['type'] ?? '',
      status: json['status'] ?? false,
      createdAt: json['created_at'],
      subServers: json['sub_servers'] != null
          ? (json['sub_servers'] as List)
              .map((e) => SubServer.fromJson(e))
              .toList()
          : [],
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
  final VpsGroup? vpsGroup;

  SubServer({
    required this.id,
    required this.serverId,
    required this.name,
    required this.status,
    this.vpsGroup,
  });

  factory SubServer.fromJson(Map<String, dynamic> json) {
    return SubServer(
      id: json['id'] ?? 0,
      serverId: json['server_id'] ?? 0,
      name: json['name'] ?? '',
      status: json['status'] ?? false,
      vpsGroup: json['vps_group'] != null
          ? VpsGroup.fromJson(json['vps_group'])
          : null,
    );
  }
}

class VpsGroup {
  final int id;
  final String name;
  final List<VpsServer>? servers;

  VpsGroup({
    required this.id,
    required this.name,
    this.servers,
  });

  factory VpsGroup.fromJson(Map<String, dynamic> json) {
    return VpsGroup(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      servers: json['servers'] != null
          ? (json['servers'] as List)
              .map((e) => VpsServer.fromJson(e))
              .toList()
          : [],
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
  final double cpuUsage;
  final double ramUsage;
  final double diskUsage;
  final double totalMbitPerS;
  final int healthScore;
  final int bandwidth;
  final int bandwidthLimitPerSecond;
  final int ramLimit;
  final int cpuLimit;
  final int diskLimit;
  final String role;
  final String? createdAt;

  VpsServer({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.domain,
    required this.port,
    required this.status,
    required this.cpuUsage,
    required this.ramUsage,
    required this.diskUsage,
    required this.totalMbitPerS,
    required this.healthScore,
    required this.bandwidth,
    required this.bandwidthLimitPerSecond,
    required this.ramLimit,
    required this.cpuLimit,
    required this.diskLimit,
    required this.role,
    this.createdAt,
  });

  factory VpsServer.fromJson(Map<String, dynamic> json) {
    return VpsServer(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      ipAddress: json['ip_address'] ?? '',
      domain: json['domain'] ?? '',
      port: json['port'] ?? 0,
      status: json['status'] ?? false,
      cpuUsage: (json['cpu_usage'] ?? 0).toDouble(),
      ramUsage: (json['ram_usage'] ?? 0).toDouble(),
      diskUsage: (json['disk_usage'] ?? 0).toDouble(),
      totalMbitPerS: (json['total_mbit_per_s'] ?? 0).toDouble(),
      healthScore: json['health_score'] ?? 0,
      bandwidth: json['bandwidth'] ?? 0,
      bandwidthLimitPerSecond: json['bandwidth_limit_per_second'] ?? 0,
      ramLimit: json['ram_limit'] ?? 0,
      cpuLimit: json['cpu_limit'] ?? 0,
      diskLimit: json['disk_limit'] ?? 0,
      role: json['role'] ?? '',
      createdAt: json['created_at'],
    );
  }
}
