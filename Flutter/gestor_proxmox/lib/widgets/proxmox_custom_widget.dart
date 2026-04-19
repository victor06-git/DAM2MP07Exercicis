import 'package:flutter/material.dart';

import '../models/disk_usage_node.dart';
import 'baobab_canvas.dart';
import 'bool_circle.dart';
import 'labeled_edit_field.dart';
import 'port_forward_widget.dart';
import 'rich_select_list.dart';
import 'server_status_widget.dart';

/// Single custom widget that groups all assignment requirements.
class ProxmoxCustomWidget extends StatefulWidget {
  const ProxmoxCustomWidget({super.key});

  @override
  State<ProxmoxCustomWidget> createState() => _ProxmoxCustomWidgetState();
}

class _ProxmoxCustomWidgetState extends State<ProxmoxCustomWidget> {
  final TextEditingController _nameCtrl = TextEditingController();
  bool _isHealthy = true;
  ServerState _serverState = ServerState.running;

  final Map<String, List<String>> _sections = {
    'Projects': ['app-node', 'service-java', 'scripts'],
    'Backups': ['backup-2026-04-17.zip'],
  };

  final DiskUsageNode _sampleTree = DiskUsageNode(
    name: '/',
    path: '/',
    sizeKb: 10 * 1024 * 1024,
    children: [
      DiskUsageNode(name: 'home', path: '/home', sizeKb: 4 * 1024 * 1024),
      DiskUsageNode(name: 'var', path: '/var', sizeKb: 3 * 1024 * 1024),
      DiskUsageNode(name: 'srv', path: '/srv', sizeKb: 2 * 1024 * 1024),
      DiskUsageNode(name: 'opt', path: '/opt', sizeKb: 1024 * 1024),
    ],
  );

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _toggleHealth() {
    setState(() {
      _isHealthy = !_isHealthy;
      _serverState = _isHealthy ? ServerState.running : ServerState.stopped;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Custom Proxmox Widget',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Server groups',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: RichSelectList(
                            sections: _sections,
                            onItemTap: (s, i) => ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('$s -> $i'))),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Health',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            BoolCircle(value: _isHealthy, size: 32),
                            const SizedBox(width: 12),
                            ServerStatusWidget(state: _serverState),
                          ],
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _toggleHealth,
                          child: const Text('Toggle state'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            LabeledEditField(
              label: 'Server name',
              controller: _nameCtrl,
              hint: 'Editable value',
            ),
            const SizedBox(height: 8),
            const PortForwardWidget(),
            const SizedBox(height: 8),
            const Text(
              'Disk usage tree (Baobab style)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 260,
              child: RepaintBoundary(child: BaobabCanvas(root: _sampleTree)),
            ),
          ],
        ),
      ),
    );
  }
}
