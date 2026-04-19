import 'package:flutter/material.dart';

class PortForwardWidget extends StatefulWidget {
  const PortForwardWidget({super.key});

  @override
  State<PortForwardWidget> createState() => _PortForwardWidgetState();
}

class _PortForwardWidgetState extends State<PortForwardWidget> {
  final List<Map<String, TextEditingController>> entries = [];

  void _add() {
    setState(
      () => entries.add({
        'from': TextEditingController(text: '80'),
        'to': TextEditingController(),
      }),
    );
  }

  void _remove(int i) {
    final removed = entries.removeAt(i);
    removed['from']?.dispose();
    removed['to']?.dispose();
    setState(() {});
  }

  @override
  void dispose() {
    for (final entry in entries) {
      entry['from']?.dispose();
      entry['to']?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Port forwards',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            ElevatedButton(onPressed: _add, child: const Text('Add')),
          ],
        ),
        const SizedBox(height: 8),
        ...entries.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: TextField(
                    controller: item['from'],
                    decoration: const InputDecoration(labelText: 'From'),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 56,
                  child: TextField(
                    controller: item['to'],
                    decoration: const InputDecoration(labelText: 'To'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _remove(i),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
