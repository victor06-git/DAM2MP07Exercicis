import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'crypto_service.dart';

// Formulari reutilitzable per encriptar i desencriptar arxius.
// El comportament canvia segons el paràmetre isEncrypting:
//   true  → mostra camps per clau pública + arxiu a xifrar
//   false → mostra camps per clau privada + arxiu xifrat + destinació
class EncryptionForm extends StatefulWidget {
  final bool isEncrypting;
  const EncryptionForm({super.key, required this.isEncrypting});

  @override
  State<EncryptionForm> createState() => _EncryptionFormState();
}

class _EncryptionFormState extends State<EncryptionForm> {
  String? _keyPath; // ruta de la clau (pública o privada)
  String? _filePath; // ruta de l'arxiu a processar
  String? _destinationPath; // ruta de destí (només per desencriptar)
  bool _isProcessing = false; // true mentre s'executa l'operació
  double _progressValue = 0.0; // valor de la barra de progress (0.0 - 1.0)

  @override
  void initState() {
    super.initState();
    // Per defecte, en mode desencriptar, usa la clau SSH privada de l'usuari
    if (!widget.isEncrypting) {
      String homeDir = Platform.environment['HOME'] ?? '';
      _keyPath = '$homeDir/private_key.pem';
    }
  }

  // Obre el selector de fitxers i guarda la ruta segons el tipus:
  //   'key'  → clau RSA
  //   'file' → arxiu a processar
  //   'dest' → arxiu de destinació
  Future<void> _pickFile(String type) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        setState(() {
          if (type == 'key') {
            _keyPath = result.files.single.path;
          } else if (type == 'file') {
            _filePath = result.files.single.path;
          } else if (type == 'dest') {
            _destinationPath = result.files.single.path;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Error al seleccionar arxiu: $e');
      }
    }
  }

  // Obre el selector de directoris i construeix la ruta completa
  // afegint el nom de fitxer per defecte (sense extensió .enc)
  Future<void> _pickDirectory() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        String fileName = _getDefaultFileName();
        String fullPath = '$selectedDirectory/$fileName';
        setState(() {
          _destinationPath = fullPath;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Error al seleccionar directori: $e');
      }
    }
  }

  // Genera el nom de fitxer per defecte per a l'arxiu desxifrat:
  // si l'arxiu acaba en .enc, elimina l'extensió; sinó afegeix _desxifrat
  String _getDefaultFileName() {
    if (_filePath == null) return 'archivo_desxifrat';
    String originalName = _filePath!.split('/').last;
    if (originalName.endsWith('.enc')) {
      return originalName.replaceAll('.enc', '');
    }
    return '${originalName}_desxifrat';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título descriptivo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isEncrypting
                    ? Colors.blue.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isEncrypting
                      ? Colors.blue.shade200
                      : Colors.green.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isEncrypting ? Icons.lock : Icons.lock_open,
                    size: 32,
                    color: widget.isEncrypting ? Colors.blue : Colors.green,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isEncrypting
                              ? 'Encriptar Arxiu'
                              : 'Desencriptar Arxiu',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isEncrypting
                              ? 'Encripta el teu arxiu amb clau pública RSA'
                              : 'Desencripta el teu arxiu amb clau privada RSA',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Selector de Clave
            _buildFileSelector(
              label: widget.isEncrypting
                  ? 'Clau pública (RSA):'
                  : 'Clau privada (RSA):',
              currentPath: _keyPath,
              onPressed: () => _pickFile('key'),
              icon: Icons.vpn_key,
            ),

            const SizedBox(height: 20),

            // Selector de Archivo
            _buildFileSelector(
              label: widget.isEncrypting
                  ? 'Arxiu a encriptar:'
                  : 'Arxiu xifrat:',
              currentPath: _filePath,
              onPressed: () => _pickFile('file'),
              icon: Icons.file_present,
            ),

            // Campo extra solo para desencriptar
            if (!widget.isEncrypting) ...[
              const SizedBox(height: 20),
              _buildFileSelector(
                label: 'Arxiu desxifrat (Destí):',
                currentPath: _destinationPath,
                onPressed: _pickDirectory,
                icon: Icons.save,
                isDirectory: true,
              ),
            ],

            const SizedBox(height: 30),

            // Mostrar progreso si está procesando
            if (_isProcessing) ...[
              Column(
                children: [
                  LinearProgressIndicator(value: _progressValue, minHeight: 8),
                  const SizedBox(height: 12),
                  Text(
                    'Processant... ${(_progressValue * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ],

            // Botón de Acción
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_canProcess() && !_isProcessing)
                    ? _handleAction
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isEncrypting
                      ? Colors.blue
                      : Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        widget.isEncrypting
                            ? 'Encripta Arxiu'
                            : 'Desencripta Arxiu',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Comprova si tots els camps obligatoris estan omplerts per habilitar el botó
  bool _canProcess() {
    if (widget.isEncrypting) {
      return _keyPath != null &&
          _keyPath!.isNotEmpty &&
          _filePath != null &&
          _filePath!.isNotEmpty;
    } else {
      return _keyPath != null &&
          _keyPath!.isNotEmpty &&
          _filePath != null &&
          _filePath!.isNotEmpty &&
          _destinationPath != null &&
          _destinationPath!.isNotEmpty;
    }
  }

  // Executa l'acció principal: crida encryptFile o decryptFile segons el mode
  void _handleAction() async {
    if (!_canProcess()) {
      _showError('Si us plau, completa tots els camps');
      return;
    }

    setState(() {
      _isProcessing = true;
      _progressValue = 0.0;
    });

    try {
      if (widget.isEncrypting) {
        await CryptoService.encryptFile(_filePath!, _keyPath!);
        _showSuccess(
          'Arxiu encriptat correctament',
          'Arxiu guardat com: $_filePath.enc',
        );
      } else {
        await CryptoService.decryptFile(
          _filePath!,
          _keyPath!,
          _destinationPath!,
        );
        _showSuccess(
          'Arxiu desencriptat correctament',
          'Arxiu guardat a: $_destinationPath',
        );
      }
    } catch (e) {
      _showError('Error en el procés: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _progressValue = 0.0;
        });
      }
    }
  }

  // Mostra un SnackBar vermell amb el missatge d'error
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Mostra un diàleg verd de confirmació amb la ruta de l'arxiu resultant
  void _showSuccess(String title, String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(
            Icons.check_circle,
            color: Colors.green.shade600,
            size: 48,
          ),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('D\'acord'),
            ),
          ],
        ),
      );
    }
  }

  // Widget reutilitzable per seleccionar fitxers o directoris.
  // Mostra la ruta seleccionada (truncada si és massa llarga) i un botó "Navega..."
  // Canvia de color (gris → verd) quan hi ha un fitxer seleccionat.
  Widget _buildFileSelector({
    required String label,
    String? currentPath,
    required VoidCallback onPressed,
    required IconData icon,
    bool isDirectory = false,
  }) {
    String displayPath = currentPath ?? 'Cap arxiu seleccionat';
    if (currentPath != null && currentPath.length > 50) {
      displayPath = '...${currentPath.substring(currentPath.length - 47)}';
    }

    bool isSelected = currentPath != null && currentPath.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.green.shade300 : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? Colors.green.shade50 : Colors.grey.shade50,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: isSelected ? Colors.green : Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayPath,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.black87 : Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onPressed,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Navega...'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
