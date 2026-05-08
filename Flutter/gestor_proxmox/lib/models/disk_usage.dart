class DiskUsage {
  final String filesystem;
  final String mountPoint;
  final int totalSize; // in KB
  final int usedSize; // in KB
  final int availableSize; // in KB
  final int percentUsed;

  DiskUsage({
    required this.filesystem,
    required this.mountPoint,
    required this.totalSize,
    required this.usedSize,
    required this.availableSize,
    required this.percentUsed,
  });

  factory DiskUsage.fromDfOutput(String line) {
    // Parse output from: df -B1 or df -BK
    // Format: Filesystem 1K-blocks Used Available Use% Mounted on
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length >= 6) {
      final total = int.tryParse(parts[1]) ?? 0;
      final used = int.tryParse(parts[2]) ?? 0;
      final available = int.tryParse(parts[3]) ?? 0;
      final percent = int.tryParse(parts[4].replaceAll('%', '')) ?? 0;

      return DiskUsage(
        filesystem: parts[0],
        mountPoint: parts.length > 6 ? parts.sublist(5).join(' ') : parts[5],
        totalSize: total,
        usedSize: used,
        availableSize: available,
        percentUsed: percent,
      );
    }
    return DiskUsage(
      filesystem: 'unknown',
      mountPoint: 'unknown',
      totalSize: 0,
      usedSize: 0,
      availableSize: 0,
      percentUsed: 0,
    );
  }

  String get totalSizeFormatted => _formatBytes(totalSize * 1024);
  String get usedSizeFormatted => _formatBytes(usedSize * 1024);
  String get availableSizeFormatted => _formatBytes(availableSize * 1024);

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var size = bytes.toDouble();
    var index = 0;
    while (size >= 1024 && index < suffixes.length - 1) {
      size /= 1024;
      index++;
    }
    return '${size.toStringAsFixed(2)} ${suffixes[index]}';
  }
}
