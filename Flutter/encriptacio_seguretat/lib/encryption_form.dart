import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'crypto_service.dart';

class EncryptionForm extends StatefulWidget {
  final bool isEncrypting;
  const EncryptionForm({super.key, required this.isEncrypting});

  @override
  State<EncryptionForm> createState() => _EncryptionFormState();
}

class _EncryptionFormState extends State<EncryptionForm> {
  String? _keyPath;
  String? _filePath;
  String? _destinationPath;

  @override
  void initState() {
    super.initState();
    // Valor por defecto para desencriptar
    if (!widget.isEncrypting) {
      _keyPath = "~/.ssh/id_rsa";
    }
  }

  Future<void> _pickFile(String type) async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isEncrypting ? 'Encriptar Arxiu' : 'Desencriptar Arxiu',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Selector de Clave
          _buildFileSelector(
            label: widget.isEncrypting
                ? 'Clau pública (RSA):'
                : 'Clau privada (RSA):',
            currentPath: _keyPath,
            onPressed: () => _pickFile('key'),
          ),

          const SizedBox(height: 15),

          // Selector de Archivo
          _buildFileSelector(
            label: widget.isEncrypting ? 'Arxiu a encriptar:' : 'Arxiu xifrat:',
            currentPath: _filePath,
            onPressed: () => _pickFile('file'),
          ),

          // Campo extra solo para desencriptar
          if (!widget.isEncrypting) ...[
            const SizedBox(height: 15),
            _buildFileSelector(
              label: 'Arxiu desxifrat (Destí):',
              currentPath: _destinationPath,
              onPressed: () => _pickFile('dest'),
            ),
          ],

          const Spacer(),

          // Botón de Acción
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canProcess() ? _handleAction : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isEncrypting
                    ? Colors.blue
                    : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                widget.isEncrypting ? 'Encripta Arxiu' : 'Desencripta Arxiu',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Validación lógica
  bool _canProcess() {
    if (widget.isEncrypting) {
      return _keyPath != null && _filePath != null;
    } else {
      return _keyPath != null && _filePath != null && _destinationPath != null;
    }
  }

  // Ejecución de la lógica
  void _handleAction() async {
    try {
      if (widget.isEncrypting) {
        await CryptoService.encryptFile(_filePath!, _keyPath!);
      } else {
        await CryptoService.decryptFile(
          _filePath!,
          _keyPath!,
          _destinationPath!,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEncrypting ? "Arxiu encriptat!" : "Arxiu desxifrat!",
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildFileSelector({
    required String label,
    String? currentPath,
    required VoidCallback onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currentPath ?? "Cap arxiu seleccionat",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: currentPath == null ? Colors.grey : Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: onPressed,
              child: const Text("Navega..."),
            ),
          ],
        ),
      ],
    );
  }
}
