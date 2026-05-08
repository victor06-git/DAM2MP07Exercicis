import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../services/ssh_service.dart';
import '../state/app_state.dart';
import 'disk_usage_browser_page.dart';
import 'disk_usage_system_page.dart';
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _deleteFile(String fileName) async {
    final path = p.posix.join(widget.appState.currentPath, fileName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Are you sure you want to delete "$fileName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.sshService.deletePath(path);
      await widget.sshService.listFiles(widget.appState.currentPath);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Deleted "$fileName"')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _renameFile(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'New name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    try {
      final oldPath = p.posix.join(widget.appState.currentPath, oldName);
      final newPath = p.posix.join(widget.appState.currentPath, newName);
      await widget.sshService.renamePath(oldPath, newPath);
      await widget.sshService.listFiles(widget.appState.currentPath);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Renamed "$oldName" to "$newName"')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final folderName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (folderName == null || folderName.isEmpty) return;
    try {
      final path = p.posix.join(widget.appState.currentPath, folderName);
      await widget.sshService.executeCommand('mkdir -p "$path"');
      await widget.sshService.listFiles(widget.appState.currentPath);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Created folder "$folderName"')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
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
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
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
                tooltip: 'System Disk Usage',
                icon: const Icon(Icons.storage),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DiskUsageSystemPage(sshService: widget.sshService),
                    ),
                  );
                },
              ),
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
                        file.isDirectory
                            ? Icons.folder
                            : Icons.insert_drive_file,
                        color: file.isDirectory
                            ? Colors.amber
                            : Colors.blueAccent,
                      ),
                      title: Text(
                        file.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          if (!file.isDirectory)
                            IconButton(
                              icon: const Icon(Icons.download, size: 20),
                              tooltip: 'Download',
                              onPressed: () {
                                final filePath = p.posix.join(
                                  widget.appState.currentPath,
                                  file.name,
                                );
                                widget.sshService.downloadPath(filePath);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Downloading ${file.name}...',
                                    ),
                                  ),
                                );
                              },
                            ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              size: 20,
                              color: Colors.red,
                            ),
                            tooltip: 'Delete',
                            onPressed: () {
                              _deleteFile(file.name);
                            },
                          ),
                        ],
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
                        showModalBottomSheet(
                          context: context,
                          builder: (ctx) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.info),
                                  title: const Text('View Details'),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FileDetailPage(
                                          sshService: widget.sshService,
                                          appState: widget.appState,
                                          file: file,
                                        ),
                                      ),
                                    ).then((_) {
                                      widget.sshService.listFiles(
                                        widget.appState.currentPath,
                                      );
                                    });
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.drive_file_rename_outline,
                                  ),
                                  title: const Text('Rename'),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _renameFile(file.name);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
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
                builder: (sheetContext) => SafeArea(
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
                      ListTile(
                        leading: const Icon(Icons.create_new_folder),
                        title: const Text('Create folder'),
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          await _createFolder();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('New'),
          ),
        );
      },
    );
  }
}
