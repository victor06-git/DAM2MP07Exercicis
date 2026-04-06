import 'package:flutter/material.dart';
// Importa tu nuevo archivo aquí:
import 'encryption_form.dart';

void main() => runApp(const CryptoApp());

class CryptoApp extends StatelessWidget {
  const CryptoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Quita la banda roja de "Debug"
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Exercici 09 - Criptografía'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Encriptar'),
              Tab(text: 'Desencriptar'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            EncryptionForm(isEncrypting: true),
            EncryptionForm(isEncrypting: false),
          ],
        ),
      ),
    );
  }
}
