import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../helpers/streaming_block_splitter.dart';
import '../../theme/app_spacing.dart';
import '../../theme/code_text_style.dart';
import '../../theme/markdown_style.dart';

class StreamingBubble extends StatefulWidget {
  final String text;
  const StreamingBubble({super.key, required this.text});

  @override
  State<StreamingBubble> createState() => _StreamingBubbleState();
}

class _StreamingBubbleState extends State<StreamingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cursorController;

  // ── Throttle state ────────────────────────────────────────────────────
  /// The text actually rendered by [MarkdownBody].
  /// Throttled independently from [widget.text] which always holds the latest.
  late String _displayedText;

  /// Timestamp of the last render flush.
  DateTime _lastRender = DateTime.now();

  /// Pending flush timer.  When non-null and active, further deltas are
  /// coalesced without triggering additional rebuilds.
  Timer? _throttleTimer;

  static const _throttleDuration = Duration(milliseconds: 50);

  // ── Block-level split state ──────────────────────────────────────────
  final StreamingBlockSplitter _splitter = StreamingBlockSplitter();
  List<String> _cachedClosedBlocks = [];
  String _cachedOpenTail = '';
  static const int _maxClosedBlocks = 50;

  // ── Widget instance cache ────────────────────────────────────────────
  // Returning the SAME MarkdownBody instance from build() lets Flutter's
  // Element.updateChild skip the subtree entirely (framework.dart:4014:
  // child.widget == newWidget via identical).  This is the core perf win —
  // unchanged closed blocks do ZERO markdown re-parsing.
  final List<Widget> _closedWidgets = [];
  List<String> _lastClosedBlockData = [];
  MarkdownStyleSheet? _lastStyleSheet;

  // ── Stylesheet cache ──────────────────────────────────────────────────
  MarkdownStyleSheet? _cachedStyleSheet;
  bool? _cachedIsDark;
  double? _cachedCodeFontSize;
  String? _cachedCodeFontFamily;

  // ── Lifecycle ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _displayedText = widget.text;
    final result = _splitter.split(_displayedText);
    _cachedClosedBlocks = result.closedBlocks;
    _cachedOpenTail = result.openTail;
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant StreamingBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _scheduleThrottledUpdate();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Theme or code-font settings may have changed — invalidate the cache.
    _cachedStyleSheet = null;
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    _cursorController.dispose();
    super.dispose();
  }

  // ── Throttle logic ────────────────────────────────────────────────────

  /// Schedules a throttled re-render.  The first delta in a throttle window
  /// renders immediately (responsive feel); subsequent deltas are deferred
  /// until the window expires.
  ///
  /// [setState] is ***only*** called inside [_flushPendingUpdate], never here.
  /// This guarantees that `_displayedText` (and therefore [MarkdownBody.data])
  /// is stable between flushes, letting Flutter skip the entire subtree.
  void _scheduleThrottledUpdate() {
    final elapsed = DateTime.now().difference(_lastRender);
    _throttleTimer?.cancel();
    if (elapsed >= _throttleDuration) {
      // Enough time has passed — flush immediately on the next event-loop tick.
      _throttleTimer = Timer(Duration.zero, _flushPendingUpdate);
    } else {
      // Still inside the throttle window — defer to the end of the window.
      _throttleTimer = Timer(_throttleDuration - elapsed, _flushPendingUpdate);
    }
  }

  void _flushPendingUpdate() {
    _lastRender = DateTime.now();
    if (!mounted) return;
    if (_displayedText != widget.text) {
      setState(() {
        _displayedText = widget.text;
        final result = _splitter.split(_displayedText);
        if (result.closedBlocks.length > _maxClosedBlocks) {
          // Too many blocks — fall back to single render to avoid
          // widget-tree ballooning in pathological cases.
          _cachedClosedBlocks = const [];
          _cachedOpenTail = _displayedText;
        } else {
          _cachedClosedBlocks = result.closedBlocks;
          _cachedOpenTail = result.openTail;
        }
      });
    }
  }

  // ── Stylesheet cache ──────────────────────────────────────────────────

  /// Returns a cached [MarkdownStyleSheet], rebuilding only when theme
  /// brightness or code-font settings have changed.
  MarkdownStyleSheet _getStyleSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final codeSettings = codeTextSettingsOf(context);

    if (_cachedStyleSheet != null &&
        _cachedIsDark == isDark &&
        _cachedCodeFontSize == codeSettings.fontSize &&
        _cachedCodeFontFamily == codeSettings.family.fontFamily) {
      return _cachedStyleSheet!;
    }

    _cachedStyleSheet = buildMarkdownStyle(context);
    _cachedIsDark = isDark;
    _cachedCodeFontSize = codeSettings.fontSize;
    _cachedCodeFontFamily = codeSettings.family.fontFamily;
    return _cachedStyleSheet!;
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_displayedText.isEmpty) return const SizedBox.shrink();

    final styleSheet = _getStyleSheet(context);

    // If the stylesheet changed (theme toggle), invalidate ALL cached
    // widgets so they are rebuilt with the new theme.
    if (_lastStyleSheet != styleSheet) {
      _closedWidgets.clear();
      _lastClosedBlockData.clear();
      _lastStyleSheet = styleSheet;
    }

    // Build closed block widgets, reusing cached instances when the
    // block data has not changed.  Returning the SAME MarkdownBody
    // instance triggers Flutter's identical() fast path in
    // Element.updateChild — zero re-parsing for stable blocks.
    final List<Widget> closedWidgets = [];
    for (var i = 0; i < _cachedClosedBlocks.length; i++) {
      final data = _cachedClosedBlocks[i];
      if (i < _closedWidgets.length && data == _lastClosedBlockData[i]) {
        closedWidgets.add(_closedWidgets[i]);
      } else {
        final w = MarkdownBody(
          key: ValueKey('closed-$i'),
          data: data,
          styleSheet: styleSheet,
          onTapLink: handleMarkdownLink,
          inlineSyntaxes: markdownInlineSyntaxes,
          blockSyntaxes: markdownBlockSyntaxes,
          builders: markdownBuilders,
        );
        if (i < _closedWidgets.length) {
          _closedWidgets[i] = w;
        } else {
          _closedWidgets.add(w);
        }
        closedWidgets.add(w);
      }
    }
    // Trim excess cached widgets when blocks shrink.
    if (_closedWidgets.length > _cachedClosedBlocks.length) {
      _closedWidgets.removeRange(
        _cachedClosedBlocks.length,
        _closedWidgets.length,
      );
    }
    _lastClosedBlockData = List<String>.from(_cachedClosedBlocks);

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.bubbleMarginV,
        horizontal: AppSpacing.bubbleMarginH,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...closedWidgets,
          // Open tail: the currently-being-written portion.
          // Tiny — re-parsing per delta is negligible.
          if (_cachedOpenTail.isNotEmpty)
            MarkdownBody(
              data: _cachedOpenTail,
              styleSheet: styleSheet,
              onTapLink: handleMarkdownLink,
              inlineSyntaxes: markdownInlineSyntaxes,
              blockSyntaxes: markdownBlockSyntaxes,
              builders: markdownBuilders,
            ),
          FadeTransition(
            opacity: _cursorController,
            child: const Text('▍', style: TextStyle(fontSize: 16, height: 1)),
          ),
        ],
      ),
    );
  }
}
