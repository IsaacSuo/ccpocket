import 'package:ccpocket/features/claude_session/widgets/rewind_action_sheet.dart';
import 'package:ccpocket/features/codex_session/widgets/codex_rewind_dialog.dart';
import 'package:ccpocket/features/codex_session/codex_session_screen.dart';
import 'package:ccpocket/l10n/app_localizations.dart';
import 'package:ccpocket/models/messages.dart';
import 'package:ccpocket/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('rewind action sheet can be limited to conversation mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: RewindActionSheet(
            userMessage: UserChatEntry(
              'first codex turn',
              messageUuid: 'codex:user-turn:1',
            ),
            availableModes: const [RewindMode.conversation],
            showPreview: false,
            onRewind: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Restore conversation only'), findsOneWidget);
    expect(find.text('Restore code only'), findsNothing);
    expect(find.text('Restore conversation & code'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('file'), findsNothing);
  });

  testWidgets('codex rewind uses a confirmation dialog', (tester) async {
    var confirmed = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: CodexRewindDialog(
            messageText: 'first codex turn',
            onConfirm: () {
              confirmed = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Rewind conversation?'), findsOneWidget);
    expect(find.text('first codex turn'), findsOneWidget);
    expect(find.text('Restore conversation only'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('codex_rewind_confirm_button')));
    expect(confirmed, isTrue);
  });

  group('CodexRewindCoordinator', () {
    test('restores the message only after a successful matching result', () {
      final coordinator = CodexRewindCoordinator();
      addTearDown(coordinator.dispose);

      expect(coordinator.begin('retry this prompt'), isTrue);
      expect(coordinator.isPending, isTrue);
      expect(
        coordinator.complete(
          const RewindResultMessage(
            success: true,
            mode: 'conversation',
            sessionId: 'other-session',
          ),
          sessionId: 'current-session',
        ),
        isNull,
      );
      expect(coordinator.isPending, isTrue);

      expect(
        coordinator.complete(
          const RewindResultMessage(
            success: true,
            mode: 'conversation',
            sessionId: 'current-session',
          ),
          sessionId: 'current-session',
        ),
        'retry this prompt',
      );
      expect(coordinator.isPending, isTrue);
    });

    test('a failed result unlocks the current conversation', () {
      final coordinator = CodexRewindCoordinator();
      addTearDown(coordinator.dispose);

      coordinator.begin('retry this prompt');
      expect(
        coordinator.complete(
          const RewindResultMessage(
            success: false,
            mode: 'conversation',
            sessionId: 'current-session',
            error: 'Cannot rewind while Codex is running',
          ),
          sessionId: 'current-session',
        ),
        isNull,
      );
      expect(coordinator.isPending, isFalse);
    });

    test('accepts a result from an older Bridge without a session id', () {
      final coordinator = CodexRewindCoordinator();
      addTearDown(coordinator.dispose);

      coordinator.begin('retry this prompt');
      expect(
        coordinator.complete(
          const RewindResultMessage(success: true, mode: 'conversation'),
          sessionId: 'current-session',
        ),
        'retry this prompt',
      );
    });
  });
}
