import 'package:flutter/material.dart';
import 'encryption_form.dart';

void main() => runApp(const CryptoApp());

class CryptoApp extends StatelessWidget {
  const CryptoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encriptació i Seguretat'),
        centerTitle: true,
        elevation: 2,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          EncryptionForm(isEncrypting: true),
          EncryptionForm(isEncrypting: false),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.lock), label: 'Encriptar'),
          NavigationDestination(
            icon: Icon(Icons.lock_open),
            label: 'Desencriptar',
          ),
        ],
      ),
    );
  }
}
