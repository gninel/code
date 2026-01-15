import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:voice_autobiography_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('verify app startup', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify that the app has started by finding a known widget or text
      // Note: Adjust the finder based on actual initial UI
      // Assuming 'Voice Autobiography' or similar text is present on splash or home
      expect(find.text('口述'),
          findsWidgets); // Should find AppBar title and BottomNav label
    });
  });
}
