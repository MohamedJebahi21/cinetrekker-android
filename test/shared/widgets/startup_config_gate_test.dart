import 'package:cinetrekker_android/shared/widgets/startup_config_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StartupConfigGate', () {
    testWidgets('renders child directly when configured', (tester) async {
      await tester.pumpWidget(
        const StartupConfigGate(
          isConfiguredOverride: true,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Text('App Main Content'),
          ),
        ),
      );

      expect(find.text('App Main Content'), findsOneWidget);
      expect(find.text('CineTrekker is not configured yet'), findsNothing);
    });

    testWidgets('shows missing config message when unconfigured', (tester) async {
      await tester.pumpWidget(
        const StartupConfigGate(
          isConfiguredOverride: false,
          missingKeysOverride: ['CINETREKKER_SUPABASE_URL'],
          child: SizedBox.shrink(),
        ),
      );

      expect(find.text('CineTrekker is not configured yet'), findsOneWidget);
      expect(find.textContaining('CINETREKKER_SUPABASE_URL'), findsWidgets);
    });
  });
}
