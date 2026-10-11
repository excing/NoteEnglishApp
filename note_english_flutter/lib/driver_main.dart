import 'package:flutter_driver/driver_extension.dart';
import 'package:note_english_flutter/main.dart';

void main() async {
  // 必须最优先调用 enableFlutterDriverExtension
  enableFlutterDriverExtension();
  await startNoteEnglishApp();
}
