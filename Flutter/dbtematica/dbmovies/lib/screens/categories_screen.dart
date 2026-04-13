import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import '../config.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../view_item.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => CategoriesScreenState();
}

class CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> _categories = [];
  bool _loading = true;
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
      final uri = Uri.parse('$baseUrl/categories');
      final resp = await http.post(uri,
          headers: {'Content-Type': 'application/json'}, body: jsonEncode({}));
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

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
      _searchLoading = true;
      _searchResults = [];
    });
    try {
      final uri = Uri.parse('$baseUrl/search');
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
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CachedNetworkImage(
              imageUrl: '$baseUrl/images/thumbs/${item.image}',
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              placeholder: (context, url) => SizedBox(
                width: 56,
                height: 56,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.movie),
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Busca items o escriu i prem Enter...',
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
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
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
                  const SizedBox(height: 12),

                  // If searching show inline results
                  if (_isSearching)
                    Expanded(child: _buildSearchResults())
                  else
                    // Categories grid
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 3 / 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final c = _categories[index];
                          final colors = [
                            Colors.indigo,
                            Colors.deepPurple,
                            Colors.teal,
                            Colors.orange,
                            Colors.pink
                          ];
                          final color = colors[c.id % colors.length];
                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/items',
                                  arguments: {'id': c.id, 'name': c.name},
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                      colors: [color.shade700, color.shade300],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(c.name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    const Align(
                                      alignment: Alignment.bottomRight,
                                      child: Icon(Icons.chevron_right,
                                          color: Colors.white),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
