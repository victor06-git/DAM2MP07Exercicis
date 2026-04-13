class ServerConfig {
  String nom;
  String host;
  String port;
  String clau;

  ServerConfig({
    required this.nom,
    required this.host,
    required this.port,
    required this.clau,
  });

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'host': host,
    'port': port,
    'clau': clau,
  };

  factory ServerConfig.fromJson(Map<String, dynamic> json) => ServerConfig(
    nom: json['nom'],
    host: json['host'],
    port: json['port'].toString(),
    clau: json['clau'],
  );
}
