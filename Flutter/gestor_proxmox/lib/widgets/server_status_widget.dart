import 'package:flutter/material.dart';

enum ServerState { running, stopped, restarting, error }

class ServerStatusWidget extends StatelessWidget {
  final ServerState state;
  const ServerStatusWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String label;
    switch (state) {
      case ServerState.running:
        icon = Icons.play_arrow;
        color = Colors.green;
        label = 'Running';
        break;
      case ServerState.stopped:
        icon = Icons.stop;
        color = Colors.red;
        label = 'Stopped';
        break;
      case ServerState.restarting:
        icon = Icons.refresh;
        color = Colors.orange;
        label = 'Restarting';
        break;
      default:
        icon = Icons.error_outline;
        color = Colors.purple;
        label = 'Error';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
