import 'package:flutter/material.dart';

import '../models/server_info.dart';
import '../services/server_config_service.dart';
import '../services/ssh_service.dart';
import '../state/app_state.dart';
import '../widgets/labeled_edit_field.dart';
import '../widgets/proxmox_panel.dart';
import '../widgets/server_card.dart';
import 'file_explorer_page.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final appState = AppStateController();
  late final SSHService sshService;

  @override
  void initState() {
    super.initState();
    sshService = SSHService(appState);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor Proxmox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: MyHomePage(
        title: 'File Manager',
        appState: appState,
        sshService: sshService,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.appState,
    required this.sshService,
  });

  final String title;
  final AppStateController appState;
  final SSHService sshService;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late TextEditingController _servernameController;
  late TextEditingController _userController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _keyController;
  int? _currentServerId;

  @override
  void initState() {
    super.initState();
    _servernameController = TextEditingController(text: 'Victor');
    _userController = TextEditingController(text: 'vasensiobermudez');
    _hostController = TextEditingController(text: 'ieticloudpro.ieti.cat');
    _portController = TextEditingController(text: '20127');
    _keyController = TextEditingController(text: 'id_rsa');
    _loadServers();
  }

  Future<void> _loadServers() async {
    final loaded = await serverConfigService.loadServers();
    widget.appState.setServers(loaded);
    if (loaded.isNotEmpty) {
      final selected = loaded.first;
      _currentServerId = selected.id;
      _servernameController.text = selected.name;
      _userController.text = selected.username;
      _hostController.text = selected.ip;
      _portController.text = selected.port.toString();
      _keyController.text = selected.key;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _servernameController.dispose();
    _userController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _saveCurrentServer() async {
    final parsedPort = int.tryParse(_portController.text) ?? 22;
    ServerInfo server;
    if (_currentServerId == null) {
      final current = widget.appState.servers;
      final newId =
          current.isEmpty
              ? 1
              : current.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
      server = ServerInfo(
        id: newId,
        name: _servernameController.text.trim(),
        ip: _hostController.text.trim(),
        port: parsedPort,
        username: _userController.text.trim(),
        key: _keyController.text.trim(),
      );
      _currentServerId = newId;
    } else {
      server = ServerInfo(
        id: _currentServerId!,
        name: _servernameController.text.trim(),
        ip: _hostController.text.trim(),
        port: parsedPort,
        username: _userController.text.trim(),
        key: _keyController.text.trim(),
      );
    }

    widget.appState.upsertServer(server);
    await serverConfigService.saveServers(widget.appState.servers);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Server configuration saved')));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final servers = widget.appState.servers;
        return Scaffold(
          appBar: AppBar(title: Text(widget.title)),
          body: Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  color: Colors.blueGrey[900],
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Servers',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: servers.length,
                          itemBuilder: (context, index) {
                            final server = servers[index];
                            return ServerCard(
                              server: server,
                              onTap: () {
                                setState(() {
                                  _currentServerId = server.id;
                                  _servernameController.text = server.name;
                                  _userController.text = server.username;
                                  _hostController.text = server.ip;
                                  _portController.text = server.port.toString();
                                  _keyController.text = server.key;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configuración SSH',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LabeledEditField(
                        label: 'Server Name',
                        controller: _servernameController,
                      ),
                      const SizedBox(height: 12),
                      LabeledEditField(
                        label: 'Username',
                        controller: _userController,
                      ),
                      const SizedBox(height: 12),
                      LabeledEditField(label: 'Host', controller: _hostController),
                      const SizedBox(height: 12),
                      LabeledEditField(label: 'Port', controller: _portController),
                      const SizedBox(height: 12),
                      LabeledEditField(
                        label: 'SSH Key',
                        controller: _keyController,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _saveCurrentServer,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Server Config'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.link),
                                label: const Text('Connect'),
                                onPressed: () async {
                                  final navigator = Navigator.of(context);
                                  final messenger = ScaffoldMessenger.of(context);
                                  final success = await widget.sshService.connect(
                                    _userController.text,
                                    _hostController.text,
                                    int.tryParse(_portController.text) ?? 22,
                                    _keyController.text,
                                  );
                                  if (!context.mounted) return;
                                  if (success) {
                                    await widget.sshService.listFiles(
                                      widget.appState.currentPath,
                                    );
                                    navigator.push(
                                      MaterialPageRoute(
                                        builder:
                                            (_) => FileExplorerPage(
                                              appState: widget.appState,
                                              sshService: widget.sshService,
                                            ),
                                      ),
                                    );
                                  } else {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Error al conectar'),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.widgets),
                              label: const Text('Proxmox Panel'),
                              onPressed:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ProxmoxPanel(),
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
