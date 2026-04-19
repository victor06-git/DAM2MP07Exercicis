import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Widget personalizado unico que integra todos los requisitos del enunciado.
class ProxmoxPanel extends StatefulWidget {
  const ProxmoxPanel({super.key});

  @override
  State<ProxmoxPanel> createState() => _ProxmoxPanelState();
}

enum _ServerState { running, stopped, restarting, error }

class _PortForwardEntry {
  _PortForwardEntry({
    required this.targetController,
  });

  final TextEditingController targetController;
  bool enabled = true;
}

class _ProxmoxPanelState extends State<ProxmoxPanel> {
  final TextEditingController _nameCtrl = TextEditingController();
  final List<_PortForwardEntry> _portForwards = [
    _PortForwardEntry(targetController: TextEditingController(text: '3000')),
  ];

  bool _healthy = true;
  _ServerState _serverState = _ServerState.running;

  final Map<String, List<String>> _sections = const {
    'Projects': ['app-node', 'service-java', 'scripts'],
    'Backups': ['backup-2026-04-17.zip'],
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final entry in _portForwards) {
      entry.targetController.dispose();
    }
    super.dispose();
  }

  void _toggleHealth() {
    setState(() {
      _healthy = !_healthy;
      _serverState = _healthy ? _ServerState.running : _ServerState.stopped;
    });
  }

  void _addForward() {
    setState(() {
      _portForwards.add(
        _PortForwardEntry(targetController: TextEditingController()),
      );
    });
  }

  void _removeForward(int index) {
    final removed = _portForwards.removeAt(index);
    removed.targetController.dispose();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proxmox Panel')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Custom Proxmox Widget',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _SelectableSectionList(
                          sections: _sections,
                          onItemTap: (section, item) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$section -> $item')),
                            );
                          },
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
                                _BoolCanvasCircle(value: _healthy, size: 30),
                                const SizedBox(width: 10),
                                _ServerStatusView(state: _serverState),
                              ],
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: _toggleHealth,
                              child: const Text('Toggle'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _LabeledEditableField(
                  label: 'Server name',
                  controller: _nameCtrl,
                ),
                const SizedBox(height: 8),
                _PortForwardEditor(
                  entries: _portForwards,
                  onAdd: _addForward,
                  onRemove: _removeForward,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Disk usage tree (Baobab style)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 250, child: _BaobabLikeCanvas()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectableSectionList extends StatelessWidget {
  const _SelectableSectionList({
    required this.sections,
    required this.onItemTap,
  });

  final Map<String, List<String>> sections;
  final void Function(String section, String item) onItemTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView(
        children: sections.entries.expand((entry) {
          return [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...entry.value.map(
              (item) => InkWell(
                onTap: () => onItemTap(entry.key, item),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 10,
                    top: 4,
                    bottom: 4,
                  ),
                  child: Text(item, style: const TextStyle(fontSize: 13)),
                ),
              ),
            ),
          ];
        }).toList(),
      ),
    );
  }
}

class _BoolCanvasCircle extends StatelessWidget {
  const _BoolCanvasCircle({required this.value, required this.size});

  final bool value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _BoolCirclePainter(value),
    );
  }
}

class _BoolCirclePainter extends CustomPainter {
  _BoolCirclePainter(this.value);

  final bool value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = value ? Colors.green : Colors.red,
    );
  }

  @override
  bool shouldRepaint(covariant _BoolCirclePainter oldDelegate) =>
      oldDelegate.value != value;
}

class _LabeledEditableField extends StatelessWidget {
  const _LabeledEditableField({
    required this.label,
    required this.controller,
  });

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
      ],
    );
  }
}

class _PortForwardEditor extends StatelessWidget {
  const _PortForwardEditor({
    required this.entries,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  final List<_PortForwardEntry> entries;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Port 80 redirection',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(onPressed: onAdd, child: const Text('Add')),
              ],
            ),
            ...entries.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const SizedBox(width: 60, child: Text('80')),
                    const Text('->'),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: item.targetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => onChanged(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: item.enabled,
                      onChanged: (value) {
                        item.enabled = value;
                        onChanged();
                      },
                    ),
                    IconButton(
                      onPressed: () => onRemove(index),
                      icon: const Icon(Icons.delete),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ServerStatusView extends StatelessWidget {
  const _ServerStatusView({required this.state});

  final _ServerState state;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String text;
    switch (state) {
      case _ServerState.running:
        icon = Icons.play_arrow;
        color = Colors.green;
        text = 'Running';
        break;
      case _ServerState.stopped:
        icon = Icons.stop;
        color = Colors.red;
        text = 'Stopped';
        break;
      case _ServerState.restarting:
        icon = Icons.refresh;
        color = Colors.orange;
        text = 'Restarting';
        break;
      case _ServerState.error:
        icon = Icons.error_outline;
        color = Colors.purple;
        text = 'Error';
        break;
    }
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _BaobabLikeCanvas extends StatefulWidget {
  const _BaobabLikeCanvas();

  @override
  State<_BaobabLikeCanvas> createState() => _BaobabLikeCanvasState();
}

class _BaobabLikeCanvasState extends State<_BaobabLikeCanvas>
    with SingleTickerProviderStateMixin {
  (int ring, int index)? _selected;
  late final AnimationController _explodeController;

  @override
  void initState() {
    super.initState();
    _explodeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _explodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _explodeController,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final data = _BaobabPainterData(
            size: size,
            selected: _selected,
            explodeProgress: Curves.easeOutCubic.transform(_explodeController.value),
          );
          return GestureDetector(
            onTapDown: (details) {
              final hit = data.hitTest(details.localPosition);
              if (hit != null) {
                setState(() {
                  _selected = hit;
                });
                _explodeController.forward(from: 0);
              }
            },
            child: CustomPaint(
              painter: _BaobabPainter(data),
              child: const SizedBox.expand(),
            ),
          );
        },
      ),
    );
  }
}

