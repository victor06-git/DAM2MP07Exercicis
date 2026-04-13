import 'package:flutter/material.dart';
import 'screens/categories_screen.dart';
import 'screens/items_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DBMovies',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.indigo)
            .copyWith(secondary: Colors.teal),
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const CategoriesScreen(),
        '/items': (context) => const ItemsScreen(),
      },
    );
  }
}

// CategoriesScreen moved to screens/categories_screen.dart
