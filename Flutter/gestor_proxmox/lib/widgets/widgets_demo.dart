import 'package:flutter/material.dart';
import 'rich_select_list.dart';
import 'bool_circle.dart';
import 'labeled_edit_field.dart';
import 'port_forward_widget.dart';
import 'server_status_widget.dart';
import 'file_tree_canvas.dart';

class WidgetsDemoPage extends StatefulWidget {
  const WidgetsDemoPage({super.key});
  @override
  State<WidgetsDemoPage> createState() => _WidgetsDemoPageState();
}

class _WidgetsDemoPageState extends State<WidgetsDemoPage> {
  final TextEditingController _editController = TextEditingController(
    text: 'Editable text',
  );
  bool toggle = true;

  final Map<String, List<String>> sample = {
    'Projects': ['app1', 'app2', 'shared-lib'],
    'Logs': ['today.log', 'yesterday.log'],
  };

  final Map<String, dynamic> sampleTree = {
    'root': {
      'etc': {'nginx': {}, 'ssh': {}},
      'var': {
        'log': {'app.log': {}},
        'www': {},
      },
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Widgets Demo')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Rich Select List',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 120,
                child: Card(
                  child: RichSelectList(
                    sections: sample,
                    onItemTap: (s, i) => ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('$s -> $i'))),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bool Circle',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  BoolCircle(value: toggle, size: 36),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => setState(() => toggle = !toggle),
                    child: const Text('Toggle'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Labeled Edit Field',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              LabeledEditField(label: 'Name', controller: _editController),
              const SizedBox(height: 12),
              const Text(
                'Port Forward',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const PortForwardWidget(),
              const SizedBox(height: 12),
              const Text(
                'Server Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: const [
                  ServerStatusWidget(state: ServerState.running),
                  SizedBox(width: 16),
                  ServerStatusWidget(state: ServerState.stopped),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'File Tree Canvas',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Card(
                child: SizedBox(
                  height: 300,
                  child: FileTreeCanvas(tree: sampleTree),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
