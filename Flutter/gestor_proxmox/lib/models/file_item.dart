class FileItem {
  String name;
  final bool isDirectory;
  final bool isImage;
  String permissions;

  FileItem({
    required this.name,
    required this.isDirectory,
    required this.isImage,
    required this.permissions,
  });
}
