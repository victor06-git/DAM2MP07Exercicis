import 'dart:math';
import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
import 'dart:ui' as ui;

class ServerStatsScreen extends StatefulWidget {
  final SSHClient client;
  final String currentPath;
  final List<SftpName> items;

  const ServerStatsScreen({
    super.key,
    required this.client,
    required this.currentPath,
    required this.items,
  });

  @override
  State<ServerStatsScreen> createState() => _ServerStatsScreenState();
}

class _ServerStatsScreenState extends State<ServerStatsScreen> {
  bool isServerActive = true;
  bool isRedirectEnabled = false;
  String serverStatus = "En funcionament";
  Offset? _hoverPosition;
  final TextEditingController _configController = TextEditingController(
    text: "srv-proxmox-01",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F7FA,
      ), // Gris molt clar de fons professional
      appBar: AppBar(
        title: Text(
          widget.currentPath.split('/').last,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // --- SECCIÓ BAOBAB (CARD) ---
            _buildSectionCard(
              title: "DISTRIBUCIÓ DE DISC",
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: GestureDetector(
                      // Afegim onTapDown per capturar el clic instantani
                      onTapDown: (details) {
                        setState(() {
                          _hoverPosition = details.localPosition;
                        });
                      },
                      // OnPanUpdate per si l'usuari arrossega el dit/ratolí
                      onPanUpdate: (details) {
                        setState(() {
                          _hoverPosition = details.localPosition;
                        });
                      },
                      // Quan s'aixeca el dit o surt el ratolí, netegem (opcional)
                      onTapUp: (_) => setState(() => _hoverPosition = null),
                      onPanEnd: (_) => setState(() => _hoverPosition = null),
                      child: SizedBox(
                        width: 260,
                        height: 260,
                        child: CustomPaint(
                          painter: RealBaobabPainter(
                            items: widget.items,
                            hoverPosition: _hoverPosition,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Toca els segments per veure detalls",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            // --- SECCIÓ ESTAT I HOSTNAME ---
            _buildSectionCard(
              title: "CONFIGURACIÓ DEL SISTEMA",
              child: Column(
                children: [
                  _buildStatusHeader(),
                  const Divider(height: 30),
                  _buildEditableConfig(),
                ],
              ),
            ),

            // --- SECCIÓ DEPENDÈNCIES ---
            const CustomIndentList(
              title: "DEPENDÈNCIES DETECTADES",
              subItems: [
                "NodeJS Engine v18.x",
                "Express Framework",
                "PM2 Process Manager",
                "Body-parser Middleware",
              ],
            ),

            // --- SECCIÓ REDIRECCIÓ ---
            _buildSectionCard(
              title: "XARXA I PORTS",
              child: _buildPortRedirector(),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Contenidor estil "Card" per agrupar ginys
  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.blueGrey.shade300,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Row(
      children: [
        CustomPaint(
          size: const Size(14, 14),
          painter: StatusCircleCanvas(isActive: isServerActive),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            serverStatus.toUpperCase(),
            style: TextStyle(
              color: isServerActive
                  ? Colors.green.shade700
                  : Colors.red.shade700,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Icon(
          Icons.check_circle_outline,
          color: Colors.green.shade200,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildEditableConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Identificador de xarxa",
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        TextField(
          controller: _configController,
          style: const TextStyle(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortRedirector() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "HTTP Redirecció (Port 80)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "Apunta el trànsit extern al port 3000",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          activeColor: Colors.blue,
          value: isRedirectEnabled,
          onChanged: (val) => setState(() => isRedirectEnabled = val),
        ),
      ],
    );
  }
}

// --- WIDGETS DE SUPORT AMB MILLORES VISUALS ---

class CustomIndentList extends StatelessWidget {
  final String title;
  final List<String> subItems;
  const CustomIndentList({
    super.key,
    required this.title,
    required this.subItems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.blueGrey.shade300,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...subItems.map(
            (item) => Container(
              margin: const EdgeInsets.only(left: 10, bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.subdirectory_arrow_right,
                    size: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatusCircleCanvas extends CustomPainter {
  final bool isActive;
  StatusCircleCanvas({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Efecte de resplendor (Glow) al voltant del cercle
    final shadowPaint = Paint()
      ..color = (isActive ? Colors.green : Colors.red).withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, size.width / 2 + 2, shadowPaint);

    // El cercle principal
    final paint = Paint()
      ..color = isActive ? Colors.green : Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width / 2, paint);
  }

  @override
  bool shouldRepaint(covariant StatusCircleCanvas oldDelegate) =>
      oldDelegate.isActive != isActive;
}

class RealBaobabPainter extends CustomPainter {
  final List<SftpName> items;
  final Offset? hoverPosition;

  RealBaobabPainter({required this.items, this.hoverPosition});

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width * 0.38;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double totalSize = items.fold(
      0,
      (sum, item) => sum + (item.attr.size ?? 1024),
    );
    double startAngle = -pi / 2; // Les 12 del rellotge
    String? hoveredName;

    final List<Color> palette = [
      const Color(0xFF6C5CE7),
      const Color(0xFF00CEC9),
      const Color(0xFFFAB1A0),
      const Color(0xFF0984E3),
      const Color(0xFFFD79A8),
      const Color(0xFF00B894),
    ];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      double sweepAngle = ((item.attr.size ?? 1024) / totalSize) * 2 * pi;
      if (sweepAngle < 0.12) sweepAngle = 0.12;

      // --- LÒGICA DE DETECCIÓ (Ara sí, al lloc correcte) ---
      bool isHovered = false;
      if (hoverPosition != null) {
        final dist = (hoverPosition! - center).distance;
        if (dist > radius - 30 && dist < radius + 30) {
          double touchAngle = atan2(
            hoverPosition!.dy - center.dy,
            hoverPosition!.dx - center.dx,
          );
          if (touchAngle < -pi / 2) touchAngle += 2 * pi;

          if (touchAngle >= startAngle &&
              touchAngle <= startAngle + sweepAngle) {
            isHovered = true;
            hoveredName = item.filename; // Aquesta variable ara sí que existeix
          }
        }
      }

      paint.color = palette[i % palette.length].withOpacity(
        isHovered ? 1.0 : 0.7,
      );
      paint.strokeWidth = isHovered ? 48 : 38;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + 0.04,
        sweepAngle - 0.04,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }

    _drawCenterText(
      canvas,
      center,
      hoveredName ?? "${(totalSize / 1024).toStringAsFixed(1)} KB",
    );
  }

  void _drawCenterText(Canvas canvas, Offset center, String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF2D3436),
          fontWeight: FontWeight.w900,
          fontSize: 15,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: 100);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant RealBaobabPainter oldDelegate) =>
      oldDelegate.hoverPosition != hoverPosition;
}
