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
  // Search state
  bool _isSearching = false;
  String _searchQuery = '';
  List<Item> _searchResults = [];
  bool _searchLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final uri = Uri.parse('https://vasensiobermudez.ieti.site/categories');
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
                  const Text('Selecciona una categoria:'),
                  const SizedBox(height: 8),
                  DropdownButton<int>(
                    isExpanded: true,
                    value: _selectedCategory,
                    hint: const Text('Escull una categoria'),
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
                  const Text('O busca items:'),
                  const SizedBox(height: 8),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Cerca items...',
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _isSearching = false;
                                    _searchResults = [];
                                  });
                                },
                              )
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                      onSubmitted: (v) {
                        final q = v.trim();
                        if (q.isNotEmpty) {
                          _performSearch(q);
                        } else {
                          setState(() {
                            _isSearching = false;
                            _searchResults = [];
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _isSearching
                        ? _buildSearchResults()
                        : Center(child: Text('Escriu i prem Enter per cercar')),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchLoading) return const Center(child: CircularProgressIndicator());
    if (_searchResults.isEmpty)
      return const Center(child: Text('No s\'han trobat resultats'));
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return ListTile(
          title: Text(item.name),
          subtitle: Text(item.description),
          leading: CachedNetworkImage(
            imageUrl:
                'https://vasensiobermudez.ieti.site/images/thumbs/${item.image}',
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            placeholder: (context, url) => const SizedBox(
              width: 56,
              height: 56,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.movie),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
            );
          },
        );
      },
    );
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
      _searchLoading = true;
      _searchResults = [];
    });
    try {
      final uri = Uri.parse('https://vasensiobermudez.ieti.site/search');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );
      if (resp.statusCode == 200) {
        final Map<String, dynamic> decoded = jsonDecode(resp.body);
        final List<Item> results = (decoded['items'] as List<dynamic>?)
                ?.map((e) => Item.fromJson(e))
                .toList() ??
            [];
        setState(() {
          _searchResults = results;
        });
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
      });
    } finally {
      setState(() {
        _searchLoading = false;
      });
    }
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

  // Fetch items from server with pagination
  Future<void> _fetchItems() async {
    if (_page == 1) {
      setState(() => _loading = true);
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final uri = Uri.parse(
        'https://vasensiobermudez.ieti.site/items?categoryId=${categoryId}&page=${_page}&pageSize=${_pageSize}',
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
                        'https://vasensiobermudez.ieti.site/images/thumbs/${item.image}',
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

// Parsing heavy work off the UI thread
List<Item> _parseItemsFromResponse(String body) {
  final Map<String, dynamic> decoded = jsonDecode(body);
  final List<dynamic> data = decoded['items'] ?? [];
  return data.map((e) => Item.fromJson(e)).toList();
}
