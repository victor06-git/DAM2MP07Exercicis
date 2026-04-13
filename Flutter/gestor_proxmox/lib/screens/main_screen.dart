import 'dart:convert';
import 'dart:io';
import 'package:gestor_proxmox/screens/file_explorer.dart';
import 'package:gestor_proxmox/widgets/buttons.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dartssh2/dartssh2.dart';
import '../models/server_config.dart';
import '../widgets/input.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<ServerConfig> servers = [];
  ServerConfig? selectedServer;
  List<ServerConfig> get _filteredServers {
    final q = searchCtrl.text.trim().toLowerCase();
    final list = servers.where((s) {
      if (q.isEmpty) return true;
      return s.nom.toLowerCase().contains(q) ||
          s.host.toLowerCase().contains(q) ||
          s.port.toLowerCase().contains(q);
    }).toList();
    list.sort(
      (a, b) => sortByNameAsc
          ? a.nom.toLowerCase().compareTo(b.nom.toLowerCase())
          : b.nom.toLowerCase().compareTo(a.nom.toLowerCase()),
    );
    return list;
  }

  final nomCtrl = TextEditingController();
  final hostCtrl = TextEditingController();
  final portCtrl = TextEditingController();
  final clauCtrl = TextEditingController();
  final searchCtrl = TextEditingController();
  bool sortByNameAsc = true;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  // --- LÓGICA ORIGINAL (Mantenida 100%) ---
  Future<void> _loadConfigs() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/configuracio.json');
    if (await file.exists()) {
      final List<dynamic> jsonList = jsonDecode(await file.readAsString());
      setState(() {
        servers = jsonList.map((e) => ServerConfig.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveConfigs() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/configuracio.json');
    await file.writeAsString(
      jsonEncode(servers.map((e) => e.toJson()).toList()),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Configuració guardada"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _selectServer(ServerConfig server) {
    setState(() {
      selectedServer = server;
      nomCtrl.text = server.nom;
      hostCtrl.text = server.host;
      portCtrl.text = server.port;
      clauCtrl.text = server.clau;
    });
  }

  Future<void> _connectSSH() async {
    if (selectedServer == null) return;

    try {
      final keyFile = File(selectedServer!.clau);
      if (!await keyFile.exists()) {
        _showMsg("No s'ha trobat el fitxer id_rsa.");
        return;
      }
      final keyString = await keyFile.readAsString();
      final keyPair = SSHKeyPair.fromPem(keyString);

      final socket = await SSHSocket.connect(
        selectedServer!.host,
        int.parse(selectedServer!.port),
        timeout: const Duration(seconds: 10),
      );

      final client = SSHClient(
        socket,
        username: selectedServer!.nom,
        identities: keyPair,
      );

      await client.authenticated;
      _showMsg("Connectat amb èxit a ${selectedServer!.host}", isError: false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              FileExplorerScreen(client: client, config: selectedServer!),
        ),
      );
    } catch (e) {
      _showMsg("Error de connexió: $e");
    }
  }

  void _showMsg(String text, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- DISEÑO MEJORADO ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          // BARRA LATERAL ESTILIZADA
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSidebarHeader(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchCtrl,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Cerca servidor, host o port',
                            prefixIcon: const Icon(Icons.search),
                            isDense: true,
                            contentPadding: const EdgeInsets.all(10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Ordenar',
                        onPressed: () =>
                            setState(() => sortByNameAsc = !sortByNameAsc),
                        icon: Icon(
                          sortByNameAsc
                              ? Icons.sort_by_alpha
                              : Icons.sort_by_alpha_outlined,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: _filteredServers.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 12, endIndent: 12),
                    itemBuilder: (context, i) {
                      final s = _filteredServers[i];
                      final bool isSelected = selectedServer == s;
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        tileColor: isSelected
                            ? Colors.blue.withOpacity(0.04)
                            : null,
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? Colors.blue
                              : Colors.blueGrey.shade200,
                          child: Icon(Icons.dns, size: 18, color: Colors.white),
                          radius: 18,
                        ),
                        title: Text(
                          s.nom,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${s.host}:${s.port}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Connectar',
                              icon: const Icon(Icons.link, size: 20),
                              onPressed: () => setState(() {
                                _selectServer(s);
                                _connectSSH();
                              }),
                            ),
                            IconButton(
                              tooltip: 'Editar',
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => setState(() => _selectServer(s)),
                            ),
                            IconButton(
                              tooltip: 'Eliminar',
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () {
                                setState(() {
                                  if (selectedServer == s)
                                    selectedServer = null;
                                  servers.remove(s);
                                });
                                _saveConfigs();
                              },
                            ),
                          ],
                        ),
                        onTap: () => _selectServer(s),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // PANEL CENTRAL / FORMULARIO
          Expanded(
            child: selectedServer == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.terminal_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Selecciona un servidor per començar",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(40),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 550),
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: _buildConfigForm(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 16, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Servidors",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                final n = ServerConfig(
                  nom: "Nou Servidor",
                  host: "",
                  port: "22",
                  clau: "",
                );
                servers.add(n);
                _selectServer(n);
              });
            },
            icon: const Icon(Icons.add_circle, color: Colors.blue, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.settings_outlined, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            const Text(
              "Configuració SSH",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 32),
        CustomInput(
          label: "Etiqueta del Node:",
          controller: nomCtrl,
          onChanged: (v) => setState(() => selectedServer!.nom = v),
        ),
        const SizedBox(height: 16),
        CustomInput(
          label: "Adreça Host / IP:",
          controller: hostCtrl,
          onChanged: (v) => setState(() => selectedServer!.host = v),
        ),
        const SizedBox(height: 16),
        CustomInput(
          label: "Port Port:",
          controller: portCtrl,
          onChanged: (v) => setState(() => selectedServer!.port = v),
        ),
        const SizedBox(height: 16),
        CustomInput(
          label: "Fitxer de Clau Privada:",
          controller: clauCtrl,
          readOnly: true,
          onTap: () async {
            FilePickerResult? r = await FilePicker.platform.pickFiles();
            if (r != null)
              setState(
                () =>
                    clauCtrl.text = selectedServer!.clau = r.files.single.path!,
              );
          },
        ),
        const SizedBox(height: 40),
        _buildFooterButtons(),
      ],
    );
  }

  Widget _buildFooterButtons() {
    return ConnectionButtons(
      onDelete: () {
        setState(() {
          servers.remove(selectedServer);
          selectedServer = null;
        });
        _saveConfigs();
      },
      onSave: _saveConfigs,
      onConnect: _connectSSH,
    );
  }
}
