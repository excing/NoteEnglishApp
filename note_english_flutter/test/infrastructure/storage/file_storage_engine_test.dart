import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_english_flutter/infrastructure/storage/file_storage_engine.dart';

void main() {
  late Directory tempDir;
  late FileStorageEngine storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('note_english_storage_test_');
    storage = FileStorageEngine(customDirectory: tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('FileStorageEngine Tests (TDD)', () {
    test('should return null when reading non-existent key', () async {
      final value = await storage.readString('non_existent.json');
      expect(value, isNull);
    });

    test('should write and read string atomically', () async {
      const content = '{"hello":"world"}';
      await storage.writeString('data.json', content);

      final readValue = await storage.readString('data.json');
      expect(readValue, content);
    });

    test('should overwrite existing content safely', () async {
      await storage.writeString('test.json', 'first');
      await storage.writeString('test.json', 'second');

      final readValue = await storage.readString('test.json');
      expect(readValue, 'second');
    });

    test('should delete existing file', () async {
      await storage.writeString('to_delete.json', 'val');
      await storage.delete('to_delete.json');

      final readValue = await storage.readString('to_delete.json');
      expect(readValue, isNull);
    });
  });
}
