import 'package:flutter/material.dart';

import '../models/disk_usage.dart';
import '../services/ssh_service.dart';

class DiskUsageSystemPage extends StatefulWidget {
  const DiskUsageSystemPage({super.key, required this.sshService});

  final SSHService sshService;

  @override
  State<DiskUsageSystemPage> createState() => _DiskUsageSystemPageState();
}

class _DiskUsageSystemPageState extends State<DiskUsageSystemPage> {
  late Future<List<DiskUsage>> _diskUsage;

  @override
  void initState() {
    super.initState();
    _loadDiskUsage();
  }

  void _loadDiskUsage() {
    _diskUsage = widget.sshService
        .executeCommandOutput('df -B1')
        .then((output) {
          final disks = <DiskUsage>[];
          final lines = output.split('\n');

          // Skip header line
          for (int i = 1; i < lines.length; i++) {
            final line = lines[i].trim();
            if (line.isEmpty) continue;

            try {
              final disk = DiskUsage.fromDfOutput(line);
              if (disk.filesystem != 'unknown') {
                disks.add(disk);
              }
            } catch (e) {
              // Skip invalid lines
            }
          }

          return disks;
        })
        .catchError((_) {
          // Fallback: try with -BK format
          return widget.sshService.executeCommandOutput('df -BK').then((
            output,
          ) {
            final disks = <DiskUsage>[];
            final lines = output.split('\n');

            for (int i = 1; i < lines.length; i++) {
              final line = lines[i].trim();
              if (line.isEmpty) continue;

              try {
                final disk = DiskUsage.fromDfOutput(line);
                if (disk.filesystem != 'unknown') {
                  disks.add(disk);
                }
              } catch (e) {
                // Skip invalid lines
              }
            }

            return disks;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disk Usage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadDiskUsage();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<DiskUsage>>(
        future: _diskUsage,
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
                        _loadDiskUsage();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final disks = snapshot.data ?? [];

          if (disks.isEmpty) {
            return const Center(child: Text('No disk data available'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: disks.length,
            itemBuilder: (context, index) {
              final disk = disks[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    disk.filesystem,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    disk.mountPoint,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
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
                                color: disk.percentUsed > 80
                                    ? Colors.red[300]
                                    : disk.percentUsed > 60
                                    ? Colors.orange[300]
                                    : Colors.green[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${disk.percentUsed}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: disk.percentUsed / 100,
                            minHeight: 8,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              disk.percentUsed > 80
                                  ? Colors.red
                                  : disk.percentUsed > 60
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  disk.totalSizeFormatted,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Used',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  disk.usedSizeFormatted,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Available',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  disk.availableSizeFormatted,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
