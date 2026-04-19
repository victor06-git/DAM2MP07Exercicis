class DiskUsageNode {
  DiskUsageNode({
    required this.name,
    required this.path,
    required this.sizeKb,
    this.children = const [],
  });

  final String name;
  final String path;
  final int sizeKb;
  final List<DiskUsageNode> children;
}
