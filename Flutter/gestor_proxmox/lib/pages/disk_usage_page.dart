import 'package:flutter/material.dart';

import '../models/disk_usage_node.dart';
import '../services/ssh_service.dart';
import '../widgets/baobab_canvas.dart';

class DiskUsagePage extends StatefulWidget {
  const DiskUsagePage({
    super.key,
    required this.sshService,
    required this.initialPath,
  });

  final SSHService sshService;
  final String initialPath;

  @override
  State<DiskUsagePage> createState() => _DiskUsagePageState();
}

class _DiskUsagePageState extends State<DiskUsagePage> {
  late final TextEditingController _pathController;
  DiskUsageNode? _tree;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController(text: widget.initialPath);
    _load();
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tree = await widget.sshService.getDiskUsageTree(
        _pathController.text.trim(),
        maxDepth: 3,
      );
      setState(() {
        _tree = tree;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Baobab Disk Usage')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pathController,
                    decoration: const InputDecoration(
                      labelText: 'Remote path',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _load, child: const Text('Analyze')),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!))
                        : _tree == null
                            ? const Center(child: Text('No data'))
                            : Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: BaobabCanvas(root: _tree!),
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
