import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/app_logger.dart';
import '../core/file_helpers.dart';
import '../models/disk_usage_node.dart';
import '../models/file_item.dart';
import '../models/operation_result.dart';
import '../state/app_state.dart';

class SSHService {
  SSHService(this.appState);

  final AppStateController appState;
  SSHClient? _client;
  SftpClient? _sftp;

  Future<bool> connect(String username, String ip, int port, String key) async {
    try {
      logger.i('Attempting to connect to $ip:$port');
      final socket = await SSHSocket.connect(ip, port);
      _client = SSHClient(
        socket,
        username: username,
        keepAliveInterval: const Duration(seconds: 30),
        identities: [...SSHKeyPair.fromPem(await getPrivateKey(key))],
      );
      logger.i('Connected to $ip:$port');
      appState.setConnected(true);
      return true;
    } catch (e) {
      logger.e('Connection error: $e');
      return false;
    }
  }

  Future<void> listFiles(String path) async {
    if (_client == null) return;
    try {
      _sftp ??= await _client!.sftp();
      final items = await _sftp!.listdir(path);
      final files = <FileItem>[];
      for (final item in items) {
        files.add(
          FileItem(
            name: item.filename,
            isDirectory: item.attr.isDirectory,
            isImage: isImageFile(item.filename),
            permissions: formatPermissions(item.attr.mode?.value),
          ),
        );
      }
      appState.setCurrentFiles(files);
    } catch (e) {
      logger.e('Error listing files: $e');
      _sftp = null;
    }
  }

  Future<void> downloadPath(String remotePath) async {
    if (_client == null) return;
    try {
      _sftp ??= await _client!.sftp();
      final stat = await _sftp!.stat(remotePath);
      final downloadsDir = await getDownloadsDirectory();
      if (stat.isDirectory) {
        await _downloadFolderAsZip(remotePath, downloadsDir!.path);
      } else {
        await _downloadSingleFile(remotePath, downloadsDir!.path);
      }
    } catch (e) {
      logger.e('Error downloading: $e');
    }
  }

  Future<OperationResult> uploadFile(String localPath, String remotePath) async {
    if (_client == null) {
      return const OperationResult(
        success: false,
        message: 'Not connected to server',
      );
    }

    Future<void> uploadToPath(String targetDirectory) async {
      _sftp ??= await _client!.sftp();
      final localFile = File(localPath);
      final fileName = p.basename(localPath);
      final remoteFilePath = p.posix.join(targetDirectory, fileName);
      final remoteFile = await _sftp!.open(
        remoteFilePath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write,
      );
      final stream = localFile.openRead().map((list) => Uint8List.fromList(list));
      await remoteFile.write(stream);
      logger.i('Uploaded $remoteFilePath');
    }

    try {
      await uploadToPath(remotePath);
      return OperationResult(
        success: true,
        message: 'File uploaded to $remotePath',
      );
    } catch (e) {
      logger.e('Upload error: $e');
      final message = e.toString();
      if (!message.contains('Permission denied')) {
        _sftp = null;
        return OperationResult(success: false, message: 'Upload failed: $message');
      }

      try {
        await uploadToPath('~');
        return const OperationResult(
          success: true,
          message:
              'No write permission in selected folder. Uploaded to your home directory (~) instead.',
        );
      } catch (fallbackError) {
        return OperationResult(
          success: false,
          message:
              'Permission denied in destination and fallback (~) also failed: $fallbackError',
        );
      }
    }
  }

