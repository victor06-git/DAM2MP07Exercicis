class Item {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final String
  image; // Guardaremos solo el nombre del archivo, ej: "stratocaster.jpg"

  Item({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.image,
  });

  // Constructor para crear un Item desde un JSON.
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      categoryId: json['categoryId'],
      name: json['name'],
      description: json['description'],
      image: json['image'],
    );
  }
}
