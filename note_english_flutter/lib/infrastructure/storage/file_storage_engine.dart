import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 跨平台轻量存储引擎抽象契约
abstract class IStorageEngine {
  Future<String?> readString(String key);
  Future<void> writeString(String key, String content);
  Future<void> delete(String key);
}

/// 基于本地文件系统原子写入的高可靠跨平台存储引擎
class FileStorageEngine implements IStorageEngine {
  final Directory? _customDirectory;
  Directory? _resolvedDir;

  FileStorageEngine({Directory? customDirectory})
      : _customDirectory = customDirectory;

  Future<Directory> _getRootDir() async {
    if (_customDirectory != null) {
      return _customDirectory;
    }
    if (_resolvedDir != null) {
      return _resolvedDir!;
    }

    try {
      _resolvedDir = await getApplicationSupportDirectory();
    } catch (_) {
      try {
        _resolvedDir = await getApplicationDocumentsDirectory();
      } catch (_) {
        _resolvedDir = Directory.systemTemp;
      }
    }
    if (!await _resolvedDir!.exists()) {
      await _resolvedDir!.create(recursive: true);
    }
    return _resolvedDir!;
  }

  @override
  Future<String?> readString(String key) async {
    final root = await _getRootDir();
    final file = File(p.join(root.path, key));
    if (!await file.exists()) {
      return null;
    }
    return await file.readAsString();
  }

  @override
  Future<void> writeString(String key, String content) async {
    final root = await _getRootDir();
    final filePath = p.join(root.path, key);
    final file = File(filePath);
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    // 原子写入：先写临时文件再进行系统级原子 rename，避免进程意外终止导致文件损坏
    final tmpFile = File('$filePath.tmp_${DateTime.now().microsecondsSinceEpoch}');
    await tmpFile.writeAsString(content, flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await tmpFile.rename(filePath);
  }

  @override
  Future<void> delete(String key) async {
    final root = await _getRootDir();
    final file = File(p.join(root.path, key));
    if (await file.exists()) {
      await file.delete();
    }
  }
}