  Future<OperationResult> uploadDirectoryAsZipAndExtract(
    String localDirPath,
    String remoteTargetPath,
  ) async {
    if (_client == null) {
      return const OperationResult(
        success: false,
        message: 'Not connected to server',
      );
    }
    final sourceDir = Directory(localDirPath);
    if (!sourceDir.existsSync()) {
      return const OperationResult(
        success: false,
        message: 'Local directory does not exist',
      );
    }

    final tempDir = await getTemporaryDirectory();
    final archiveName =
        '${p.basename(localDirPath)}_${DateTime.now().millisecondsSinceEpoch}.zip';
    final localZipPath = p.join(tempDir.path, archiveName);

    try {
      final encoder = ZipFileEncoder();
      encoder.create(localZipPath);
      encoder.addDirectory(sourceDir, includeDirName: true);
      encoder.close();

      final uploadResult = await uploadFile(localZipPath, remoteTargetPath);
      if (!uploadResult.success) {
        return uploadResult;
      }
      await executeCommand(
        'cd "$remoteTargetPath" && unzip -o "$archiveName" && rm "$archiveName"',
      );
      return OperationResult(
        success: true,
        message: 'Directory uploaded and extracted in $remoteTargetPath',
      );
    } catch (e) {
      logger.e('Upload directory error: $e');
      return OperationResult(
        success: false,
        message: 'Directory upload failed: $e',
      );
    } finally {
      final tempZip = File(localZipPath);
      if (await tempZip.exists()) {
        await tempZip.delete();
      }
    }
  }

  Future<void> _downloadSingleFile(String remotePath, String localDir) async {
    final fileName = p.posix.basename(remotePath);
    final localPath = p.join(localDir, fileName);
    final remoteFile = await _sftp!.open(remotePath);
    final localFile = File(localPath);
    final ios = localFile.openWrite();
    await ios.addStream(remoteFile.read());
    await ios.close();
    logger.i('Saved to $localPath');
  }

