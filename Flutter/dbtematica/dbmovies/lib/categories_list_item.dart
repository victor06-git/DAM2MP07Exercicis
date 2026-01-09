import 'package:flutter/cupertino.dart';
import 'models/category.dart';

class CategoryListItem extends StatelessWidget {
  final Category category;

  const CategoryListItem({required this.category, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navegar a la pantalla de items pasando el id de la categoría como argumento
        Navigator.pushNamed(context, '/items', arguments: category.id);
      },
      child: Container(
        color: CupertinoColors.white,
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Icon(CupertinoIcons.forward),
          ],
        ),
      ),
    );
  }
}
