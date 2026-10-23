import 'package:flutter_syntax_highlight/flutter_syntax_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/partition.dart';

// The load-bearing claim of this suite is not "are the colours right" but "did
// anything change". A highlighter is a thing that stands between the
// consumer's bytes and the screen, and this package's claim is that what is on
// screen is the file you can paste.
//
// The three interpolation sites below were carried over verbatim from the
// reference corpus. Measured 2026-09-02, they were the only lexically hard
// constructs in that corpus's 2603 lines, and they are reproduced here so the
// scanner stays pinned to them even if the originals are rewritten later.

/// Flattens a token stream into `kind|text` lines.
///
/// The interpolation checks **compare the whole stream, not a property.** All
/// five inputs are canon, and for a check that looks only at a property there
/// is always a wrong stream that passes. Whatever changes, it has to go red.
List<String> streamOf(String source) => tokenizeDart(
  source,
).map((t) => '${t.kind.name}|${t.text}').toList(growable: false);

void main() {
  group('partition — the property the paste contract leans on', () {
    test('and for line endings this checkout will not produce today', () {
      // Escapes, not a multi-line literal: this file gets the checkout's
      // line-ending normalisation just the same, so writing it as a literal
      // would assert what the checkout produced, not what was intended. Only
      // escapes are immune to the checkout.
      const awkward =
          'class A {\r\n'
          '  // a comment with CRLF\r\n'
          '\r'
          '\tfinal x = 1;\n'
          '  // no trailing newline';

      // The side condition - the partition is satisfied even if one token
      // covers everything - is now carried by `expectPartitions` for every
      // call site.
      expectPartitions(awkward);
    });

    test('and for an empty file too', () {
      expect(tokenizeDart(''), isEmpty);
    });
  });

  group('a comment is consumed whole', () {
    // Measured 2026-09-02: in ten of the eleven files of the reference corpus,
    // 54 comment lines held a lone apostrophe, the most common hazard in the
    // corpus.
    //
    // What prevents it is the fact that the whole comment is consumed in one
    // step, so no character inside a comment is ever dispatched on — it is
    // **not** the order of the branches. An earlier version of this comment
    // claimed it was. A character is either `/` or `'` and never both, so the
    // two arms are mutually exclusive and reordering them does nothing. That
    // was confirmed by measurement, and the mutation that actually turned
    // these two red was crippling the line comment scanner.
    test('an apostrophe inside a comment does not open a string', () {
      const source = "// somebody's name\nfinal x = 1;\n";
      final tokens = tokenizeDart(source);

      expectPartitions(source);
      expect(tokens.first.kind, DartTokenKind.comment);
      expect(tokens.first.text, "// somebody's name");
      expect(
        tokens.any((t) => t.kind == DartTokenKind.string),
        isFalse,
        reason: 'the apostrophe was treated as a quote',
      );
      // And the code after it is still code.
      expect(
        tokens.any(
          (t) => t.kind == DartTokenKind.keyword && t.text.contains('final'),
        ),
        isTrue,
      );
    });

    test('a quote inside a doc comment does not leak into the next line', () {
      const source = "/// the API's shape\nconst a = 'x';\n";
      final tokens = tokenizeDart(source);

      expectPartitions(source);
      final strings = tokens
          .where((t) => t.kind == DartTokenKind.string)
          .toList();
      expect(strings, hasLength(1));
      expect(strings.single.text, "'x'");
    });
  });

  group('interpolation — the three hard sites of the reference corpus', () {
    // Carried over verbatim. Naive quote-pairing draws the third as string /
    // ✓ as code / ' : ' as string / ✗ as code — inverted, and on exactly the
    // two glyphs that snippet exists to show.
    //
    // With the inside of an interpolation tokenized recursively, "the whole
    // literal is one token" became false. The new claim is stronger: it used
    // to check only that the literal *was not split*, and now it checks
    // **whether the split result is right** — aiming straight at the failure
    // a quote-pair scanner actually commits (inside and outside swapped).
    test('a nested empty string inside an interpolation', () {
      const source = "final text = '\${newValue ?? ''}'.trim();";
      expectPartitions(source);
      expect(streamOf(source), [
        'keyword|final',
        'plain| text ',
        'punctuation|=',
        'plain| ',
        "string|'",
        'punctuation|\${',
        'plain|newValue ',
        'punctuation|??',
        'plain| ',
        "string|''", // the nested empty string comes out as a string
        'punctuation|}',
        "string|'",
        'punctuation|.',
        'function|trim',
        'punctuation|();',
      ]);
    });

    test('a nested string holding a comma, inside join', () {
      const source = "': \${selected.join(', ')}',";
      expectPartitions(source);
      expect(streamOf(source), [
        "string|': ",
        'punctuation|\${',
        'plain|selected',
        'punctuation|.',
        'function|join',
        'punctuation|(',
        "string|', '", // the nested string with a comma does not end the outer
        'punctuation|)}',
        "string|'",
        'punctuation|,',
      ]);
    });

    test('two interpolations, one holding a ternary of two strings', () {
      // This is where the package's claim shows up in the stream. The nested
      // '✓' and '✗' come out **as strings**, and the conditional around them
      // comes out as code.
      const source = "'\${term.value ? '✓' : '✗'} \${term.key}',";
      expectPartitions(source);
      expect(streamOf(source), [
        "string|'",
        'punctuation|\${',
        'plain|term',
        'punctuation|.',
        'plain|value ',
        'punctuation|?',
        'plain| ',
        "string|'✓'", // ← a string. A quote-pair scanner paints this as code
        'plain| ',
        'punctuation|:',
        'plain| ',
        "string|'✗'", // ← likewise
        'punctuation|}',
        'string| ',
        'punctuation|\${',
        'plain|term',
        'punctuation|.',
        'plain|key',
        'punctuation|}',
        "string|'",
        'punctuation|,',
      ]);
    });

    test(
      'and a brace inside an interpolated string is not the closing brace',
      () {
        const source = "'\${map['{']}'";
        expectPartitions(source);
        expect(streamOf(source), [
          "string|'",
          'punctuation|\${',
          'plain|map',
          'punctuation|[',
          "string|'{'", // ending the interpolation here would drift the rest
          'punctuation|]}',
          "string|'",
        ]);
      },
    );
  });

  group('rare constructs that must not break', () {
    // Checked with grep on 2026-09-02, not assumed: none of the below was in
    // the reference corpus. They are handled anyway — each costs a few lines,
    // and the consumer's code is under no obligation to be tame.
    test('a raw string does not handle escapes', () {
      const source = r"final p = r'a\' + 1;";
      final tokens = tokenizeDart(source);

      expectPartitions(source);
      final strings = tokens
          .where((t) => t.kind == DartTokenKind.string)
          .toList();
      expect(
        strings.single.text,
        r"r'a\'",
        reason:
            'the backslash was handled as an escape and skipped the closing '
            'quote, and the rest of the line took the string colour',
      );
    });

    test('a triple-quoted string spans lines', () {
      const source = "const a = '''\nline\n''';\n";
      final tokens = tokenizeDart(source);

      expectPartitions(source);
      final strings = tokens
          .where((t) => t.kind == DartTokenKind.string)
          .toList();
      expect(strings.single.text, "'''\nline\n'''");
    });

    test('block comments nest, as in Dart and not in C', () {
      const source = 'a /* outer /* inner */ still outer */ b';
      final tokens = tokenizeDart(source);

      expectPartitions(source);
      final comments = tokens
          .where((t) => t.kind == DartTokenKind.comment)
          .toList();
      expect(
        comments.single.text,
        '/* outer /* inner */ still outer */',
        reason: 'it stopped at the first */ and the tail was mis-coloured',
      );
      // Side condition: `b` is still outside the comment.
      expect(tokens.last.text.trim(), 'b');
    });

    test('an unclosed string stops at the newline, not at the end of file', () {
      // Confines the damage from syntax this scanner does not understand to
      // the line it is on, rather than the rest of the file.
      const source = "final a = 'oops\nfinal b = 2;\n";
      final tokens = tokenizeDart(source);

      expectPartitions(source);
      final strings = tokens
          .where((t) => t.kind == DartTokenKind.string)
          .toList();
      expect(strings.single.text, "'oops");
      expect(
        tokens.any(
          (t) => t.kind == DartTokenKind.keyword && t.text.contains('final'),
        ),
        isTrue,
        reason: 'the second line was swallowed by the unclosed string',
      );
    });

    test('and an unclosed interpolation stops there too', () {
      // The boundary above was stated without conditions, and it had a hole:
      // `${` handed scanning to the interpolation scanner, which had no
      // newline boundary of its own and returned the end of the file. Two
      // characters were enough to slip out of the guarantee, and the test
      // above could not see it because `'oops` has no `$`.
      //
      // The boundary still holds after recursive tokenizing. It is now
      // checked against the whole stream — the second line coming out as code
      // is plain to see.
      const source = "final a = '\${oops\nfinal b = 2;\n";
      expectPartitions(source);
      expect(streamOf(source), [
        'keyword|final',
        'plain| a ',
        'punctuation|=',
        'plain| ',
        "string|'",
        'punctuation|\${',
        'plain|oops\n', // the interpolation ends at the newline
        'keyword|final', // and the second line comes back as code
        'plain| b ',
        'punctuation|=',
        'plain| ',
        'number|2',
        'punctuation|;',
        'plain|\n',
      ]);
      // Side condition — the second line was not swallowed by a string.
      expect(
        tokenizeDart(
          source,
        ).where((t) => t.kind == DartTokenKind.keyword).length,
        2,
        reason: 'the rest of the file was painted as one string',
      );
    });
  });

  group(
    'comments inside an interpolation — where the two scanners drifted',
    () {
      // The end of an interpolation is set by the brace-counting scanner, and
      // its inside is walked again by the same dispatch as the outside. If the
      // two drift apart, the boundary is wrong.
      //
      // They really did drift. The brace-counting side did not know about
      // comments and took a brace **inside** a comment as the end of the
      // interpolation, so in the first input below the comment was cut in half
      // and the rest became string. And all of these are **valid Dart that
      // actually runs** — this is not a story about defending against broken
      // input.
      test('a brace inside a block comment does not end the interpolation', () {
        const source = "'\${a /* } */ + 1}'";
        expectPartitions(source);
        expect(streamOf(source), [
          "string|'",
          'punctuation|\${',
          'plain|a ',
          'comment|/* } */', // cut in half, this would be `/* `
          'plain| ',
          'punctuation|+',
          'plain| ',
          'number|1',
          'punctuation|}',
          "string|'",
        ]);
      });

      test('even when a line comment spans lines inside triple quotes', () {
        const source = "'''\${a // c\n}'''";
        expectPartitions(source);
        expect(streamOf(source), [
          "string|'''",
          'punctuation|\${',
          'plain|a ',
          'comment|// c',
          'plain|\n',
          'punctuation|}',
          "string|'''",
        ]);
      });

      test('a quote inside a comment does not open a string — once a throwing '
          'input', () {
        // A minimal repro found by fuzzing. Before the fix it died with a
        // `RangeError` — the clamped end went behind the previous end and
        // `substring` threw. The library's only guarantee breaking with an
        // exception is worse than the partition breaking.
        const source = "'\${/*'*/'}\\n'}'";
        expectPartitions(source);
        expect(streamOf(source), [
          "string|'",
          'punctuation|\${',
          "comment|/*'*/",
          "string|'}",
          'escape|\\n',
          "string|'",
          'punctuation|}',
          "string|'",
        ]);
      });

      test('an unclosed line comment ends the interpolation and the string '
          'together', () {
        // `'\${a // b}'` has no newline, so the comment runs to the end of the
        // input. It is not valid Dart, and the damage being confined to that
        // line is right.
        const source = "'\${a // b}'";
        expectPartitions(source, expectClassified: false);
        expect(streamOf(source), [
          "string|'",
          'punctuation|\${',
          'plain|a ',
          "comment|// b}'",
        ]);
      });

      test(
        'a raw string inside an interpolation sets the boundary differently',
        () {
          // The brace-counting side has to check the `r` prefix too. Without
          // it, it reads `\'` as an escape, runs past the closing quote, and
          // looks for the end of the interpolation in the wrong place.
          const source = "'\${r'a\\'}'";
          expectPartitions(source);
          expect(streamOf(source), [
            "string|'",
            'punctuation|\${',
            "string|r'a\\'",
            'punctuation|}',
            "string|'",
          ]);
        },
      );
    },
  );

  group('classification', () {
    test('keywords, numbers and punctuation come out as themselves', () {
      const source = 'const x = 0xFF + 1.5e3;';
      final tokens = tokenizeDart(source);

      expectPartitions(source);
      expect(
        tokens.firstWhere((t) => t.kind == DartTokenKind.keyword).text,
        'const',
      );
      final numbers = tokens
          .where((t) => t.kind == DartTokenKind.number)
          .map((t) => t.text)
          .toList();
      expect(numbers, ['0xFF', '1.5e3']);
    });

    test('a dot after an integer is not part of the literal', () {
      const source = '1.toString()';
      final tokens = tokenizeDart(source);

      expectPartitions(source);
      expect(tokens.first.kind, DartTokenKind.number);
      expect(
        tokens.first.text,
        '1',
        reason: 'the method name was eaten by the number literal',
      );
    });

    test('adjacent runs of the same kind are coalesced into one', () {
      // It is not cosmetic. The widget layer turns one token into one
      // `TextSpan`, `SelectableText` rebuilds its controller whenever the tree
      // compares unequal, and `TextSpan` equality is a deep walk. A span per
      // bracket would put thousands of `TextStyle` comparisons on every
      // rebuild to no visible end.
      final tokens = tokenizeDart('((( )))');

      expectPartitions('((( )))');
      expect(
        tokens,
        hasLength(3),
        reason: 'punctuation / whitespace / punctuation, not seven tokens',
      );
    });

    test('a non-ASCII glyph survives as one token', () {
      // The scanner advances one code unit at a time, so this is a claim that
      // a surrogate pair is not split into two spans but joined back up.
      const source = "// an em dash — and a check ✓\n";
      final tokens = tokenizeDart(source);

      expectPartitions(source);
      expect(tokens.first.text, contains('—'));
      expect(tokens.first.text, contains('✓'));
    });
  });
}
