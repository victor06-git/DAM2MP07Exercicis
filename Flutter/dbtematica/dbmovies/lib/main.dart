import 'dart:convert';

import 'package:flutter/foundation.dart' as fd;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import 'models/category.dart';
import 'models/item.dart';
import 'categories_list_item.dart';
import 'view_item.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DBMovies',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const CategoriesScreen(),
        '/items': (context) => const ItemsScreen(),
      },
    );
  }
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> _categories = [];
  bool _loading = true;
  int? _selectedCategory;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final uri = Uri.parse('http://localhost:3000/categories');
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);
        setState(() {
          _categories = data.map((e) => Category.fromJson(e)).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Seleccione una categoría:'),
                  const SizedBox(height: 8),
                  DropdownButton<int>(
                    isExpanded: true,
                    value: _selectedCategory,
                    hint: const Text('Elige una categoría'),
                    items: _categories
                        .map<DropdownMenuItem<int>>(
                          (c) => DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                        Navigator.pushNamed(
                          context,
                          '/items',
                          arguments: value,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('O navega por categorías:'),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        return CategoryListItem(category: cat);
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  late int categoryId;
  List<Item> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  final int _pageSize = 20;
  int _total = 0;
  late ScrollController _scrollController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    categoryId = args is int ? args : int.parse(args.toString());
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    if (_page == 1) {
      setState(() => _loading = true);
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final uri = Uri.parse(
        'http://localhost:3000/items?categoryId=${categoryId}&page=${_page}&pageSize=${_pageSize}',
      );
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final Map<String, dynamic> decoded = jsonDecode(resp.body);
        final List<Item> itemsList = (decoded['items'] as List<dynamic>)
            .map((e) => Item.fromJson(e))
            .toList();
        setState(() {
          _total = decoded['total'] ?? _total;
          if (_page == 1) {
            _items = itemsList;
            _loading = false;
          } else {
            _items.addAll(itemsList);
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
      appBar: AppBar(title: const Text('Items')),
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
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text(item.description),
                  leading: CachedNetworkImage(
                    imageUrl:
                        'http://localhost:3000/images/thumbs/${item.image}',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const SizedBox(
                      width: 56,
                      height: 56,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.movie),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ItemDetailScreen(item: item),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

// Nota: La pantalla de detalle se implementa en `view_item.dart` como `ItemDetailScreen`.

// Parsing heavy work off the UI thread
List<Item> _parseItemsFromResponse(String body) {
  final Map<String, dynamic> decoded = jsonDecode(body);
  final List<dynamic> data = decoded['items'] ?? [];
  return data.map((e) => Item.fromJson(e)).toList();
}