  Future<void> _downloadFolderAsZip(String remotePath, String localDir) async {
    final folderName = p.posix.basename(remotePath);
    final zipName =
        '${folderName}_${DateTime.now().millisecondsSinceEpoch}.zip';
    final remoteZipPath = '~/$zipName';
    final localZipPath = p.join(localDir, zipName);
    try {
      final parentDir = p.posix.dirname(remotePath);
      await _client!.execute(
        'cd "$parentDir" && zip -r "$remoteZipPath" "$folderName"',
      );
      _sftp ??= await _client!.sftp();
      final remoteFile = await _sftp!.open(remoteZipPath);
      final localFile = File(localZipPath);
      final ios = localFile.openWrite();
      await ios.addStream(remoteFile.read());
      await ios.close();
      final bytes = File(localZipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        final filename = file.name;
        final destPath = p.join(localDir, filename);
        if (file.isFile) {
          final data = file.content as List<int>;
          File(destPath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory(destPath).createSync(recursive: true);
        }
      }
      await _client!.execute('rm "$remoteZipPath"');
      if (await File(localZipPath).exists()) {
        await File(localZipPath).delete();
      }
    } catch (e) {
      logger.e('ZIP process failed: $e');
      rethrow;
    }
  }

  Future<void> deletePath(String path) async {
    if (_client == null) return;
    try {
      _sftp ??= await _client!.sftp();
      final stat = await _sftp!.stat(path);
      if (stat.isDirectory) {
        await executeCommand('rm -rf "$path"');
      } else {
        await _sftp!.remove(path);
      }
      logger.i('Deleted $path');
    } catch (e) {
      logger.e('Delete path error: $e');
      _sftp = null;
    }
  }

  Future<void> renamePath(String oldPath, String newPath) async {
    if (_sftp == null && _client != null) {
      _sftp = await _client!.sftp();
    }
    if (_sftp == null) return;
    try {
      await _sftp!.rename(oldPath, newPath);
      logger.i('Renamed $oldPath -> $newPath');
    } catch (e) {
      logger.e('Rename error: $e');
      _sftp = null;
    }
  }

  Future<void> unzipFile(String zipRemotePath, String destRemotePath) async {
    if (_client == null) return;
    try {
      await executeCommand(
        'unzip -o "$zipRemotePath" -d "$destRemotePath" && rm "$zipRemotePath"',
      );
      logger.i('Unzipped $zipRemotePath to $destRemotePath');
    } catch (e) {
      logger.e('Unzip error: $e');
    }
  }

  Future<String> getPrivateKey(String file) async {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE']!;
    final keyPath = p.join(home, '.ssh', file);
    final keyFile = File(keyPath);
    if (await keyFile.exists()) {
      return await keyFile.readAsString();
    }
    throw Exception('Private key file not found: $keyPath');
  }

  Future<String?> checkServerType(String path) async {
    if (_client == null) return null;
    try {
      _sftp ??= await _client!.sftp();
      final items = await _sftp!.listdir(path);
      for (final item in items) {
        if (item.filename == 'package.json') {
          return 'node';
        }
        if (item.filename == 'pom.xml' ||
            item.filename == 'build.gradle' ||
            item.filename == 'build.gradle.kts') {
          return 'java';
        }
      }
      return null;
    } catch (e) {
      logger.e('Error checking server type: $e');
      return null;
    }
  }

  Future<void> executeCommand(String command) async {
    if (_client == null) return;
    try {
      final session = await _client!.execute(command);
      if (!command.trim().endsWith('&')) {
        final output = utf8.decode(
          await session.stdout.fold(
            <int>[],
            (previous, element) => previous..addAll(element),
          ),
        );
        logger.i('Command executed: $command, output: $output');
      } else {
        logger.i('Background command executed: $command');
      }
    } catch (e) {
      logger.e('Execute error: $e');
    }
  }

  Future<String> executeCommandOutput(String command) async {
    if (_client == null) {
      throw Exception('Not connected to server');
    }
    final session = await _client!.execute(command);
    return utf8.decode(
      await session.stdout.fold(
        <int>[],
        (previous, element) => previous..addAll(element),
      ),
    );
  }

  Future<DiskUsageNode> getDiskUsageTree(String rootPath, {int maxDepth = 2}) async {
    final escaped = rootPath.replaceAll('"', r'\"');
    final output = await executeCommandOutput(
      'du -k -d $maxDepth "$escaped" 2>/dev/null',
    );
    final rows = output
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final sizes = <String, int>{};
    for (final row in rows) {
      final parts = row.split(RegExp(r'\s+'));
      if (parts.length < 2) continue;
      final size = int.tryParse(parts[0]);
      if (size == null) continue;
      final path = parts.sublist(1).join(' ');
      sizes[path] = size;
    }

    if (!sizes.containsKey(rootPath)) {
      sizes[rootPath] = sizes.values.isEmpty ? 0 : sizes.values.reduce((a, b) => a > b ? a : b);
    }

    DiskUsageNode buildNode(String path) {
      final nodeSize = sizes[path] ?? 0;
      final depth = path == rootPath
          ? 0
          : p.posix.relative(path, from: rootPath).split('/').length;
      final children = <DiskUsageNode>[];
      if (depth < maxDepth) {
        for (final candidate in sizes.keys) {
          if (candidate == path || !candidate.startsWith('$path/')) continue;
          final rel = p.posix.relative(candidate, from: path);
          if (!rel.contains('/')) {
            children.add(buildNode(candidate));
          }
        }
        children.sort((a, b) => b.sizeKb.compareTo(a.sizeKb));
      }
      final nodeName = path == rootPath
          ? (rootPath == '/' ? '/' : p.posix.basename(rootPath))
          : p.posix.basename(path);
      return DiskUsageNode(
        name: nodeName,
        path: path,
        sizeKb: nodeSize,
        children: children,
      );
    }

    return buildNode(rootPath);
  }

  Future<bool> isServerRunning(String type, String path) async {
    if (_client == null) return false;
    try {
      final port = type == 'node' ? '3000' : '8080';
      final command = 'ss -tln | grep :$port || netstat -tln | grep :$port';
      final session = await _client!.execute(command);
      final output = utf8.decode(
        await session.stdout.fold(
          <int>[],
          (previous, element) => previous..addAll(element),
        ),
      );
      return output.trim().isNotEmpty;
    } catch (e) {
      logger.e('Error checking server status: $e');
      return false;
    }
  }
}
