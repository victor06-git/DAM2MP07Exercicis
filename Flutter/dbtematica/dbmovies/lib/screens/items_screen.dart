import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import '../config.dart';
import '../models/item.dart';
import '../view_item.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  late int categoryId;
  String? _categoryName;
  List<Item> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  final int _pageSize = 20;
  int _total = 0;
  late ScrollController _scrollController;

  // Full items fetched from server for this category (we paginate client-side)
  List<Item> _allCategoryItems = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is Map) {
      categoryId =
          args['id'] is int ? args['id'] : int.parse(args['id'].toString());
      _categoryName = args['name']?.toString();
    } else {
      categoryId = args is int ? args : int.parse(args.toString());
      _categoryName = null;
    }
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _fetchItems();
  }

  // Fetch items from server with pagination
  Future<void> _fetchItems() async {
    if (_page == 1) {
      setState(() => _loading = true);
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      // Use POST /items to obtain items for the category (server supports POST)
      final uri = Uri.parse('$baseUrl/items');
      final resp = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'categoryId': categoryId}));
      if (resp.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(resp.body);
        _allCategoryItems = decoded.map((e) => Item.fromJson(e)).toList();
        _total = _allCategoryItems.length;

        // Client-side pagination
        final start = (_page - 1) * _pageSize;
        final paged = _allCategoryItems.skip(start).take(_pageSize).toList();
        setState(() {
          if (_page == 1) {
            _items = paged;
            _loading = false;
          } else {
            _items.addAll(paged);
            _loadingMore = false;
          }
        });
      } else {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loadingMore || _loading) return;
    final threshold = 200.0; // pixels from bottom to trigger
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (maxScroll - current <= threshold && _items.length < _total) {
      _page += 1;
      _fetchItems();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_categoryName ?? 'Items')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              controller: _scrollController,
              itemCount: _items.length + (_loadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final item = _items[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    title: Text(item.name),
                    subtitle: Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: Hero(
                      tag: 'item-image-${item.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: '$baseUrl/images/thumbs/${item.image}',
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => SizedBox(
                            width: 72,
                            height: 72,
                            child: Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ItemDetailScreen(item: item),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
