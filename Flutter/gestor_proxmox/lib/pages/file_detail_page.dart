import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../models/file_item.dart';
import '../services/ssh_service.dart';
import '../state/app_state.dart';

class FileDetailPage extends StatefulWidget {
  const FileDetailPage({
    super.key,
    required this.sshService,
    required this.appState,
    required this.file,
  });

  final SSHService sshService;
  final AppStateController appState;
  final FileItem file;

  @override
  State<FileDetailPage> createState() => _FileDetailPageState();
}

class _FileDetailPageState extends State<FileDetailPage> {
  String? serverType;
  bool isRunning = false;
  late final TextEditingController _renameController;

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController(text: widget.file.name);
    if (widget.file.isDirectory) _checkServerType();
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  Future<void> _checkServerType() async {
    serverType = await widget.sshService.checkServerType(
      p.posix.join(widget.appState.currentPath, widget.file.name),
    );
    if (serverType != null) await _checkServerStatus();
    setState(() {});
  }

  Future<void> _checkServerStatus() async {
    isRunning = await widget.sshService.isServerRunning(
      serverType ?? '',
      p.posix.join(widget.appState.currentPath, widget.file.name),
    );
    setState(() {});
  }

  Future<void> startServer() async {
    final path = p.posix.join(widget.appState.currentPath, widget.file.name);
    String command;
    if (serverType == 'node') {
      command = 'cd "$path" && nohup npm run dev > /dev/null 2>&1 &';
    } else if (serverType == 'java') {
      command = 'cd "$path" && nohup mvn spring-boot:run > /dev/null 2>&1 &';
    } else {
      return;
    }
    await widget.sshService.executeCommand(command);
    await Future.delayed(const Duration(seconds: 3));
    await _checkServerStatus();
  }

  Future<void> stopServer() async {
    final process = serverType == 'node' ? 'node' : 'java';
    await widget.sshService.executeCommand('pkill -f $process');
    await _checkServerStatus();
  }

  Future<void> restartServer() async {
    await stopServer();
    await startServer();
  }

  Future<void> _renameFile() async {
    final navigator = Navigator.of(context);
    final oldPath = p.posix.join(widget.appState.currentPath, widget.file.name);
    final newName = _renameController.text.trim();
    if (newName.isEmpty || newName == widget.file.name) return;
    final newPath = p.posix.join(widget.appState.currentPath, newName);
    await widget.sshService.renamePath(oldPath, newPath);
    await widget.sshService.listFiles(widget.appState.currentPath);
    if (!context.mounted) return;
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File Details')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.file.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Icon(
              widget.file.isDirectory ? Icons.folder : Icons.insert_drive_file,
              size: 100,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Iniciando descarga...')),
                    );
                    final fullRemotePath = p.posix.join(
                      widget.appState.currentPath,
                      widget.file.name,
                    );
                    await widget.sshService.downloadPath(fullRemotePath);
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Descarga completada')),
                    );
                  },
                  child: const Text('Download'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await widget.sshService.deletePath(
                      p.posix.join(widget.appState.currentPath, widget.file.name),
                    );
                    await widget.sshService.listFiles(widget.appState.currentPath);
                    if (!context.mounted) return;
                    navigator.pop();
                  },
                  child: const Text('Delete'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _renameController,
                    decoration: const InputDecoration(labelText: 'New name'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _renameFile,
                  child: const Text('Rename'),
                ),
              ],
            ),
            if (!widget.file.isDirectory &&
                widget.file.name.toLowerCase().endsWith('.zip'))
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: ElevatedButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await widget.sshService.unzipFile(
                      p.posix.join(widget.appState.currentPath, widget.file.name),
                      widget.appState.currentPath,
                    );
                    await widget.sshService.listFiles(widget.appState.currentPath);
                    if (!context.mounted) return;
                    navigator.pop();
                  },
                  child: const Text('Unzip on server'),
                ),
              ),
            if (serverType != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: isRunning ? null : startServer,
                      child: const Text('Start'),
                    ),
                    ElevatedButton(
                      onPressed: isRunning ? stopServer : null,
                      child: const Text('Stop'),
                    ),
                    ElevatedButton(
                      onPressed: isRunning ? restartServer : null,
                      child: const Text('Restart'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Permissions',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(widget.file.permissions),
          ],
        ),
      ),
    );
  }
}
