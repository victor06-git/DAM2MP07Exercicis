import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'models/item.dart';
import 'config.dart';

class ItemDetailScreen extends StatelessWidget {
  final Item item;

  const ItemDetailScreen({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    final mainImage = '$baseUrl/images/${item.image}';
    final apiImage = '$baseUrl/item/${item.id}/image';
    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: SafeArea(
        child: Column(
          children: [
            // Expandable & zoomable image
            Expanded(
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Hero(
                    tag: 'item-image-${item.id}',
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: CachedNetworkImage(
                        // Try the main image first; if it fails the errorWidget will try the API image or thumbnail
                        imageUrl: mainImage,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            CachedNetworkImage(
                          imageUrl: apiImage,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => Image.network(
                            '$baseUrl/images/thumbs/${item.image}',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 120),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(item.description,
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[700])),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                              onPressed: () {
                                // Open original image in browser or share; placeholder action
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Imatge original')));
                              },
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Obrir')),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
