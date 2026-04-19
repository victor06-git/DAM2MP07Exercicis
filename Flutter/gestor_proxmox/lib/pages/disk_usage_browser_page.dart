import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/disk_usage_node.dart';
import '../services/ssh_service.dart';

class DiskUsageBrowserPage extends StatefulWidget {
  const DiskUsageBrowserPage({
    super.key,
    required this.sshService,
    required this.initialPath,
  });

  final SSHService sshService;
  final String initialPath;

  @override
  State<DiskUsageBrowserPage> createState() => _DiskUsageBrowserPageState();
}

class _DiskUsageBrowserPageState extends State<DiskUsageBrowserPage> {
  late final TextEditingController _pathController;
  DiskUsageNode? _tree;
  DiskUsageNode? _selected;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController(text: widget.initialPath);
    _loadPath();
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _loadPath([String? path]) async {
    final target = (path ?? _pathController.text).trim();
    if (target.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tree = await widget.sshService.getDiskUsageTree(target, maxDepth: 2);
      setState(() {
        _pathController.text = target;
        _tree = tree;
        _selected = tree;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo analizar: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  String _formatSize(int kb) {
    if (kb >= 1024 * 1024) return '${(kb / (1024 * 1024)).toStringAsFixed(2)} GB';
    if (kb >= 1024) return '${(kb / 1024).toStringAsFixed(1)} MB';
    return '$kb KB';
  }

  @override
  Widget build(BuildContext context) {
    final tree = _tree;
    final selected = _selected;
    return Scaffold(
      appBar: AppBar(title: const Text('Baobab Explorer')),
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
                      labelText: 'Ruta remota',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _loadPath(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : () => _loadPath(),
                  child: const Text('Analizar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Card(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : _error != null
                              ? Center(child: Text(_error!))
                              : tree == null
                                  ? const Center(child: Text('Sin datos'))
                                  : Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: _InteractiveBaobabCanvas(
                                        root: tree,
                                        selectedPath: selected?.path,
                                        onSelect: (node) {
                                          setState(() {
                                            _selected = node;
                                          });
                                        },
                                      ),
                                    ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: selected == null
                            ? const Center(child: Text('Selecciona un segmento'))
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Mini View',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text('Nombre: ${selected.name}'),
                                  const SizedBox(height: 6),
                                  Text('Ruta: ${selected.path}'),
                                  const SizedBox(height: 6),
                                  Text('Tamaño: ${_formatSize(selected.sizeKb)}'),
                                  const SizedBox(height: 6),
                                  Text('Elementos: ${selected.children.length}'),
                                  const SizedBox(height: 10),
                                  if (selected.children.isNotEmpty)
                                    ElevatedButton.icon(
                                      onPressed: () => _loadPath(selected.path),
                                      icon: const Icon(Icons.folder_open),
                                      label: const Text('Entrar en carpeta'),
                                    ),
                                  const SizedBox(height: 10),
                                  const Divider(),
                                  const Text(
                                    'Contenido principal',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: selected.children.length,
                                      itemBuilder: (context, index) {
                                        final child = selected.children[index];
                                        return ListTile(
                                          dense: true,
                                          leading: Icon(
                                            child.children.isEmpty
                                                ? Icons.insert_drive_file
                                                : Icons.folder,
                                          ),
                                          title: Text(
                                            child.name,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          subtitle: Text(_formatSize(child.sizeKb)),
                                          onTap: () {
                                            setState(() {
                                              _selected = child;
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractiveBaobabCanvas extends StatelessWidget {
  const _InteractiveBaobabCanvas({
    required this.root,
    required this.onSelect,
    required this.selectedPath,
  });

  final DiskUsageNode root;
  final void Function(DiskUsageNode node) onSelect;
  final String? selectedPath;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final segments = _buildSegments(root, size);
        return GestureDetector(
          onTapDown: (details) {
            final tapped = segments.where((s) => s.contains(details.localPosition)).toList();
            if (tapped.isNotEmpty) {
              onSelect(tapped.last.node);
            }
          },
          child: CustomPaint(
            size: size,
            painter: _InteractiveBaobabPainter(
              root: root,
              segments: segments,
              selectedPath: selectedPath,
            ),
          ),
        );
      },
    );
  }

  List<_ArcSegment> _buildSegments(DiskUsageNode root, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.46;
    const ringWidth = 34.0;
    final segments = <_ArcSegment>[];

    void addLevel({
      required List<DiskUsageNode> nodes,
      required int total,
      required double innerRadius,
      required int depth,
    }) {
      if (nodes.isEmpty || innerRadius > maxRadius) return;
      double startAngle = -math.pi / 2;
      for (final node in nodes) {
        final ratio = total <= 0 ? 0.0 : node.sizeKb / total;
        final sweep = (ratio * math.pi * 2).clamp(0.03, math.pi * 2);
        segments.add(
          _ArcSegment(
            node: node,
            center: center,
            innerRadius: innerRadius,
            outerRadius: innerRadius + ringWidth,
            startAngle: startAngle,
            sweepAngle: sweep,
            depth: depth,
          ),
        );
        if (node.children.isNotEmpty) {
          addLevel(
            nodes: node.children,
            total: node.sizeKb <= 0 ? 1 : node.sizeKb,
            innerRadius: innerRadius + ringWidth + 4,
            depth: depth + 1,
          );
        }
        startAngle += sweep;
      }
    }

    addLevel(
      nodes: root.children,
      total: root.sizeKb <= 0 ? 1 : root.sizeKb,
      innerRadius: 34,
      depth: 0,
    );
    return segments;
  }
}

class _InteractiveBaobabPainter extends CustomPainter {
  _InteractiveBaobabPainter({
    required this.root,
    required this.segments,
    required this.selectedPath,
  });

  final DiskUsageNode root;
  final List<_ArcSegment> segments;
  final String? selectedPath;
  final List<Color> palette = const [
    Color(0xFF6CC070),
    Color(0xFF4DB6AC),
    Color(0xFF64B5F6),
    Color(0xFFFFB74D),
    Color(0xFFE57373),
    Color(0xFFBA68C8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final isSelected = segment.node.path == selectedPath;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (segment.outerRadius - segment.innerRadius) - 2
        ..color = palette[(segment.depth + i) % palette.length].withValues(
          alpha: isSelected ? 1.0 : 0.9,
        );
      final rect = Rect.fromCircle(
        center: segment.center,
        radius: (segment.outerRadius + segment.innerRadius) / 2,
      );
      canvas.drawArc(rect, segment.startAngle, segment.sweepAngle, false, paint);
    }

    final center = Offset(size.width / 2, size.height / 2);
    final text = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      text: TextSpan(
        text: root.name,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    )..layout(maxWidth: 110);
    text.paint(canvas, Offset(center.dx - text.width / 2, center.dy - text.height / 2));
  }

  @override
  bool shouldRepaint(covariant _InteractiveBaobabPainter oldDelegate) =>
      oldDelegate.root != root || oldDelegate.selectedPath != selectedPath;
}

class _ArcSegment {
  _ArcSegment({
    required this.node,
    required this.center,
    required this.innerRadius,
    required this.outerRadius,
    required this.startAngle,
    required this.sweepAngle,
    required this.depth,
  });

  final DiskUsageNode node;
  final Offset center;
  final double innerRadius;
  final double outerRadius;
  final double startAngle;
  final double sweepAngle;
  final int depth;

  bool contains(Offset point) {
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    final radius = math.sqrt(dx * dx + dy * dy);
    if (radius < innerRadius || radius > outerRadius) return false;
    var angle = math.atan2(dy, dx);
    if (angle < -math.pi / 2) {
      angle += 2 * math.pi;
    }
    final start = startAngle < -math.pi / 2 ? startAngle + 2 * math.pi : startAngle;
    final end = start + sweepAngle;
    return angle >= start && angle <= end;
  }
}
