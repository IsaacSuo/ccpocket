import 'package:ccpocket/theme/markdown_math.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

void main() {
  group('Markdown math parsing', () {
    test('parses supported inline delimiters', () {
      final nodes = _parse(r'Value $x^2$ and \(x+y\).');

      expect(_elements(nodes, 'tex-inline').map((e) => e.textContent), [
        'x^2',
        'x+y',
      ]);
    });

    test('parses supported display delimiters', () {
      final nodes = _parse(r'''$$\frac{a}{b}$$

\[
x+y
\]''');

      expect(_elements(nodes, 'tex-block').map((e) => e.textContent), [
        r'\frac{a}{b}',
        'x+y',
      ]);
    });

    test('does not parse TeX inside inline or fenced code', () {
      final nodes = _parse(r'''`$x$`

```text
$y$
```''');

      expect(_elements(nodes, 'tex-inline'), isEmpty);
      expect(_elements(nodes, 'tex-block'), isEmpty);
    });

    test('leaves dollar amounts and unfinished streaming TeX as text', () {
      final nodes = _parse(r'Costs $10 and streaming $x +');

      expect(_elements(nodes, 'tex-inline'), isEmpty);
      expect(nodes.map((node) => node.textContent).join(), contains(r'$10'));
      expect(nodes.map((node) => node.textContent).join(), contains(r'$x +'));
    });

    test(
      'changes from text to an element only after stream delimiter closes',
      () {
        expect(_elements(_parse(r'Answer: $x^2 +'), 'tex-inline'), isEmpty);
        expect(
          _elements(
            _parse(r'Answer: $x^2 + 1$'),
            'tex-inline',
          ).single.textContent,
          'x^2 + 1',
        );
      },
    );
  });

  group('Markdown math widgets', () {
    testWidgets('renders inline and display formulas with Math widgets', (
      tester,
    ) async {
      await tester.pumpWidget(
        _markdown(r'''Inline $x^2$.

$$\frac{a}{b}$$'''),
      );

      expect(find.byType(Math), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey('markdown_math_inline')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('markdown_math_block')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('invalid TeX falls back to the original source', (
      tester,
    ) async {
      await tester.pumpWidget(_markdown(r'Bad $\notacommand{x}$ formula.'));
      await tester.pump();

      expect(find.text(r'$\notacommand{x}$'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

List<md.Node> _parse(String source) {
  final document = md.Document(
    blockSyntaxes: markdownMathBlockSyntaxes,
    inlineSyntaxes: markdownMathInlineSyntaxes,
    extensionSet: md.ExtensionSet.gitHubFlavored,
    encodeHtml: false,
  );
  return document.parseLines(source.split('\n'));
}

Iterable<md.Element> _elements(List<md.Node> nodes, String tag) sync* {
  for (final node in nodes) {
    if (node is! md.Element) continue;
    if (node.tag == tag) yield node;
    if (node.children != null) yield* _elements(node.children!, tag);
  }
}

Widget _markdown(String data) {
  return MaterialApp(
    home: Scaffold(
      body: MarkdownBody(
        data: data,
        inlineSyntaxes: markdownMathInlineSyntaxes,
        blockSyntaxes: markdownMathBlockSyntaxes,
        builders: markdownMathBuilders,
      ),
    ),
  );
}
