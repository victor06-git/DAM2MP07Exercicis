import 'package:flutter/material.dart';

/// Muestra secciones con título en negrita y elementos indentados seleccionables.
class RichSelectList extends StatelessWidget {
  final Map<String, List<String>> sections;
  final void Function(String section, String item)? onItemTap;

  const RichSelectList({super.key, required this.sections, this.onItemTap});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: sections.entries.expand<Widget>((entry) {
        final title = entry.key;
        final items = entry.value;
        return [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 12.0,
            ),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          ...items.map(
            (it) => InkWell(
              onTap: () => onItemTap?.call(title, it),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 24.0,
                ),
                child: Text(
                  it,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
            ),
          ),
        ];
      }).toList(),
    );
  }
}
