import 'package:http/http.dart' as http;
import 'dart:convert';

class OllamaService {
  static const String baseUrl = 'http://localhost:11434';
  static const String model = 'granite2:3b';

  /// Call Ollama with Granite 2:3B model (simple, non-streaming)
  static Future<String> generateText(String prompt) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/generate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': model,
              'prompt': prompt,
              'stream': false,
            }),
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw Exception('Ollama request timeout'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'No response from model';
      } else {
        throw Exception('Ollama error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to Ollama: $e');
    }
  }

  /// Call Ollama with streaming response
  static Future<Stream<String>> generateTextStream(String prompt) async {
    try {
      final request = http.Request('POST', Uri.parse('$baseUrl/api/generate'));

      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'model': model,
        'prompt': prompt,
        'stream': true,
      });

      final streamResponse = await request.send();

      if (streamResponse.statusCode != 200) {
        throw Exception('Ollama error: ${streamResponse.statusCode}');
      }

      return streamResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .map((line) {
            if (line.isEmpty) return '';
            try {
              final data = jsonDecode(line);
              return data['response'] ?? '';
            } catch (e) {
              return '';
            }
          });
    } catch (e) {
      throw Exception('Failed to stream from Ollama: $e');
    }
  }

  /// Check if Ollama is running and model is available
  static Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/tags'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List?;
        return models?.any((m) => m['name'].contains('granite2')) ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
