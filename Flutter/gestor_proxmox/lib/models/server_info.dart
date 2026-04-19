class ServerInfo {
  int id;
  String name;
  String ip;
  int port;
  String username;
  String key;

  ServerInfo({
    required this.id,
    required this.name,
    required this.ip,
    required this.port,
    required this.username,
    required this.key,
  });

  factory ServerInfo.fromJson(Map<String, dynamic> json) {
    return ServerInfo(
      id: json['id'],
      name: json['name'],
      ip: json['host'],
      port: json['port'],
      username: json['username'],
      key: json['key'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'host': ip,
      'port': port,
      'username': username,
      'key': key,
    };
  }
}
