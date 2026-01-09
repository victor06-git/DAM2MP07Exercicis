class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  // Crear una instancia de Category a partir de JSON.
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'].toString(),
    );
  }
}
