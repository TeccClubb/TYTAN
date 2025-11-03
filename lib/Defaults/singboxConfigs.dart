// ignore_for_file: unnecessary_brace_in_string_interps

class SingboxConfig {
  static getHysteriaConfig({
    String serverAddress = '',
    int serverPort = 443,
    String password = '',
    bool isAdblock = false,
  }) {
    // Use AdGuard DNS if ad blocker is enabled, otherwise use Cloudflare DNS
    final dnsServer = isAdblock ? "94.140.14.14" : "1.1.1.1";

    return '''{
    "dns": {
        "final": "local-dns",
        "rules": [
            {
                "clash_mode": "Global",
                "server": "proxy-dns",
                "source_ip_cidr": [
                    "172.19.0.0/30"
                ]
            },
            {
                "server": "proxy-dns",
                "source_ip_cidr": [
                    "172.19.0.0/30"
                ]
            },
            {
                "clash_mode": "Direct",
                "server": "direct-dns"
            }
        ],
        "servers": [
            {
                "address": "tls://$dnsServer",
                "address_resolver": "local-dns",
                "detour": "proxy",
                "tag": "proxy-dns"
            },
            {
                "address": "local",
                "detour": "direct",
                "tag": "local-dns"
            },
            {
                "address": "rcode://success",
                "tag": "block"
            },
            {
                "address": "local",
                "detour": "direct",
                "tag": "direct-dns"
            }
        ],
        "strategy": "prefer_ipv4"
    },
    "inbounds": [
        {
            "type": "tun",
            "tag": "tun-in",
            "inet4_address": "172.19.0.1/30",
            "inet6_address": "fdfe:dcba:9876::1/126",
            "auto_route": true,
            "endpoint_independent_nat": false,
            "mtu": 1400,
            "platform": {
                "http_proxy": {
                    "enabled": true,
                    "server": "127.0.0.1",
                    "server_port": 2080
                }
            },
            "sniff": true,
            "stack": "system",
            "strict_route": false
        },
        {
            "type": "mixed",
            "tag": "mixed-in",
            "listen": "127.0.0.1",
            "listen_port": 2080,
            "sniff": true,
            "users": []
        }
    ],
    "outbounds": [
        {
            "tag": "proxy",
            "type": "selector",
            "outbounds": [
                "auto",
                "Hysteria2",
                "direct"
            ]
        },
        {
            "tag": "auto",
            "type": "urltest",
            "outbounds": [
                "Hysteria2"
            ],
            "url": "http://www.gstatic.com/generate_204",
            "interval": "10m",
            "tolerance": 50
        },
        {
            "tag": "direct",
            "type": "direct"
        },
        {
            "tag": "dns-out",
            "type": "dns"
        },
        {
            "type": "hysteria2",
            "tag": "Hysteria2",
            "server": "${serverAddress}",
            "server_port": ${serverPort},
            "up_mbps": 200,
            "down_mbps": 1000,
            "password": "${password}",
            "tls": {
                "enabled": true,
                "insecure": false,
                "server_name": "${serverAddress}",
                "alpn": [
                    "h3"
                ]
            }
        }
    ],
    "route": {
        "auto_detect_interface": true,
        "final": "proxy",
        "rules": [
            {
                "clash_mode": "Direct",
                "outbound": "direct"
            },
            {
                "clash_mode": "Global",
                "outbound": "proxy"
            },
            {
                "protocol": "dns",
                "outbound": "dns-out"
            }
        ]
    }
}
  ''';
  }