class _BaobabPainterData {
  _BaobabPainterData({
    required this.size,
    required this.selected,
    required this.explodeProgress,
  }) {
    _build();
  }

  final Size size;
  final (int ring, int index)? selected;
  final double explodeProgress;
  final List<_Sector> sectors = [];

  static const widths = [30.0, 26.0, 22.0];
  static const ratios = [
    [0.42, 0.34, 0.16, 0.08],
    [0.58, 0.22, 0.12, 0.08],
    [0.63, 0.2, 0.1, 0.07],
  ];

  void _build() {
    sectors.clear();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.38;
    for (int ring = 0; ring < widths.length; ring++) {
      double start = -math.pi / 2;
      final ringRadius = radius - (ring * 30);
      for (int index = 0; index < ratios[ring].length; index++) {
        final sweep = ratios[ring][index] * math.pi * 2;
        final isSelected = selected?.$1 == ring && selected?.$2 == index;
        final mid = start + (sweep / 2);
        final offset = isSelected ? 14.0 * explodeProgress : 0.0;
        final shiftedCenter = Offset(
          center.dx + math.cos(mid) * offset,
          center.dy + math.sin(mid) * offset,
        );
        sectors.add(
          _Sector(
            ring: ring,
            index: index,
            center: shiftedCenter,
            radius: ringRadius,
            strokeWidth: widths[ring],
            start: start,
            sweep: sweep,
          ),
        );
        start += sweep;
      }
    }
  }

  (int ring, int index)? hitTest(Offset point) {
    for (int i = sectors.length - 1; i >= 0; i--) {
      if (sectors[i].contains(point)) {
        return (sectors[i].ring, sectors[i].index);
      }
    }
    return null;
  }
}

class _Sector {
  _Sector({
    required this.ring,
    required this.index,
    required this.center,
    required this.radius,
    required this.strokeWidth,
    required this.start,
    required this.sweep,
  });

  final int ring;
  final int index;
  final Offset center;
  final double radius;
  final double strokeWidth;
  final double start;
  final double sweep;

  bool contains(Offset point) {
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final outer = radius + (strokeWidth / 2);
    final inner = radius - (strokeWidth / 2);
    if (distance < inner || distance > outer) return false;

    var angle = math.atan2(dy, dx);
    while (angle < -math.pi / 2) {
      angle += 2 * math.pi;
    }
    var normalizedStart = start;
    while (normalizedStart < -math.pi / 2) {
      normalizedStart += 2 * math.pi;
    }
    final normalizedEnd = normalizedStart + sweep;
    return angle >= normalizedStart && angle <= normalizedEnd;
  }
}

class _BaobabPainter extends CustomPainter {
  _BaobabPainter(this.data);

  final _BaobabPainterData data;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final colors = [
      Colors.green.shade400,
      Colors.cyan.shade400,
      Colors.blue.shade400,
      Colors.orange.shade400,
      Colors.red.shade400,
      Colors.purple.shade400,
    ];
    for (final sector in data.sectors) {
      final isSelected =
          data.selected?.$1 == sector.ring && data.selected?.$2 == sector.index;
      final strokeExtra = isSelected ? 3.0 * data.explodeProgress : 0.0;
      final shadow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = sector.strokeWidth + strokeExtra + 4
        ..color = Colors.black.withValues(
          alpha: isSelected ? 0.28 : 0.15,
        );
      canvas.drawArc(
        Rect.fromCircle(center: sector.center, radius: sector.radius),
        sector.start,
        sector.sweep,
        false,
        shadow,
      );
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = sector.strokeWidth + strokeExtra
        ..color = colors[(sector.ring + sector.index) % colors.length];
      canvas.drawArc(
        Rect.fromCircle(center: sector.center, radius: sector.radius),
        sector.start,
        sector.sweep,
        false,
        paint,
      );
    }

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '/\n10.0 GB',
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 100);

    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _BaobabPainter oldDelegate) =>
      oldDelegate.data.selected != data.selected ||
      oldDelegate.data.size != data.size ||
      oldDelegate.data.explodeProgress != data.explodeProgress;
}
