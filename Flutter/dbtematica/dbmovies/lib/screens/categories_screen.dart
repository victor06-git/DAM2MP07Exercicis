import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import '../config.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../view_item.dart';
import '../categories_list_item.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => CategoriesScreenState();
}

class CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> _categories = []; // llista de categories carregades del servidor
  bool _loading = true;            // indica si s'estan carregant les categories

  // Estat de la cerca
  bool _isSearching = false;       // true quan s'ha llançat una cerca
  String _searchQuery = '';        // text actual del camp de cerca
  List<Item> _searchResults = [];  // resultats retornats pel servidor
  bool _searchLoading = false;     // true mentre s'espera resposta del servidor

  // didChangeDependencies es crida just després d'initState i quan canvien
  // dependències heretades (com ModalRoute). És el lloc correcte per fer
  // la primera càrrega de dades perquè el context ja està disponible.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchCategories();
  }

  // Fa un POST a /categories i carrega la llista de categories
  Future<void> _fetchCategories() async {
    try {
      final uri = Uri.parse('$baseUrl/categories');
      final resp = await http.post(uri,
          headers: {'Content-Type': 'application/json'}, body: jsonEncode({}));
      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);
        setState(() {
          // Converteix cada element JSON en un objecte Category
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

  // Fa un POST a /search amb el text de cerca i actualitza _searchResults
  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;   // activa el mode cerca per mostrar resultats
      _searchLoading = true; // mostra el spinner mentre espera
      _searchResults = [];   // neteja resultats anteriors
    });
    try {
      final uri = Uri.parse('$baseUrl/search');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}), // envia el text com a JSON
      );
      if (resp.statusCode == 200) {
        final Map<String, dynamic> decoded = jsonDecode(resp.body);
        // Extreu la llista d'items del camp 'items' de la resposta
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
      // S'executa sempre, tant si hi ha error com si no
      setState(() {
        _searchLoading = false;
      });
    }
  }

  // Construeix la llista de resultats de cerca
  Widget _buildSearchResults() {
    // Mentre carrega mostra un spinner
    if (_searchLoading) return const Center(child: CircularProgressIndicator());
    // Si no hi ha resultats mostra un missatge
    if (_searchResults.isEmpty)
      return const Center(child: Text('No s\'han trobat resultats'));
    // Llista de resultats amb imatge, nom i descripció
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
          // Al prémer navega al detall de l'item
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
                  // Barra de cerca: es mostra sempre a la part superior
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Busca items o escriu i prem Enter...',
                      // Botó X per netejar la cerca, només visible si hi ha text
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';    // neteja el text
                                  _isSearching = false; // torna a mostrar categories
                                  _searchResults = [];  // neteja resultats
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
                    // S'executa amb cada tecla: actualitza _searchQuery per
                    // controlar si mostrar o no el botó X
                    onChanged: (v) => setState(() => _searchQuery = v),
                    // S'executa al prémer Enter
                    onSubmitted: (v) {
                      final q = v.trim(); // elimina espais en blanc
                      if (q.isNotEmpty) {
                        _performSearch(q); // llança la cerca al servidor
                      } else {
                        // Si el camp és buit, torna a mostrar les categories
                        setState(() {
                          _isSearching = false;
                          _searchResults = [];
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Si s'està cercant mostra els resultats, sinó les categories
                  if (_isSearching)
                    Expanded(child: _buildSearchResults())
                  else
                    // Àrea de categories amb layout responsiu
                    Expanded(
                      child: LayoutBuilder(builder: (context, constraints) {
                        final w = constraints.maxWidth; // amplada de la pantalla
                        if (w > 600) {
                          // Tablet/Desktop: grid de targetes amb gradient
                          // Calcula el nombre de columnes segons l'amplada (mínim 2, màxim 3)
                          final cross = (w / 300).floor().clamp(2, 3);
                          return GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: cross,
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
                                // Card de la categoria
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
                                          colors: [
                                            color.shade700,
                                            color.shade300
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                          );
                        } else {
                          // Mòbil: llista simple usant el widget CategoryListItem
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _categories.length,
                            itemBuilder: (ctx, i) =>
                                CategoryListItem(category: _categories[i]),
                          );
                        }
                      }),
                    ),
                ],
              ),
            ),
    );
  }
}
