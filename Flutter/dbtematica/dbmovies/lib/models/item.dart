class Item {
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final String image; // Nombre del archivo, ej: "harry_potter.jpg"

  Item({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.image,
  });

  // Crear un Item desde JSON.
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      categoryId: json['categoryId'] is int
          ? json['categoryId']
          : int.parse(json['categoryId'].toString()),
      name: json['name'].toString(),
      description: json['description'].toString(),
      image: json['image'].toString(),
    );
  }
}
