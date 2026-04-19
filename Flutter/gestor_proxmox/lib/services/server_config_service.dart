import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../core/app_logger.dart';
import '../models/server_info.dart';

class ServerConfigService {
  Future<List<ServerInfo>> loadServers() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/servers.json');
      if (!await file.exists()) {
        final fallback = {
          'servers': [
            {
              'id': 1,
              'name': 'Victor',
              'host': 'ieticloudpro.ieti.cat',
              'port': 20127,
              'username': 'vasensiobermudez',
              'key': 'id_rsa',
            },
          ],
        };
        await file.writeAsString(jsonEncode(fallback));
      }

      final response = await file.readAsString();
      final data = jsonDecode(response);
      final loaded = <ServerInfo>[];
      for (final serverJson in data['servers']) {
        loaded.add(ServerInfo.fromJson(serverJson));
      }
      logger.i('Loaded ${loaded.length} server(s)');
      return loaded;
    } catch (e) {
      logger.e('loadServers error: $e');
      return [];
    }
  }

  Future<void> saveServers(List<ServerInfo> serverList) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/servers.json');
      final jsonString = jsonEncode({
        'servers': serverList.map((s) => s.toJson()).toList(),
      });
      await file.writeAsString(jsonString);
      logger.i('Server file saved in: ${file.path}');
    } catch (e) {
      logger.e('Error saving servers: $e');
    }
  }
}

final serverConfigService = ServerConfigService();
