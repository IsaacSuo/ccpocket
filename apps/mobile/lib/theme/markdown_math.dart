import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

const _inlineTexTag = 'tex-inline';
const _blockTexTag = 'tex-block';

/// TeX syntaxes shared by every Markdown surface in the app.
///
/// A syntax only matches after its closing delimiter has arrived. This is
/// important for streaming messages: an unfinished formula remains ordinary
/// text until the matching delimiter is present.
final markdownMathInlineSyntaxes = <md.InlineSyntax>[
  InlineDollarTexSyntax(),
  ParenthesizedTexSyntax(),
];

final markdownMathBlockSyntaxes = <md.BlockSyntax>[
  DisplayDollarTexSyntax(),
  BracketedDisplayTexSyntax(),
];

final markdownMathBuilders = <String, MarkdownElementBuilder>{
  _inlineTexTag: TexElementBuilder(),
  _blockTexTag: TexElementBuilder(displayMode: true),
};

/// Parses `$...$` while deliberately ignoring dollar amounts such as `$10`.
///
/// Numeric-only formulas can still be written as `\(10\)`. Excluding a digit
/// immediately after the opening dollar prevents prose like
/// "costs $10 and solve $x$" from becoming one large accidental formula.
class InlineDollarTexSyntax extends md.InlineSyntax {
  InlineDollarTexSyntax()
    : super(r'\$(?![\s$\d])((?:\\.|[^\\$\n])+?)\$(?!\$)', startCharacter: 0x24);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    _addTexElement(parser, match[1]!, match[0]!);
    return true;
  }
}

/// Parses the unambiguous inline TeX delimiter `\(...\)`.
class ParenthesizedTexSyntax extends md.InlineSyntax {
  ParenthesizedTexSyntax()
    : super(r'\\\((?!\s)(.+?)\\\)', startCharacter: 0x5c);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    _addTexElement(parser, match[1]!, match[0]!);
    return true;
  }
}

void _addTexElement(md.InlineParser parser, String expression, String raw) {
  final element = md.Element.text(_inlineTexTag, expression);
  element.attributes['raw'] = raw;
  parser.addNode(element);
}

/// Parses display TeX surrounded by `$$` delimiters.
class DisplayDollarTexSyntax extends _DisplayTexSyntax {
  const DisplayDollarTexSyntax() : super(r'$$');
}

/// Parses display TeX surrounded by `\[` and `\]` delimiters.
class BracketedDisplayTexSyntax extends _DisplayTexSyntax {
  const BracketedDisplayTexSyntax() : super(r'\[', closingDelimiter: r'\]');
}

abstract class _DisplayTexSyntax extends md.BlockSyntax {
  final String openingDelimiter;
  final String closingDelimiter;

  const _DisplayTexSyntax(this.openingDelimiter, {String? closingDelimiter})
    : closingDelimiter = closingDelimiter ?? openingDelimiter;

  @override
  RegExp get pattern => RegExp(r'^ {0,3}' + RegExp.escape(openingDelimiter));

  @override
  bool canParse(md.BlockParser parser) => _findEnd(parser) != null;

  _DisplayTexEnd? _findEnd(md.BlockParser parser) {
    final firstLine = parser.current.content.trim();
    if (!firstLine.startsWith(openingDelimiter)) return null;

    final afterOpening = firstLine.substring(openingDelimiter.length);
    if (afterOpening.endsWith(closingDelimiter) &&
        afterOpening.length > closingDelimiter.length) {
      return _DisplayTexEnd(0, afterOpening.length - closingDelimiter.length);
    }

    for (var offset = 1; ; offset++) {
      final line = parser.peek(offset);
      if (line == null) return null;
      if (line.content.trim() == closingDelimiter) {
        return _DisplayTexEnd(offset, 0);
      }
    }
  }

  @override
  md.Node? parse(md.BlockParser parser) {
    final end = _findEnd(parser)!;
    final rawLines = <String>[];
    final expressionLines = <String>[];

    for (var offset = 0; offset <= end.lineOffset; offset++) {
      final line = parser.current.content;
      rawLines.add(line);

      if (offset == 0) {
        final trimmed = line.trim();
        var content = trimmed.substring(openingDelimiter.length);
        if (end.lineOffset == 0) {
          content = content.substring(
            0,
            content.length - closingDelimiter.length,
          );
        }
        if (content.isNotEmpty) expressionLines.add(content);
      } else if (offset < end.lineOffset) {
        expressionLines.add(line);
      }

      parser.advance();
    }

    final expression = expressionLines.join('\n').trim();
    final element = md.Element.text(_blockTexTag, expression);
    element.attributes['raw'] = rawLines.join('\n');
    return element;
  }
}

class _DisplayTexEnd {
  final int lineOffset;
  final int inlineClosingIndex;

  const _DisplayTexEnd(this.lineOffset, this.inlineClosingIndex);
}

/// Renders custom TeX AST elements with a safe plain-text fallback.
class TexElementBuilder extends MarkdownElementBuilder {
  final bool displayMode;

  TexElementBuilder({this.displayMode = false});

  @override
  bool isBlockElement() => displayMode;

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {
    // Keep flutter_markdown's inline stack balanced for block elements. The
    // placeholder is replaced by the final widget below.
    if (displayMode) return const SizedBox.shrink();
    return null;
  }

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final expression = element.textContent;
    final raw = element.attributes['raw'] ?? expression;
    final style = DefaultTextStyle.of(
      context,
    ).style.merge(parentStyle ?? preferredStyle);
    final math = Math.tex(
      expression,
      key: ValueKey('markdown_math_${displayMode ? 'block' : 'inline'}'),
      mathStyle: displayMode ? MathStyle.display : MathStyle.text,
      textStyle: style,
      onErrorFallback: (_) => Text(raw, style: style),
    );

    if (!displayMode) return math;

    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: math,
        ),
      ),
    );
  }
}
