/// Result of [StreamingBlockSplitter.split].
class StreamBlockSplitResult {
  /// Blocks whose text is complete and won't change in future deltas.
  final List<String> closedBlocks;

  /// The currently-being-written tail after the last safe paragraph boundary.
  final String openTail;

  const StreamBlockSplitResult(this.closedBlocks, this.openTail);
}

/// Splits accumulated streaming text into closed (stable) blocks and an
/// open (active) tail.
///
/// Uses **line-by-line scanning** so that blank lines *inside* fenced code
/// blocks (```` ``` ```` / `~~~`) are preserved as block content rather
/// than treated as paragraph boundaries.  Outside fences, blank lines act
/// as separators: they close the preceding block.
///
/// ### Known limitation
///
/// Markdown structures that can span paragraph boundaries — list-item
/// continuations, blockquote multi-paragraph, reference-link definitions —
/// will be split at `\n\n` even though semantically they form a single
/// block.  During streaming this is a minor *temporary* visual glitch;
/// once streaming completes, [AssistantBubble] renders the full markdown
/// correctly.
class StreamingBlockSplitter {
  /// Matches a code-fence opening or closing line.
  ///
  /// Per CommonMark, fences can be indented up to 3 spaces.
  static final RegExp _fenceLine = RegExp(r'^ {0,3}(```|~~~)');

  /// Splits [fullText] into closed blocks and an open tail.
  StreamBlockSplitResult split(String fullText) {
    if (fullText.isEmpty) {
      return const StreamBlockSplitResult([], '');
    }

    final lines = fullText.split('\n');
    final blocks = <StringBuffer>[];
    final closedFlags = <bool>[];
    var inFence = false;

    // Start with one open block.
    blocks.add(StringBuffer());
    closedFlags.add(false);

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (_fenceLine.hasMatch(line)) {
        inFence = !inFence;
      }

      final isBlank = line.trim().isEmpty;

      // A blank line outside a code fence is a paragraph boundary.
      // The blank line itself is NOT added to any block — it acts as a
      // separator.  The current block is now closed.
      if (!inFence && isBlank) {
        closedFlags[closedFlags.length - 1] = true;
        blocks.add(StringBuffer());
        closedFlags.add(false);
        continue;
      }

      // Append the line to the current block.
      final block = blocks.last;
      if (block.isNotEmpty) {
        block.write('\n');
      }
      block.write(line);
    }

    // Trim trailing empty blocks and their flags.
    while (blocks.isNotEmpty && blocks.last.isEmpty) {
      blocks.removeLast();
      closedFlags.removeLast();
    }

    if (blocks.isEmpty) {
      return const StreamBlockSplitResult([], '');
    }

    // Partition: blocks with closedFlags=true are closed, others are open.
    final List<String> closed = [];
    String open = '';

    for (var i = 0; i < blocks.length; i++) {
      final text = blocks[i].toString();
      if (closedFlags[i]) {
        if (text.isNotEmpty) closed.add(text);
      } else {
        open = text;
      }
    }

    return StreamBlockSplitResult(closed, open);
  }
}
