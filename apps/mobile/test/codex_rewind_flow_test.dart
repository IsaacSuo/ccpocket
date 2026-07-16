import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ccpocket/models/messages.dart';

import 'chat_screen/helpers/chat_test_helpers.dart';

const _sessionId = 'codex-before-rewind';
const _targetText = 'rewrite this request';
const _existingDraft = 'keep my current draft';

Future<void> _startRewind(WidgetTester tester, MockBridgeService bridge) async {
  bridge.emitMessage(
    const UserInputMessage(
      text: _targetText,
      userMessageUuid: 'codex:user-turn:1',
    ),
    sessionId: _sessionId,
  );
  bridge.emitMessage(
    const StatusMessage(status: ProcessStatus.idle),
    sessionId: _sessionId,
  );
  await tester.pump();

  await tester.enterText(
    find.byKey(const ValueKey('message_input')),
    _existingDraft,
  );
  await tester.tap(find.byKey(const ValueKey('session_overflow_menu')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('menu_message_history')));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Rewind to here'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('codex_rewind_confirm_button')));
  await tester.pump();
}

String _inputText(WidgetTester tester) {
  return tester
      .widget<TextField>(find.byKey(const ValueKey('message_input')))
      .controller!
      .text;
}

void main() {
  late MockBridgeService bridge;

  setUp(() {
    bridge = MockBridgeService();
  });

  tearDown(() {
    bridge.dispose();
  });

  testWidgets(
    'keeps the draft unchanged and shows an error when rewind fails',
    (tester) async {
      await tester.pumpWidget(
        await buildTestCodexSessionScreen(
          bridge: bridge,
          sessionId: _sessionId,
        ),
      );
      await tester.pump();

      await _startRewind(tester, bridge);

      expect(_inputText(tester), _existingDraft);
      expect(find.text('Rewinding conversation...'), findsOneWidget);
      var sent = bridge.sentMessages
          .map(
            (message) => jsonDecode(message.toJson()) as Map<String, dynamic>,
          )
          .toList();
      final rewind = sent.singleWhere((message) => message['type'] == 'rewind');
      expect(rewind['sessionId'], _sessionId);
      expect(rewind['targetUuid'], 'codex:user-turn:1');

      await tester.tap(find.byKey(const ValueKey('send_button')));
      await tester.pump();
      sent = bridge.sentMessages
          .map(
            (message) => jsonDecode(message.toJson()) as Map<String, dynamic>,
          )
          .toList();
      expect(sent.where((message) => message['type'] == 'input'), isEmpty);

      bridge.emitMessage(
        const RewindResultMessage(
          success: false,
          mode: 'conversation',
          sessionId: _sessionId,
          error: 'Cannot rewind while Codex is running',
        ),
        sessionId: _sessionId,
      );
      await tester.pump();

      expect(_inputText(tester), _existingDraft);
      expect(find.text('Rewinding conversation...'), findsNothing);
      expect(
        find.text(
          'Could not rewind the conversation: '
          'Cannot rewind while Codex is running',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('restores the target only after success and switches session', (
    tester,
  ) async {
    await tester.pumpWidget(
      await buildTestCodexSessionScreen(bridge: bridge, sessionId: _sessionId),
    );
    await tester.pump();

    await _startRewind(tester, bridge);
    expect(_inputText(tester), _existingDraft);

    bridge.emitMessage(
      const RewindResultMessage(
        success: true,
        mode: 'conversation',
        sessionId: _sessionId,
      ),
      sessionId: _sessionId,
    );
    await tester.pump();

    expect(_inputText(tester), _targetText);
    expect(find.text('Rewinding conversation...'), findsOneWidget);

    bridge.emitMessage(
      const SystemMessage(
        subtype: 'session_created',
        sessionId: 'codex-after-rewind',
        sourceSessionId: _sessionId,
        provider: 'codex',
      ),
      sessionId: 'codex-after-rewind',
    );
    await tester.pump();
    await tester.pump();

    expect(_inputText(tester), _targetText);
    expect(find.text('Rewinding conversation...'), findsNothing);
  });
}
