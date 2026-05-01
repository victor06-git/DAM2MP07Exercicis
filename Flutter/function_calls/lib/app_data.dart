import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'constants.dart';
import 'drawable.dart';
import 'ollama_service.dart';

const streamingModel = 'granite4:3b';
const functionCallingModel = 'granite4:3b';
const jsonFixModel = 'granite4:3b';

// Classe per representar un missatge del xat
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}

// Funcionamiento de pasar el tamaño del canvas, cambiar el color, el radio, etc.

class AppData extends ChangeNotifier {
  String _responseText = "";
  bool _isLoading = false;
  bool _isInitial = true;
  http.Client? _client;
  IOClient? _ioClient;
  HttpClient? _httpClient;
  StreamSubscription<String>? _streamSubscription;
  int? _selectedShapeIndex;

  double canvasWidth = 0;
  double canvasHeight = 0;

  final List<Drawable> drawables = [];
  final List<ChatMessage> chatHistory = [];

  String get responseText =>
      _isInitial ? "..." : (_isLoading ? "Esperant ..." : _responseText);

  bool get isLoading => _isLoading;
  List<ChatMessage> get messages => chatHistory;
  int? get selectedShapeIndex => _selectedShapeIndex;
  Drawable? get selectedShape =>
      _selectedShapeIndex != null && _selectedShapeIndex! < drawables.length
      ? drawables[_selectedShapeIndex!]
      : null;

