import 'package:flutter_test/flutter_test.dart';
import 'package:ccpocket/helpers/streaming_block_splitter.dart';

void main() {
  late StreamingBlockSplitter splitter;

  setUp(() {
    splitter = StreamingBlockSplitter();
  });

  group('basic cases', () {
    test('empty string', () {
      final r = splitter.split('');
      expect(r.closedBlocks, isEmpty);
      expect(r.openTail, isEmpty);
    });

    test('single chunk — all open', () {
      final r = splitter.split('hello');
      expect(r.closedBlocks, isEmpty);
      expect(r.openTail, 'hello');
    });

    test('two paragraphs — first closed, second open', () {
      final r = splitter.split('hello\n\nworld');
      expect(r.closedBlocks, ['hello']);
      expect(r.openTail, 'world');
    });

    test('three paragraphs — first two closed, last open', () {
      final r = splitter.split('a\n\nb\n\nc');
      expect(r.closedBlocks, ['a', 'b']);
      expect(r.openTail, 'c');
    });
  });

  group('code fence preservation', () {
    test('tilde fence with internal blank line stays as one block', () {
      final r = splitter.split('p1\n\n~~~\ncode\n\nmore\n~~~\n\np2');
      expect(r.closedBlocks, ['p1', '~~~\ncode\n\nmore\n~~~']);
      expect(r.openTail, 'p2');
    });

    test('backtick fence with language', () {
      final r = splitter.split('```python\ncode\n```\n\nafter');
      expect(r.closedBlocks, ['```python\ncode\n```']);
      expect(r.openTail, 'after');
    });

    test('fence with bash lang in multi-paragraph text', () {
      final r = splitter.split('before\n\n```bash\nls -la\n```\n\nend');
      expect(r.closedBlocks, ['before', '```bash\nls -la\n```']);
      expect(r.openTail, 'end');
    });

    test('indented fence (3 spaces) with internal blank line', () {
      final r = splitter.split('text\n\n   ```\ncode\n\nmore\n   ```\n\nafter');
      expect(r.closedBlocks, ['text', '   ```\ncode\n\nmore\n   ```']);
      expect(r.openTail, 'after');
    });

    test('unclosed fence — preceding paragraph closes, fence stays open', () {
      final r = splitter.split('text\n\n```\ncode');
      expect(r.closedBlocks, ['text']);
      expect(r.openTail, '```\ncode');
    });

    test('only code fence — all open', () {
      final r = splitter.split('```python\ncode');
      expect(r.closedBlocks, isEmpty);
      expect(r.openTail, '```python\ncode');
    });

    test('fence with internal blank line before closing', () {
      final r = splitter.split('text\n\n```\ncode\n\nmore\n```\n\nafter');
      expect(r.closedBlocks, ['text', '```\ncode\n\nmore\n```']);
      expect(r.openTail, 'after');
    });

    test('multiple complete fences in sequence', () {
      final r = splitter.split(
        'p1\n\n```\ncode1\n```\n\np2\n\n```\ncode2\n```\n\np3',
      );
      expect(r.closedBlocks, [
        'p1',
        '```\ncode1\n```',
        'p2',
        '```\ncode2\n```',
      ]);
      expect(r.openTail, 'p3');
    });
  });

  group('edge cases', () {
    test('consecutive empty lines between paragraphs', () {
      final r = splitter.split('a\n\n\n\nb');
      expect(r.closedBlocks, ['a']);
      expect(r.openTail, 'b');
    });

    test('realistic streaming: multi-paragraph reply', () {
      final r = splitter.split('Hello world.\n\nI am doing great.\n\nNow');
      expect(r.closedBlocks, ['Hello world.', 'I am doing great.']);
      expect(r.openTail, 'Now');
    });

    test('trailing double newline — closed block, empty open', () {
      final r = splitter.split('a\n\n');
      expect(r.closedBlocks, ['a']);
      expect(r.openTail, isEmpty);
    });

    test('blank line at start', () {
      final r = splitter.split('\n\na\n\nb');
      expect(r.closedBlocks, ['a']);
      expect(r.openTail, 'b');
    });
  });
}
