import 'package:flutter/material.dart';
import 'encryption_form.dart';

// Punt d'entrada de l'app
void main() => runApp(const CryptoApp());

// Widget arrel de l'aplicació
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

// Pantalla principal amb navegació inferior entre les dues pestanyes
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // 0 = Encriptar, 1 = Desencriptar

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encriptació i Seguretat'),
        centerTitle: true,
        elevation: 2,
      ),
      // IndexedStack manté els dos formularis en memòria i només mostra l'actiu.
      // Això evita que es perdi l'estat (camps omplerts) en canviar de pestanya.
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