  AppData() {
    _httpClient = HttpClient();
    _ioClient = IOClient(_httpClient!);
    _client = _ioClient;
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void addDrawable(Drawable drawable) {
    drawables.add(drawable);
    notifyListeners();
  }

  // Cuando se selecciona una forma se guarda el índice
  // el dibujo de la selección se maneja en CanvasPainter llamando a drawSelected
  void selectShape(int index) {
    if (index >= 0 && index < drawables.length) {
      _selectedShapeIndex = index;
    }
    notifyListeners();
  }

  void deselectShape() {
    _selectedShapeIndex = null;
    notifyListeners();
  }

  void deleteSelectedShape() {
    if (_selectedShapeIndex != null &&
        _selectedShapeIndex! < drawables.length) {
      drawables.removeAt(_selectedShapeIndex!);
      _selectedShapeIndex = null;
      notifyListeners();
    }
  }

  void updateShapeProperty(int index, String property, dynamic value) {
    if (index >= 0 && index < drawables.length) {
      final shape = drawables[index];

      if (shape is Circle) {
        switch (property) {
          case 'x':
            drawables[index] = Circle(
              center: Offset(parseDouble(value), shape.center.dy),
              radius: shape.radius,
              color: shape.color,
              strokeWidth: shape.strokeWidth,
              gradientColors: shape.gradientColors,
            );
            break;
          case 'y':
            drawables[index] = Circle(
              center: Offset(shape.center.dx, parseDouble(value)),
              radius: shape.radius,
              color: shape.color,
              strokeWidth: shape.strokeWidth,
              gradientColors: shape.gradientColors,
            );
            break;
          case 'radius':
            drawables[index] = Circle(
              center: shape.center,
              radius: parseDouble(value),
              color: shape.color,
              strokeWidth: shape.strokeWidth,
              gradientColors: shape.gradientColors,
            );
            break;
          case 'color':
            drawables[index] = Circle(
              center: shape.center,
              radius: shape.radius,
              color: parseColor(value),
              strokeWidth: shape.strokeWidth,
              gradientColors: shape.gradientColors,
            );
            break;
          case 'strokeWidth':
            drawables[index] = Circle(
              center: shape.center,
              radius: shape.radius,
              color: shape.color,
              strokeWidth: parseDouble(value),
              gradientColors: shape.gradientColors,
            );
            break;
        }
      } else if (shape is Rectangle) {
        switch (property) {
          case 'topLeftX':
            drawables[index] = Rectangle(
              topLeft: Offset(parseDouble(value), shape.topLeft.dy),
              bottomRight: shape.bottomRight,
              color: shape.color,
              strokeWidth: shape.strokeWidth,
              gradientColors: shape.gradientColors,
            );
            break;
          case 'topLeftY':
            drawables[index] = Rectangle(
              topLeft: Offset(shape.topLeft.dx, parseDouble(value)),
              bottomRight: shape.bottomRight,
              color: shape.color,
              strokeWidth: shape.strokeWidth,
              gradientColors: shape.gradientColors,
            );
            break;
          case 'bottomRightX':
            drawables[index] = Rectangle(
              topLeft: shape.topLeft,
              bottomRight: Offset(parseDouble(value), shape.bottomRight.dy),
              color: shape.color,
              strokeWidth: shape.strokeWidth,
              gradientColors: shape.gradientColors,
            );
            break;
          case 'bottomRightY':
            drawables[index] = Rectangle(
              topLeft: shape.topLeft,
              bottomRight: Offset(shape.bottomRight.dx, parseDouble(value)),
              color: shape.color,
              strokeWidth: shape.strokeWidth,
              gradientColors: shape.gradientColors,
            );
            break;
          case 'color':
            drawables[index] = Rectangle(
              topLeft: shape.topLeft,
              bottomRight: shape.bottomRight,
              color: parseColor(value),
              strokeWidth: shape.strokeWidth,
              gradientColors: shape.gradientColors,
            );
            break;
          case 'strokeWidth':
            drawables[index] = Rectangle(
              topLeft: shape.topLeft,
              bottomRight: shape.bottomRight,
              color: shape.color,
              strokeWidth: parseDouble(value),
              gradientColors: shape.gradientColors,
            );
            break;
        }
      } else if (shape is Line) {
        switch (property) {
          case 'startX':
            drawables[index] = Line(
              start: Offset(parseDouble(value), shape.start.dy),
              end: shape.end,
              color: shape.color,
              strokeWidth: shape.strokeWidth,
            );
            break;
          case 'startY':
            drawables[index] = Line(
              start: Offset(shape.start.dx, parseDouble(value)),
              end: shape.end,
              color: shape.color,
              strokeWidth: shape.strokeWidth,
            );
            break;
          case 'endX':
            drawables[index] = Line(
              start: shape.start,
              end: Offset(parseDouble(value), shape.end.dy),
              color: shape.color,
              strokeWidth: shape.strokeWidth,
            );
            break;
          case 'endY':
            drawables[index] = Line(
              start: shape.start,
              end: Offset(shape.end.dx, parseDouble(value)),
              color: shape.color,
              strokeWidth: shape.strokeWidth,
            );
            break;
          case 'color':
            drawables[index] = Line(
              start: shape.start,
              end: shape.end,
              color: parseColor(value),
              strokeWidth: shape.strokeWidth,
            );
            break;
          case 'strokeWidth':
            drawables[index] = Line(
              start: shape.start,
              end: shape.end,
              color: shape.color,
              strokeWidth: parseDouble(value),
            );
            break;
        }
      } else if (shape is TextElement) {
        switch (property) {
          case 'x':
            drawables[index] = TextElement(
              text: shape.text,
              position: Offset(parseDouble(value), shape.position.dy),
              color: shape.color,
              fontSize: shape.fontSize,
              fontWeight: shape.fontWeight,
              fontStyle: shape.fontStyle,
            );
            break;
          case 'y':
            drawables[index] = TextElement(
              text: shape.text,
              position: Offset(shape.position.dx, parseDouble(value)),
              color: shape.color,
              fontSize: shape.fontSize,
              fontWeight: shape.fontWeight,
              fontStyle: shape.fontStyle,
            );
            break;
          case 'color':
            drawables[index] = TextElement(
              text: shape.text,
              position: shape.position,
              color: parseColor(value),
              fontSize: shape.fontSize,
              fontWeight: shape.fontWeight,
              fontStyle: shape.fontStyle,
            );
            break;
          case 'fontSize':
            drawables[index] = TextElement(
              text: shape.text,
              position: shape.position,
              color: shape.color,
              fontSize: parseDouble(value),
              fontWeight: shape.fontWeight,
              fontStyle: shape.fontStyle,
            );
            break;
        }
      }
      notifyListeners();
    }
  }

  bool isPointInShape(Offset point, Drawable shape) {
    if (shape is Circle) {
      final distance = (point - shape.center).distance;
      return distance <= shape.radius;
    } else if (shape is Rectangle) {
      final rect = Rect.fromPoints(shape.topLeft, shape.bottomRight);
      return rect.contains(point);
    } else if (shape is Line) {
      const threshold = 10.0;
      final dist = _distancePointToLine(point, shape.start, shape.end);
      return dist <= threshold;
    } else if (shape is TextElement) {
      const hitBoxSize = 20.0;
      final dx = (point.dx - shape.position.dx).abs();
      final dy = (point.dy - shape.position.dy).abs();
      return dx <= hitBoxSize && dy <= hitBoxSize;
    }
    return false;
  }

  double _distancePointToLine(Offset point, Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    if (dx == 0 && dy == 0) {
      return (point - start).distance;
    }
    final t =
        ((point.dx - start.dx) * dx + (point.dy - start.dy) * dy) /
        (dx * dx + dy * dy);
    final t_clamped = t.clamp(0.0, 1.0);
    final closest = Offset(
      start.dx + t_clamped * dx,
      start.dy + t_clamped * dy,
    );
    return (point - closest).distance;
  }

  void selectShapeAtPosition(Offset position) {
    for (int i = drawables.length - 1; i >= 0; i--) {
      if (isPointInShape(position, drawables[i])) {
        selectShape(i);
        return;
      }
    }
    deselectShape();
  }

  Future<void> callStream({required String question}) async {
    _isInitial = false;
    setLoading(true);

    try {
      var request = http.Request(
        'POST',
        Uri.parse('http://localhost:11434/api/generate'),
      );

      request.headers.addAll({'Content-Type': 'application/json'});
      request.body = jsonEncode({
        'model': streamingModel,
        'prompt': question,
        'stream': true,
      });

      var streamedResponse = await _client!.send(request);
      _streamSubscription = streamedResponse.stream
          .transform(utf8.decoder)
          .listen(
            (value) {
              var jsonResponse = jsonDecode(value);
              var jsonResponseStr = jsonResponse['response'];
              _responseText = "$_responseText\n$jsonResponseStr";
              notifyListeners();
            },
            onError: (error) {
              if (error is http.ClientException &&
                  error.message == 'Connection closed while receiving data') {
                _responseText += "\nRequest cancelled.";
              } else {
                _responseText += "\nError during streaming: $error";
              }
              setLoading(false);
              notifyListeners();
            },
            onDone: () {
              setLoading(false);
            },
          );
    } catch (e) {
      _responseText = "\nError during streaming.";
      setLoading(false);
      notifyListeners();
    }
  }

  Future<dynamic> fixJsonInStrings(dynamic data) async {
    if (data is Map<String, dynamic>) {
      final result = <String, dynamic>{};
      for (final entry in data.entries) {
        result[entry.key] = await fixJsonInStrings(entry.value);
      }
      return result;
    } else if (data is List) {
      return Future.wait(data.map((value) => fixJsonInStrings(value)));
    } else if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) {
        return data;
      }

      try {
        // Si és JSON dins d'una cadena, el deserialitzem
        final parsed = jsonDecode(data);
        return fixJsonInStrings(parsed);
      } catch (_) {
        if (_looksLikeJsonCandidate(trimmed)) {
          final repairedJson = await _repairJsonWithAi(trimmed);
          if (repairedJson != null) {
            return fixJsonInStrings(repairedJson);
          }
        }

        // Si no és JSON o no es pot reparar, retornem la cadena tal qual
        return data;
      }
    }
    // Retorna qualsevol altre tipus sense canvis (números, booleans, etc.)
    return data;
  }

  bool _looksLikeJsonCandidate(String value) {
    return value.startsWith('{') ||
        value.startsWith('[') ||
        ((value.contains('{') || value.contains('[')) && value.contains(':'));
  }

  Future<dynamic> _repairJsonWithAi(String rawJson) async {
    const apiUrl = 'http://localhost:11434/api/chat';
    final body = {
      "model": jsonFixModel,
      "stream": false,
      "format": "json",
      "messages": [
        {
          "role": "system",
          "content":
              "You repair malformed JSON. Return only valid JSON that preserves the original intent and values as closely as possible.",
        },
        {
          "role": "user",
          "content":
              "Repair this malformed JSON and return only the fixed JSON:\n$rawJson",
        },
      ],
    };

    try {
      final response = await _client!.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final jsonResponse = jsonDecode(response.body);
      final content = jsonResponse['message']?['content'];
      if (content is! String || content.trim().isEmpty) {
        return null;
      }

      return jsonDecode(content);
    } catch (_) {
      return null;
    }
  }

  dynamic cleanKeys(dynamic value) {
    if (value is Map<String, dynamic>) {
      final result = <String, dynamic>{};
      value.forEach((k, v) {
        result[k.trim()] = cleanKeys(v);
      });
      return result;
    }
    if (value is List) {
      return value.map(cleanKeys).toList();
    }
    return value;
  }

  Future<void> callWithCustomTools({required String userPrompt}) async {
    const apiUrl = 'http://localhost:11434/api/chat';
    _isInitial = false;

    // Afegir el missatge del usuari al xat
    chatHistory.add(
      ChatMessage(content: userPrompt, isUser: true, timestamp: DateTime.now()),
    );

    setLoading(true);

    // include canvas size info in system message
    final sizeInfo =
        "Canvas size: width=${canvasWidth.toStringAsFixed(1)}, height=${canvasHeight.toStringAsFixed(1)}.";

    final body = {
      "model": functionCallingModel,
      "stream": false,
      "messages": [
        {"role": "system", "content": sizeInfo},
        {"role": "user", "content": userPrompt},
      ],
      "tools": tools,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        String aiResponse = "";

        if (jsonResponse['message'] != null &&
            jsonResponse['message']['tool_calls'] != null) {
          final toolCalls = (jsonResponse['message']['tool_calls'] as List)
              .map((e) => cleanKeys(e))
              .toList();
          aiResponse = "Executant funcions: ";
          for (final tc in toolCalls) {
            if (tc['function'] != null) {
              aiResponse += "${tc['function']['name']}, ";
              await _processFunctionCall(tc['function']);
            }
          }
        } else if (jsonResponse['message'] != null &&
            jsonResponse['message']['content'] != null) {
          aiResponse = jsonResponse['message']['content'];
        }

        // Afegir la resposta de la IA al xat
        if (aiResponse.isNotEmpty) {
          chatHistory.add(
            ChatMessage(
              content: aiResponse,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        }

        setLoading(false);
      } else {
        setLoading(false);
        throw Exception("Error: ${response.body}");
      }
    } catch (e) {
      print("Error during API call: $e");
      chatHistory.add(
        ChatMessage(
          content: "Error: $e",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      setLoading(false);
    }
    notifyListeners();
  }

  void cancelRequests() {
    _streamSubscription?.cancel();
    _httpClient?.close(force: true);
    _httpClient = HttpClient();
    _ioClient = IOClient(_httpClient!);
    _client = _ioClient;
    _responseText += "\nRequest cancelled.";
    setLoading(false);
    notifyListeners();
  }

  double parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Color parseColor(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'red':
          return Colors.red;
        case 'blue':
          return Colors.blue;
        case 'green':
          return Colors.green;
        case 'yellow':
          return Colors.yellow;
        case 'black':
          return Colors.black;
        case 'white':
          return Colors.white;
        case 'orange':
          return Colors.orange;
        case 'purple':
          return Colors.purple;
        case 'pink':
          return Colors.pink;
        case 'brown':
          return Colors.brown;
        case 'grey':
        case 'gray':
          return Colors.grey;
        default:
          return Colors.black;
      }
    }
    return Colors.black;
  }

  List<Color> parseGradientColors(dynamic value) {
    if (value is List) {
      return value.map((color) => parseColor(color)).toList();
    }
    return [];
  }

  FontWeight parseFontWeight(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'bold':
        case 'w700':
          return FontWeight.bold;
        case 'w600':
        case 'semibold':
          return FontWeight.w600;
        case 'w500':
        case 'medium':
          return FontWeight.w500;
        case 'w400':
        case 'normal':
        case 'regular':
          return FontWeight.normal;
        case 'w300':
        case 'light':
          return FontWeight.w300;
        case 'w200':
          return FontWeight.w200;
        case 'w100':
        case 'thin':
          return FontWeight.w100;
        case 'w800':
          return FontWeight.w800;
        case 'w900':
          return FontWeight.w900;
        default:
          return FontWeight.normal;
      }
    }
    return FontWeight.normal;
  }

  FontStyle parseFontStyle(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'italic':
          return FontStyle.italic;
        case 'normal':
          return FontStyle.normal;
        default:
          return FontStyle.normal;
      }
    }
    return FontStyle.normal;
  }

  double _randomBetween(double min, double max) {
    return min + Random().nextDouble() * (max - min);
  }

  Future<void> _processFunctionCall(Map<String, dynamic> functionCall) async {
    final fixedJson = await fixJsonInStrings(functionCall);
    final parametersData = fixedJson['arguments'];
    final parameters = parametersData is Map<String, dynamic>
        ? parametersData
        : <String, dynamic>{};

    String name = fixedJson['name'];
    String infoText = "Draw $name: $parameters";

    print(infoText);
    _responseText = "$_responseText\n$infoText";

    switch (name) {
      case 'draw_circle':
        final dx = parameters['x'] != null
            ? parseDouble(parameters['x'])
            : 50.0;
        final dy = parameters['y'] != null
            ? parseDouble(parameters['y'])
            : 50.0;
        final radius = parameters['radius'] != null
            ? parseDouble(parameters['radius'])
            : 10.0;
        final color = parseColor(parameters['color']);
        final strokeWidth = parameters['strokeWidth'] != null
            ? parseDouble(parameters['strokeWidth'])
            : 2.0;
        final gradientColors = parseGradientColors(
          parameters['gradientColors'],
        );
        addDrawable(
          Circle(
            center: Offset(dx, dy),
            radius: max(0.0, radius),
            color: color,
            strokeWidth: strokeWidth,
            gradientColors: gradientColors.isNotEmpty ? gradientColors : null,
          ),
        );
        break;

      case 'draw_line':
        final startX = parameters['startX'] != null
            ? parseDouble(parameters['startX'])
            : _randomBetween(10.0, 100.0);
        final startY = parameters['startY'] != null
            ? parseDouble(parameters['startY'])
            : _randomBetween(10.0, 100.0);
        final endX = parameters['endX'] != null
            ? parseDouble(parameters['endX'])
            : _randomBetween(10.0, 100.0);
        final endY = parameters['endY'] != null
            ? parseDouble(parameters['endY'])
            : _randomBetween(10.0, 100.0);
        final color = parseColor(parameters['color']);
        final strokeWidth = parameters['strokeWidth'] != null
            ? parseDouble(parameters['strokeWidth'])
            : 1.0;
        final start = Offset(startX, startY);
        final end = Offset(endX, endY);
        addDrawable(
          Line(start: start, end: end, color: color, strokeWidth: strokeWidth),
        );
        break;

      case 'draw_rectangle':
        if (parameters['topLeftX'] != null &&
            parameters['topLeftY'] != null &&
            parameters['bottomRightX'] != null &&
            parameters['bottomRightY'] != null) {
          final topLeftX = parseDouble(parameters['topLeftX']);
          final topLeftY = parseDouble(parameters['topLeftY']);
          final bottomRightX = parseDouble(parameters['bottomRightX']);
          final bottomRightY = parseDouble(parameters['bottomRightY']);
          final color = parseColor(parameters['color']);
          final strokeWidth = parameters['strokeWidth'] != null
              ? parseDouble(parameters['strokeWidth'])
              : 2.0;
          final gradientColors = parseGradientColors(
            parameters['gradientColors'],
          );
          final topLeft = Offset(topLeftX, topLeftY);
          final bottomRight = Offset(bottomRightX, bottomRightY);
          addDrawable(
            Rectangle(
              topLeft: topLeft,
              bottomRight: bottomRight,
              color: color,
              strokeWidth: strokeWidth,
              gradientColors: gradientColors.isNotEmpty ? gradientColors : null,
            ),
          );
        } else {
          print("Missing rectangle properties: $parameters");
        }
        break;

      case 'draw_text':
        if (parameters['x'] != null &&
            parameters['y'] != null &&
            parameters['text'] != null) {
          final x = parseDouble(parameters['x']);
          final y = parseDouble(parameters['y']);
          final text = parameters['text'].toString();
          final color = parseColor(parameters['color']);
          final fontSize = parameters['fontSize'] != null
              ? parseDouble(parameters['fontSize'])
              : 14.0;
          final fontWeight = parseFontWeight(parameters['fontWeight']);
          final fontStyle = parseFontStyle(parameters['fontStyle']);
          addDrawable(
            TextElement(
              position: Offset(x, y),
              text: text,
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle,
            ),
          );
        } else {
          print("Missing text properties: $parameters");
        }
        break;

      default:
        print("Unknown function call: ${fixedJson['name']}");
    }
  }

  /// Call Granite 2:3B via Ollama (simple, non-streaming)
  Future<void> callGraniteSimple({required String userPrompt}) async {
    setLoading(true);
    try {
      _responseText = "";
      notifyListeners();

      final result = await OllamaService.generateText(userPrompt);
      _responseText = result;
      _isInitial = false;
    } catch (e) {
      _responseText = "Error: ${e.toString()}";
      _isInitial = false;
    } finally {
      setLoading(false);
    }
  }

  /// Call Granite 2:3B via Ollama with streaming
  Future<void> callGraniteStreaming({required String userPrompt}) async {
    setLoading(true);
    _responseText = "";
    _isInitial = false;
    notifyListeners();

    try {
      final stream = await OllamaService.generateTextStream(userPrompt);
      await for (final chunk in stream) {
        _responseText += chunk;
        notifyListeners();
      }
    } catch (e) {
      _responseText = "Streaming error: ${e.toString()}";
    } finally {
      setLoading(false);
    }
  }

  /// Check if Ollama with Granite is available
  Future<bool> checkOllamaConnection() async {
    return await OllamaService.checkConnection();
  }
}
