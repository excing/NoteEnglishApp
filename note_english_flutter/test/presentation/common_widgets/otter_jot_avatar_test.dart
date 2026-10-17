import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_english_flutter/presentation/common_widgets/otter_jot_avatar.dart';

void main() {
  group('OtterJotAvatar', () {
    testWidgets('renders correctly with default and custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                OtterJotAvatar(),
                OtterJotAvatar(size: 48),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(OtterJotAvatar), findsNWidgets(2));
      final firstAvatarFinder = find.byType(OtterJotAvatar).first;
      final size = tester.getSize(firstAvatarFinder);
      expect(size.width, 34.0);
      expect(size.height, 34.0);

      final secondAvatarFinder = find.byType(OtterJotAvatar).last;
      final secondSize = tester.getSize(secondAvatarFinder);
      expect(secondSize.width, 48.0);
      expect(secondSize.height, 48.0);
    });
  });
}
