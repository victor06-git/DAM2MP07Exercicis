import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../services/ssh_service.dart';
import '../state/app_state.dart';
import 'disk_usage_browser_page.dart';
import 'file_detail_page.dart';

class FileExplorerPage extends StatefulWidget {
  const FileExplorerPage({
    super.key,
    required this.appState,
    required this.sshService,
  });

  final AppStateController appState;
  final SSHService sshService;

  @override
  State<FileExplorerPage> createState() => _FileExplorerPageState();
}

class _FileExplorerPageState extends State<FileExplorerPage> {
  String _normalizeRemotePath(String path) {
    if (path.trim().isEmpty) return '/';
    final normalized = p.posix.normalize(path);
    return normalized.startsWith('/') ? normalized : '/$normalized';
  }

  String _parentPath(String path) {
    final normalized = _normalizeRemotePath(path);
    if (normalized == '/') return '/';
    final parent = p.posix.dirname(normalized);
    return parent == '.' ? '/' : parent;
  }

  Future<void> _navigateTo(String path) async {
    final cleanPath = _normalizeRemotePath(path);
    widget.appState.setCurrentPath(cleanPath);
    await widget.sshService.listFiles(cleanPath);
  }

  Future<void> _uploadFile() async {
    final picked = await FilePicker.platform.pickFiles();
    if (picked == null) return;
    final filePath = picked.files.single.path;
    if (filePath == null) return;
    final result = await widget.sshService.uploadFile(
      filePath,
      widget.appState.currentPath,
    );
    await widget.sshService.listFiles(widget.appState.currentPath);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _uploadDirectory() async {
    final dirPath = await FilePicker.platform.getDirectoryPath();
    if (dirPath == null) return;
    final result = await widget.sshService.uploadDirectoryAsZipAndExtract(
      dirPath,
      widget.appState.currentPath,
    );
    await widget.sshService.listFiles(widget.appState.currentPath);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  Widget _buildPathBreadcrumb(String path) {
    final normalized = _normalizeRemotePath(path);
    final parts = normalized.split('/').where((e) => e.isNotEmpty).toList();
    final crumbs = <Widget>[
      InkWell(
        onTap: () => _navigateTo('/'),
        child: const Text(
          '/',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    ];

    var acc = '';
    for (final part in parts) {
      acc = '$acc/$part';
      final current = acc;
      crumbs.add(const Text('  /  ', style: TextStyle(color: Colors.white70)));
      crumbs.add(
        InkWell(
          onTap: () => _navigateTo(current),
          child: Text(
            part,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: crumbs),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.blueGrey[900],
          appBar: AppBar(
            title: const Text('Proxmox Drive'),
            actions: [
              IconButton(
                tooltip: 'Baobab explorer',
                icon: const Icon(Icons.pie_chart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DiskUsageBrowserPage(
                        sshService: widget.sshService,
                        initialPath: widget.appState.currentPath,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                color: const Color.fromARGB(255, 18, 23, 26),
                width: double.infinity,
                child: _buildPathBreadcrumb(widget.appState.currentPath),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.appState.currentFiles.length,
                  itemBuilder: (context, index) {
                    final file = widget.appState.currentFiles[index];
                    return ListTile(
                      leading: Icon(
                        file.isDirectory ? Icons.folder : Icons.insert_drive_file,
                        color:
                            file.isDirectory ? Colors.amber : Colors.blueAccent,
                      ),
                      title: Text(
                        file.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        if (!file.isDirectory) return;
                        if (file.name == '.') return;
                        if (file.name == '..') {
                          _navigateTo(_parentPath(widget.appState.currentPath));
                          return;
                        }
                        final newPath = p.posix.join(
                          widget.appState.currentPath,
                          file.name,
                        );
                        _navigateTo(newPath);
                      },
                      onLongPress: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => FileDetailPage(
                                  sshService: widget.sshService,
                                  appState: widget.appState,
                                  file: file,
                                ),
                          ),
                        ).then((_) {
                          widget.sshService.listFiles(widget.appState.currentPath);
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              await showModalBottomSheet<void>(
                context: context,
                builder:
                    (sheetContext) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.upload_file),
                            title: const Text('Upload file'),
                            onTap: () async {
                              Navigator.pop(sheetContext);
                              await _uploadFile();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.drive_folder_upload),
                            title: const Text('Upload folder (zip + extract)'),
                            onTap: () async {
                              Navigator.pop(sheetContext);
                              await _uploadDirectory();
                            },
                          ),
                        ],
                      ),
                    ),
              );
            },
            icon: const Icon(Icons.upload),
            label: const Text('Upload'),
          ),
        );
      },
    );
  }
}
