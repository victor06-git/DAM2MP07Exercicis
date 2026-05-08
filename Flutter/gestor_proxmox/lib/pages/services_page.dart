import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/system_service.dart';
import '../services/ssh_service.dart';
import '../state/app_state.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({
    super.key,
    required this.appState,
    required this.sshService,
  });

  final AppStateController appState;
  final SSHService sshService;

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  late Future<List<SystemService>> _services;
  final Set<String> _expandedServices = {};

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  void _loadServices() {
    _services = widget.sshService
        .executeCommandOutput(
          'systemctl list-units --all --no-pager --type=service --output=json',
        )
        .then((output) {
          try {
            // Parse JSON output from systemctl
            final json = jsonDecode(output);
            final services = <SystemService>[];
            if (json is List) {
              for (final item in json) {
                if (item is Map) {
                  services.add(
                    SystemService.fromJson(item as Map<String, dynamic>),
                  );
                }
              }
            }
            return services;
          } catch (e) {
            // Fallback to simple parsing
            final services = <SystemService>[];
            for (final line in output.split('\n')) {
              if (line.trim().isNotEmpty && !line.contains('UNIT')) {
                services.add(SystemService.fromString(line));
              }
            }
            return services;
          }
        });
  }

  Future<void> _toggleService(SystemService service, bool start) async {
    final command = start ? 'systemctl start' : 'systemctl stop';
    try {
      await widget.sshService.executeCommand('$command ${service.name}');
      setState(() {
        _loadServices();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${service.name} ${start ? 'started' : 'stopped'} successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _restartService(SystemService service) async {
    try {
      await widget.sshService.executeCommand(
        'systemctl restart ${service.name}',
      );
      setState(() {
        _loadServices();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${service.name} restarted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadServices();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<SystemService>>(
        future: _services,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadServices();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final services = snapshot.data ?? [];
          final activeServices = services.where((s) => s.isActive).toList();
          final inactiveServices = services.where((s) => !s.isActive).toList();

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            activeServices.length.toString(),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const Text('Active'),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            inactiveServices.length.toString(),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const Text('Inactive'),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                if (activeServices.isNotEmpty) ...[
                  ExpansionTile(
                    title: const Text('Active Services'),
                    initiallyExpanded: true,
                    children: [
                      ...activeServices.map(
                        (service) => _buildServiceTile(service),
                      ),
                    ],
                  ),
                ],
                if (inactiveServices.isNotEmpty) ...[
                  ExpansionTile(
                    title: const Text('Inactive Services'),
                    children: [
                      ...inactiveServices.map(
                        (service) => _buildServiceTile(service),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceTile(SystemService service) {
    final isExpanded = _expandedServices.contains(service.name);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        child: InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedServices.remove(service.name);
              } else {
                _expandedServices.add(service.name);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service.displayName,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: service.isActive
                            ? Colors.green[300]
                            : Colors.grey[600],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        service.state,
                        style: TextStyle(
                          color: service.isActive ? Colors.black : Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  Divider(color: Theme.of(context).dividerColor),
                  const SizedBox(height: 8),
                  Text(
                    'State: ${service.state} (${service.subState})',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Enabled: ${service.enabled ? 'Yes' : 'No'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (service.isActive)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop'),
                          onPressed: () => _toggleService(service, false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start'),
                          onPressed: () => _toggleService(service, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Restart'),
                        onPressed: () => _restartService(service),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
