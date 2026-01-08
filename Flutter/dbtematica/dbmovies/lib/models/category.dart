class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  // Este es un 'constructor con nombre' que nos permitirá crear una
  // instancia de Category a partir del JSON que nos envía el servidor.
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(id: json['id'], name: json['name']);
  }
}
