import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/app_logger.dart';
import '../models/system_service.dart';

class ProxmoxService {
  final String host;
  final int port;
  final String username;
  final String realm;
  String? _ticket;
  String? _csrfToken;

  ProxmoxService({
    required this.host,
    this.port = 8006,
    required this.username,
    this.realm = 'pam',
  });

  Future<bool> authenticate(String password) async {
    try {
      logger.i('Authenticating to Proxmox API at $host:$port');
      final client = _getHttpClient();

      final url = Uri.https(host, '/api2/json/access/ticket', {
        'port': port.toString(),
      });
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': '$username@$realm', 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _ticket = data['data']['ticket'];
        _csrfToken = data['data']['CSRFPreventionToken'];
        logger.i('Successfully authenticated to Proxmox');
        return true;
      } else {
        logger.e(
          'Authentication failed: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      logger.e('Authentication error: $e');
      return false;
    }
  }

  Future<String?> getNodeStatus(String nodeName) async {
    try {
      final data = await _get('/nodes/$nodeName/status');
      if (data != null) {
        return jsonEncode(data);
      }
      return null;
    } catch (e) {
      logger.e('Error getting node status: $e');
      return null;
    }
  }

  Future<List<SystemService>> getNodeServices(String nodeName) async {
    try {
      final output = await executeNodeCommand(
        nodeName,
        'systemctl list-units --all --no-pager',
      );
      final services = <SystemService>[];

      // Parse systemctl output
      final lines = output.split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty || line.contains('UNIT')) continue;
        final service = SystemService.fromString(line);
        if (service.name != 'unknown') {
          services.add(service);
        }
      }

      logger.i('Loaded ${services.length} services from $nodeName');
      return services;
    } catch (e) {
      logger.e('Error getting services: $e');
      return [];
    }
  }

  Future<bool> startService(String nodeName, String serviceName) async {
    try {
      await executeNodeCommand(nodeName, 'systemctl start $serviceName');
      logger.i('Started service: $serviceName');
      return true;
    } catch (e) {
      logger.e('Error starting service: $e');
      return false;
    }
  }

  Future<bool> stopService(String nodeName, String serviceName) async {
    try {
      await executeNodeCommand(nodeName, 'systemctl stop $serviceName');
      logger.i('Stopped service: $serviceName');
      return true;
    } catch (e) {
      logger.e('Error stopping service: $e');
      return false;
    }
  }

  Future<bool> restartService(String nodeName, String serviceName) async {
    try {
      await executeNodeCommand(nodeName, 'systemctl restart $serviceName');
      logger.i('Restarted service: $serviceName');
      return true;
    } catch (e) {
      logger.e('Error restarting service: $e');
      return false;
    }
  }

  Future<String> executeNodeCommand(String nodeName, String command) async {
    try {
      if (_ticket == null) {
        throw Exception('Not authenticated to Proxmox');
      }

      final client = _getHttpClient();

      // Use exec endpoint if available
      final execUrl = Uri.https(host, '/api2/json/nodes/$nodeName/exec', {
        'port': port.toString(),
      });

      final response = await client.post(
        execUrl,
        headers: _getHeaders(),
        body: jsonEncode({'command': command}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['output'] ?? data['data'].toString();
      } else {
        // Fallback: try to get the output from error
        return response.body;
      }
    } catch (e) {
      logger.e('Error executing command on node: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _get(String endpoint) async {
    try {
      if (_ticket == null) {
        throw Exception('Not authenticated to Proxmox');
      }

      final client = _getHttpClient();
      final url = Uri.https(host, '/api2/json$endpoint', {
        'port': port.toString(),
      });

      final response = await client.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else if (response.statusCode == 401) {
        _ticket = null;
        _csrfToken = null;
        throw Exception('Authentication expired');
      } else {
        logger.e('API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      logger.e('Error in GET request: $e');
      return null;
    }
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Cookie': 'PVEAuthCookie=$_ticket',
      'CSRFPreventionToken': _csrfToken ?? '',
    };
  }

  http.Client _getHttpClient() {
    return http.Client();
  }

  bool get isAuthenticated => _ticket != null && _csrfToken != null;
}
