import 'package:flutter/material.dart';

class ConnectionButtons extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onSave;
  final VoidCallback onConnect;

  const ConnectionButtons({
    super.key,
    required this.onDelete,
    required this.onSave,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildSquareBtn(Icons.delete_outline, onDelete),
        const SizedBox(width: 15),
        _buildWhiteBtn("Guardar Configuració", onSave),
        const Spacer(),
        _buildGradientBtn("Connectar", onConnect),
      ],
    );
  }

  Widget _buildSquareBtn(IconData icon, VoidCallback onTap) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade400),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 2)),
      ],
    ),
    child: IconButton(onPressed: onTap, icon: Icon(icon)),
  );

  Widget _buildWhiteBtn(String text, VoidCallback onTap) => Container(
    decoration: BoxDecoration(
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 2)),
      ],
    ),
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        side: BorderSide(color: Colors.grey.shade400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      child: Text(text),
    ),
  );

  Widget _buildGradientBtn(String text, VoidCallback onTap) => Container(
    width: 200,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      gradient: const LinearGradient(
        colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.withOpacity(0.3),
          blurRadius: 4,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    ),
  );
}
