import 'dart:typed_data';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'package:gestor_proxmox/models/server_config.dart';
import 'package:gestor_proxmox/screens/server_stats.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FileExplorerScreen extends StatefulWidget {
  final SSHClient client;
  final ServerConfig config;
  const FileExplorerScreen({
    super.key,
    required this.client,
    required this.config,
  });

  @override
  State<FileExplorerScreen> createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  late SftpClient sftp;
  List<SftpName> items = [];
  List<String> directoryStack = [];
  String currentPath = '.';
  bool isLoading = true, isServerRunning = false, isServerFolder = false;
  String? serverType;
  int serverPort = 3000;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    sftp = await widget.client.sftp();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    try {
      final list = await sftp.listdir(currentPath);
      items = list
          .where((i) => i.filename != '.' && i.filename != '..')
          .toList();

      serverType = items.any((i) => i.filename == 'package.json')
          ? 'NodeJS'
          : items.any(
              (i) => i.filename == 'pom.xml' || i.filename.endsWith('.jar'),
            )
          ? 'Java'
          : null;
      isServerFolder = serverType != null;
      if (isServerFolder) {
        final res = await widget.client.run('lsof -i :$serverPort');
        isServerRunning = res.isNotEmpty;
      }
    } catch (e) {
      _showMsg("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _cmdServer(String action) async {
    setState(() => isLoading = true);
    try {
      if (action == 'STOP' || action == 'RESTART') {
        await widget.client.run('cd "$currentPath" && node --run pm2stop');
      }
      if (action == 'START' || action == 'RESTART') {
        await widget.client.run('cd "$currentPath" && node --run pm2start');
        await widget.client.forwardLocal('127.0.0.1', serverPort);
      }
      await Future.delayed(const Duration(seconds: 2));
      _load();
    } catch (e) {
      _showMsg("Error PM2: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _upload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );

    if (result == null || result.files.single.path == null) return;

    setState(() => isLoading = true);
    String path = result.files.single.path!;
    String name = result.files.single.name;

    try {
      final remoteFile = await sftp.open(
        "$currentPath/$name",
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write,
      );

      final localFile = File(path);
      await remoteFile.write(localFile.openRead().cast<Uint8List>());
      await remoteFile.close();

      _showMsg("Arxiu '$name' pujat correctament", isError: false);
      _load();
    } catch (e) {
      _showMsg("Error en la pujada: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _download(SftpName item, bool isDir) async {
    Directory? d = Platform.isAndroid
        ? Directory('/storage/emulated/0/Download')
        : await getDownloadsDirectory();
    String name = isDir ? "${item.filename}.zip" : item.filename;
    if (isDir)
      await widget.client.run(
        'cd "$currentPath" && zip -r "$name" "${item.filename}"',
      );

    final rf = await sftp.open("$currentPath/$name");
    await File("${d!.path}/$name").openWrite().addStream(rf.read());
    await rf.close();
    if (isDir) await sftp.remove("$currentPath/$name");
    _showMsg("Baixat a Downloads", isError: false);
  }

  // --- FUNCIÓN DE DESCOMPRESIÓN REMOTA ---
  Future<void> _unzipRemote(String filename) async {
    setState(() => isLoading = true);
    try {
      // Ejecutamos unzip en el servidor Linux
      await widget.client.run(
        'unzip -o "$currentPath/$filename" -d "$currentPath/"',
      );
      _showMsg("Arxiu descomprimit al servidor", isError: false);
      _load();
    } catch (e) {
      _showMsg("Error al descomprimir: $e");
      setState(() => isLoading = false);
    }
  }

  void _showFileInfo(SftpName item) {
    final rawTime = item.attr.modifyTime;
    DateTime date;

    // Corregim l'error assignant el tipus correctament mitjançant comprovació
    if (rawTime is DateTime) {
      date = rawTime as DateTime;
    } else if (rawTime is int) {
      date = DateTime.fromMillisecondsSinceEpoch(rawTime * 1000);
    } else {
      date = DateTime.now(); // Valor per defecte si és null o desconegut
    }

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          item.filename,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(
              Icons.calendar_today,
              "Modificat",
              DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal()),
            ),
            _infoRow(
              Icons.lock_outline,
              "Permisos",
              (item.attr.mode?.value ?? 0 & 0xFFF).toRadixString(8),
            ),
            _infoRow(
              Icons.data_usage,
              "Mida",
              "${((item.attr.size ?? 0) / 1024).toStringAsFixed(2)} KB",
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Tancar"),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: directoryStack.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () {
                  setState(() => currentPath = directoryStack.removeLast());
                  _load();
                },
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentPath == '.' ? "Inici" : currentPath.split('/').last,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.config.host,
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.blue),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => ServerStatsScreen(
                  client: widget.client,
                  currentPath: currentPath,
                  items: items,
                ),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTopActions(),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 8),
                    itemBuilder: (c, i) => _buildFileCard(items[i]),
                  ),
                ),
                if (isServerFolder) _serverBar(),
              ],
            ),
    );
  }

  Widget _buildTopActions() => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Expanded(
          child: _actionBtn(
            "Pujar Fitxer",
            Icons.upload_file,
            Colors.blue,
            _upload,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionBtn(
            "Nou Item",
            Icons.create_new_folder,
            Colors.blueGrey,
            _showCreateDialog,
          ),
        ),
      ],
    ),
  );

  Widget _actionBtn(String t, IconData icon, Color col, VoidCallback f) =>
      ElevatedButton.icon(
        onPressed: f,
        icon: Icon(icon, size: 18),
        label: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: col,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: col.withOpacity(0.2)),
          ),
        ),
      );

  Widget _buildFileCard(SftpName item) {
    bool isDir = (item.attr.mode?.value ?? 0) & 0x4000 != 0;
    bool isZip = item.filename.toLowerCase().endsWith('.zip');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDir ? Colors.amber : Colors.blueGrey).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isDir ? Icons.folder : Icons.insert_drive_file,
            color: isDir ? Colors.amber.shade700 : Colors.blueGrey.shade700,
          ),
        ),
        title: Text(
          item.filename,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // BOTÓN DE DESCOMPRIMIR (Solo si es .zip)
            if (isZip)
              IconButton(
                icon: const Icon(
                  Icons.unarchive,
                  color: Colors.orange,
                  size: 20,
                ),
                tooltip: "Descomprimir al servidor",
                onPressed: () => _unzipRemote(item.filename),
              ),
            IconButton(
              icon: const Icon(
                Icons.download_rounded,
                size: 20,
                color: Colors.blueGrey,
              ),
              onPressed: () => _download(item, isDir),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.blueGrey),
              onSelected: (v) async {
                if (v == 'info') _showFileInfo(item);
                if (v == 'del') {
                  if (isDir)
                    await sftp.rmdir("$currentPath/${item.filename}");
                  else
                    await sftp.remove("$currentPath/${item.filename}");
                  _load();
                }
              },
              itemBuilder: (c) => [
                const PopupMenuItem(
                  value: 'info',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18),
                      SizedBox(width: 8),
                      Text("Info"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'del',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Eliminar", style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: isDir
            ? () {
                directoryStack.add(currentPath);
                setState(() => currentPath += "/${item.filename}");
                _load();
              }
            : null,
      ),
    );
  }

  Widget _serverBar() => Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15),
      ],
    ),
    child: SafeArea(
      child: Row(
        children: [
          Icon(
            Icons.circle,
            color: isServerRunning ? Colors.green : Colors.red,
            size: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Port $serverPort ($serverType)",
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          IconButton(
            icon: Icon(
              isServerRunning ? Icons.restart_alt : Icons.play_arrow_rounded,
              color: Colors.blue,
            ),
            onPressed: () => _cmdServer(isServerRunning ? 'RESTART' : 'START'),
          ),
          if (isServerRunning)
            IconButton(
              icon: const Icon(Icons.stop_rounded, color: Colors.red),
              onPressed: () => _cmdServer('STOP'),
            ),
        ],
      ),
    ),
  );

  void _showMsg(String m, {bool isError = true}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(m),
          backgroundColor: isError ? Colors.redAccent : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

  Future<void> _showCreateDialog() async {
    String type = 'Fitxer';
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Nou Item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                value: type,
                items: ['Fitxer', 'Directori']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setS(() => type = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                  hintText: "Nom",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (type == 'Directori')
                  await sftp.mkdir("$currentPath/${ctrl.text}");
                else
                  await (await sftp.open(
                    "$currentPath/${ctrl.text}",
                    mode: SftpFileOpenMode.create,
                  )).close();
                Navigator.pop(c);
                _load();
              },
              child: const Text("Crear"),
            ),
          ],
        ),
      ),
    );
  }
}
