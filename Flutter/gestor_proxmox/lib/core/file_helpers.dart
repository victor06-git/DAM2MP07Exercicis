import 'package:path/path.dart' as p;

String formatPermissions(int? mode) {
  if (mode == null) return '---------';
  final bits = mode & 0x1FF;
  String res = '';
  final chars = ['r', 'w', 'x'];
  for (int i = 0; i < 9; i++) {
    if ((bits >> (8 - i)) & 1 == 1) {
      res += chars[i % 3];
    } else {
      res += '-';
    }
  }
  return res;
}

bool isImageFile(String fileName) {
  final imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'];
  final extension = p.extension(fileName).toLowerCase();
  return imageExtensions.contains(extension);
}
