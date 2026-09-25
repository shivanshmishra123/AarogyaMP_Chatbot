// AarogyaMP — basic smoke test (M0 placeholder)
// Real tests will be added per screen in M1+

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aarogyamp/main.dart';

void main() {
  testWidgets('App smoke test — renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AarogyaMPApp()),
    );
    // Let splash screen timer complete and settle onto login
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    // Verify app rendered successfully
    expect(find.byType(AarogyaMPApp), findsOneWidget);
  });
}
