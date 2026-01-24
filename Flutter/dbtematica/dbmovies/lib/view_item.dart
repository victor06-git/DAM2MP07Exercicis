import 'package:flutter/cupertino.dart';
import 'models/item.dart';

class ItemDetailScreen extends StatelessWidget {
  final Item item;

  const ItemDetailScreen({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    // Use thumbs path (server stores images under public/images/thumbs)
    final imageUrl = 'https://vasensiobermudez.ieti.site/images/thumbs/${item.image}';
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(item.name)),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 240,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(CupertinoIcons.photo, size: 120),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                style: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.inactiveGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
