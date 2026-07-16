import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ccpocket/models/messages.dart';
import 'package:ccpocket/theme/app_theme.dart';
import 'package:ccpocket/widgets/bubbles/result_chip.dart';

Widget _wrap(ResultMessage message) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(body: ResultChip(message: message)),
  );
}

void main() {
  group('ResultChip status labels', () {
    testWidgets('renders an interrupted turn as a neutral status', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const ResultMessage(subtype: 'interrupted')),
      );

      expect(find.text('Interrupted'), findsOneWidget);
      expect(find.textContaining('Error'), findsNothing);
      expect(find.textContaining('unknown'), findsNothing);
    });

    testWidgets('renders an error with its details', (tester) async {
      await tester.pumpWidget(
        _wrap(const ResultMessage(subtype: 'error', error: 'Network failed')),
      );

      expect(find.text('Error: Network failed'), findsOneWidget);
    });

    testWidgets('does not invent details for an error without a message', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const ResultMessage(subtype: 'error')));

      expect(find.text('Error'), findsOneWidget);
      expect(find.textContaining('unknown'), findsNothing);
    });

    testWidgets('renders an unknown subtype as a neutral status', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const ResultMessage(subtype: 'future_status')),
      );

      expect(find.text('Future Status'), findsOneWidget);
      expect(find.textContaining('Error'), findsNothing);
    });
  });
}
