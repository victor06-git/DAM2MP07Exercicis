import 'package:flutter/foundation.dart';

import '../models/file_item.dart';
import '../models/server_info.dart';

class AppStateController extends ChangeNotifier {
  final List<ServerInfo> servers = [];
  final List<FileItem> currentFiles = [];

  String currentPath = '/';
  bool isConnected = false;

  void setServers(List<ServerInfo> items) {
    servers
      ..clear()
      ..addAll(items);
    notifyListeners();
  }

  void upsertServer(ServerInfo server) {
    final index = servers.indexWhere((s) => s.id == server.id);
    if (index == -1) {
      servers.add(server);
    } else {
      servers[index] = server;
    }
    notifyListeners();
  }

  void setCurrentPath(String path) {
    currentPath = path;
    notifyListeners();
  }

  void setCurrentFiles(List<FileItem> files) {
    currentFiles
      ..clear()
      ..addAll(files);
    notifyListeners();
  }

  void setConnected(bool connected) {
    isConnected = connected;
    notifyListeners();
  }
}