  // Get Vless Config
  static getVlessConfig({
    String uuid = '',
    String serverAddress = '',
    int serverPort = 443,
    String publicKey = '',
    String shortId = '',
    String sni = '',
    bool isAdblock = false,
  }) {
    // Use AdGuard DNS if ad blocker is enabled, otherwise use Cloudflare DNS
    final dnsServer = isAdblock ? "94.140.14.14" : "1.1.1.1";

    return '''{
    "log": {
        "level": "warn",
        "timestamp": true
    },
    "dns": {
        "servers": [
            {
                "tag": "dns-adguard",
                "address": "$dnsServer",
                "detour": "VLESS-Reality-Auto"
            },
            {
                "tag": "dns-local",
                "address": "local",
                "detour": "direct"
            }
        ],
        "rules": [
            {
                "outbound": "any",
                "server": "dns-local"
            }
        ],
        "final": "dns-adguard",
        "strategy": "ipv4_only"
    },
    "inbounds": [
        {
            "type": "tun",
            "tag": "tun-in",
            "inet4_address": "172.19.0.1/30",
            "inet6_address": "fdfe:dcba:9876::1/126",
            "auto_route": true,
            "endpoint_independent_nat": false,
            "mtu": 1400,
            "platform": {
                "http_proxy": {
                    "enabled": true,
                    "server": "127.0.0.1",
                    "server_port": 2080
                }
            },
            "sniff": true,
            "stack": "system",
            "strict_route": false
        },
        {
            "type": "mixed",
            "tag": "mixed-in",
            "listen": "127.0.0.1",
            "listen_port": 2080,
            "sniff": true,
            "users": []
        }
    ],
    "outbounds": [
        {
            "type": "vless",
            "tag": "VLESS-Reality-Auto",
            "server": "$serverAddress",
            "server_port": $serverPort,
            "uuid": "$uuid",
            "flow": "xtls-rprx-vision",
            "tls": {
                "enabled": true,
                "server_name": "$sni",
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                },
                "reality": {
                    "enabled": true,
                    "public_key": "$publicKey",
                    "short_id": "$shortId"
                }
            }
        },
        {
            "type": "dns",
            "tag": "dns-out"
        },
        {
            "type": "direct",
            "tag": "direct"
        },
        {
            "type": "block",
            "tag": "block"
        }
    ],
    "route": {
        "auto_detect_interface": true,
        "rules": [
            {
                "protocol": "dns",
                "outbound": "dns-out"
            },
            {
                "ip_version": 6,
                "outbound": "block"
            },
            {
                "ip_is_private": true,
                "outbound": "direct"
            }
        ],
        "final": "VLESS-Reality-Auto"
    },
    "experimental": {
        "cache_file": {
            "enabled": true,
            "store_rdrc": true
        }
    }
}  ''';
  }

  // Get Wireguard Config
  static getWireguardConfig({
    String privateKey = '',
    String address = '',
    String peerAddress = '',
    int peerPort = 443,
    String peerPublicKey = '',
    bool isAdblock = false,
  }) {
    // Use AdGuard DNS if ad blocker is enabled, otherwise use Cloudflare DNS
    final dnsServer = isAdblock ? "94.140.14.14" : "1.1.1.1";

    return '''{
    "log": {
        "level": "debug",
        "disabled": false,
        "timestamp": true
    },
    "dns": {
        "servers": [
            {
                "tag": "dns-remote",
                "address": "$dnsServer",
                "address_resolver": "dns-local",
                "detour": "wg-ep"
            },
            {
                "tag": "dns-local",
                "address": "local",
                "detour": "direct"
            }
        ],
        "final": "dns-remote",
        "strategy": "ipv4_only"
    },
    "inbounds": [
        {
            "type": "tun",
            "tag": "tun-in",
            "interface_name": "tun0",
            "inet4_address": "172.19.0.1/30",
            "auto_route": true,
            "mtu": 1280,
            "sniff": true,
            "stack": "system",
            "strict_route": false
        }
    ],
    "outbounds": [
        {
            "type": "wireguard",
            "tag": "wg-ep",
            "server": "${peerAddress}",
            "server_port": ${peerPort},
            "local_address": [
                "${address}"
            ],
            "private_key": "${privateKey}",
            "peer_public_key": "${peerPublicKey}",
            "mtu": 1280
        },
        {
            "tag": "direct",
            "type": "direct"
        },
        {
            "tag": "dns-out",
            "type": "dns"
        }
    ],
    "route": {
        "rules": [
            {
                "protocol": "dns",
                "outbound": "dns-out"
            }
        ],
        "auto_detect_interface": true,
        "final": "wg-ep"
    }
}  ''';
  }
}
