import 'package:cinetrekker_android/shared/widgets/startup_config_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StartupConfigGate shows missing config message without env', (
    tester,
  ) async {
    await tester.pumpWidget(
      const StartupConfigGate(
        child: SizedBox.shrink(),
      ),
    );

    expect(find.text('CineTrekker is not configured yet'), findsOneWidget);
    expect(find.textContaining('CINETREKKER_SUPABASE_URL'), findsWidgets);
  });
}
