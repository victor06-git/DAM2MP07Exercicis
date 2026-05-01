import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_data.dart';
import 'canvas_painter.dart';
import 'drawable.dart';

class Layout extends StatefulWidget {
  const Layout({super.key, required this.title});

  final String title;

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  String _colorToName(Color color) {
    // simple reverse mapping for known colors
    if (color == Colors.red) return 'red';
    if (color == Colors.blue) return 'blue';
    if (color == Colors.green) return 'green';
    if (color == Colors.yellow) return 'yellow';
    if (color == Colors.black) return 'black';
    if (color == Colors.white) return 'white';
    if (color == Colors.orange) return 'orange';
    if (color == Colors.purple) return 'purple';
    if (color == Colors.pink) return 'pink';
    if (color == Colors.brown) return 'brown';
    if (color == Colors.grey) return 'grey';
    // fallback to hex
    return '#${color.value.toRadixString(16).padLeft(8, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final ScrollController scrollController = ScrollController();
    final ScrollController propertiesController = ScrollController();
    final TextEditingController textController = TextEditingController();

    final random = Random();
    final placeholders = [
      'Dibuixa una línia 10, 50 i 100, 25 ...',
      'Dibuixa dues linies i dos cercles',
      'Dibuixa un cercle amb centre a 150, 200 i radi 50 ...',
      'Fes un rectangle entre x=10, y=20 i x=100, y=200 ...',
      'Dibuixa un cercle a la posició 50,100 de radi 34.66',
    ];

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(widget.title)),
      child: SafeArea(
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // update canvas size in model
                      appData.canvasWidth = constraints.maxWidth;
                      appData.canvasHeight = constraints.maxHeight;
                      return GestureDetector(
                        onTapDown: (details) {
                          appData.selectShapeAtPosition(details.localPosition);
                        },
                        child: Container(
                          color: CupertinoColors.systemGrey5,
                          child: CustomPaint(
                            painter: CanvasPainter(
                              drawables: appData.drawables,
                              selectedIndex: appData.selectedShapeIndex,
                            ),
                            child: Container(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: CupertinoScrollbar(
                            controller: scrollController,
                            child: ListView.builder(
                              controller: scrollController,
                              itemCount: appData.messages.length,
                              itemBuilder: (context, index) {
                                final message = appData.messages[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                    horizontal: 8.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: message.isUser
                                        ? MainAxisAlignment.end
                                        : MainAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.all(12.0),
                                          decoration: BoxDecoration(
                                            color: message.isUser
                                                ? CupertinoColors.activeBlue
                                                : CupertinoColors.systemGrey5,
                                            borderRadius: BorderRadius.circular(
                                              12.0,
                                            ),
                                          ),
                                          child: Text(
                                            message.content,
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color: message.isUser
                                                  ? CupertinoColors.white
                                                  : CupertinoColors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: appData.selectedShape != null ? 150 : 0,
                        child: appData.selectedShape != null
                            ? _buildPropertiesPanel(
                                appData,
                                propertiesController,
                              )
                            : null,
                      ),
                      SizedBox(
                        height: 100,
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CupertinoTextField(
                            maxLines: 5,
                            controller: textController,
                            placeholder:
                                placeholders[random.nextInt(
                                  placeholders.length,
                                )],
                            enabled:
                                !appData.isLoading, // Desactiva si carregant
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: CupertinoButton.filled(
                                onPressed: appData.isLoading
                                    ? null
                                    : () {
                                        final userPrompt = textController.text;
                                        if (userPrompt.isNotEmpty) {
                                          appData.callWithCustomTools(
                                            userPrompt: userPrompt,
                                          );
                                          textController.clear();
                                        }
                                      },
                                child: const Text('Query'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CupertinoButton(
                                onPressed: appData.isLoading
                                    ? () => appData.cancelRequests()
                                    : null,
                                child: const Text('Cancel'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (appData.isLoading)
              Positioned.fill(
                child: Container(
                  color: CupertinoColors.systemGrey.withOpacity(0.5),
                  child: const Center(
                    child: CupertinoActivityIndicator(radius: 20),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertiesPanel(
    AppData appData,
    ScrollController propertiesController,
  ) {
    return Container(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Properties',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => appData.deleteSelectedShape(),
                  child: const Text(
                    'Delete',
                    style: TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: CupertinoScrollbar(
              controller: propertiesController,
              child: SingleChildScrollView(
                controller: propertiesController,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildShapeProperties(appData),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShapeProperties(AppData appData) {
    final shape = appData.selectedShape;
    final index = appData.selectedShapeIndex;

    if (shape == null || index == null) {
      return const SizedBox.shrink();
    }

    final properties = <String, dynamic>{};

    if (shape is Circle) {
      properties['x'] = shape.center.dx.toStringAsFixed(1);
      properties['y'] = shape.center.dy.toStringAsFixed(1);
      properties['radius'] = shape.radius.toStringAsFixed(1);
      properties['color'] = _colorToName(shape.color ?? Colors.black);
      properties['strokeWidth'] = shape.strokeWidth.toStringAsFixed(1);
    } else if (shape is Rectangle) {
      properties['topLeftX'] = shape.topLeft.dx.toStringAsFixed(1);
      properties['topLeftY'] = shape.topLeft.dy.toStringAsFixed(1);
      properties['bottomRightX'] = shape.bottomRight.dx.toStringAsFixed(1);
      properties['bottomRightY'] = shape.bottomRight.dy.toStringAsFixed(1);
      properties['color'] = _colorToName(shape.color ?? Colors.black);
      properties['strokeWidth'] = shape.strokeWidth.toStringAsFixed(1);
    } else if (shape is Line) {
      properties['startX'] = shape.start.dx.toStringAsFixed(1);
      properties['startY'] = shape.start.dy.toStringAsFixed(1);
      properties['endX'] = shape.end.dx.toStringAsFixed(1);
      properties['endY'] = shape.end.dy.toStringAsFixed(1);
      properties['color'] = _colorToName(shape.color);
      properties['strokeWidth'] = shape.strokeWidth.toStringAsFixed(1);
    } else if (shape is TextElement) {
      properties['x'] = shape.position.dx.toStringAsFixed(1);
      properties['y'] = shape.position.dy.toStringAsFixed(1);
      properties['fontSize'] = shape.fontSize.toStringAsFixed(1);
      properties['color'] = _colorToName(shape.color);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: properties.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  entry.key,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: CupertinoTextField(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  placeholder: entry.value.toString(),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      appData.updateShapeProperty(index, entry.key, value);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
