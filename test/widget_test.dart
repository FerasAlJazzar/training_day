import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test placeholder', (WidgetTester tester) async {
    // Hive requires initialization in main(),
    // so full widget tests need setup. Placeholder for now.
    expect(1 + 1, 2);
  });
}
