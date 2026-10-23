import 'package:flutter_syntax_highlight/flutter_syntax_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/partition.dart';

/// `escape` and `function` — the two newly added to the list of eight that
/// [ADR-0001](../../docs/adr/0001-token-kinds-are-lexical-only.md) settled.
///
/// The two differ in nature. For `escape` the scanner already walks the inside
/// of a string, so it only has to emit the boundary, but `function` **adds a
/// branch that was not there.** It is the only item in the whole decision that
/// widens the scanner's behaviour, so the regression risk is concentrated
/// here.
List<String> textsOf(String source, DartTokenKind kind) => tokenizeDart(
  source,
).where((t) => t.kind == kind).map((t) => t.text).toList();

void main() {
  group('escape — lexically decidable', () {
    test('a string splits into string / escape / string', () {
      const source = r"const a = 'a\nb';";
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.escape), [r'\n']);
      expect(textsOf(source, DartTokenKind.string), ["'a", "b'"]);
    });

    test('an escaped quote does not end the string', () {
      const source = r"const a = 'it\'s';";
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.escape), [r"\'"]);
      expect(textsOf(source, DartTokenKind.string), ["'it", "s'"]);
    });

    test('back-to-back escapes are coalesced into one', () {
      // The existing rule applies to the new kind unchanged — adjacent runs of
      // the same kind are coalesced into one. There is no reason to split one
      // style into three spans.
      const source = r"const a = '\n\t\\';";
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.escape), [r'\n\t\\']);
    });

    test('with a character in between, escapes come out separately', () {
      // Shows that coalescing does not mean "cannot tell them apart".
      const source = r"const a = '\na\tb';";
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.escape), [r'\n', r'\t']);
      expect(textsOf(source, DartTokenKind.string), ["'", 'a', "b'"]);
    });

    test(
      'no escape comes out of a raw string inside an interpolation either',
      () {
        // The interpolation scanner hands off to the string scanner on seeing
        // only a quote. Unless it also checks for the `r` prefix, a raw string
        // inside an interpolation is scanned as a string that handles escapes,
        // the boundary drifts, and even the escape kind is attached wrongly.
        const source = "var a = '\${r'x\\n'}';";
        expectPartitions(source, expectClassified: false);
        expect(textsOf(source, DartTokenKind.escape), isEmpty);
      },
    );

    test('no escape comes out of a raw string', () {
      // The reference test already guarded "if the backslash is treated as an
      // escape, it skips over the closing quote". With the `escape` kind, that
      // claim comes to mean "no escape token comes out here at all", and gets
      // sharper.
      const source = r"const p = r'a\n';";
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.escape), isEmpty);
      expect(textsOf(source, DartTokenKind.string), [r"r'a\n'"]);
    });

    test('a backslash outside a string is not an escape', () {
      const source = r'const a = 1 \ 2;';
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.escape), isEmpty);
    });

    test('it splits inside a triple-quoted string too', () {
      const source = "const a = '''x\\ny''';";
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.escape), [r'\n']);
    });
  });

  group('function — the name immediately before an opening parenthesis', () {
    test('a call name is function', () {
      const source = 'foo(1);';
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.function), ['foo']);
    });

    test('a lone identifier is plain', () {
      const source = 'foo + bar;';
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.function), isEmpty);
      // The trailing whitespace is coalesced into the same run, so it is
      // `'foo '`.
      expect(textsOf(source, DartTokenKind.plain), ['foo ', ' bar']);
    });

    test('a keyword is keyword even with a parenthesis attached', () {
      // The keyword branch catches it first. If this breaks, `if`, `for`,
      // `while`, `switch` and `catch` are all painted as function names — the
      // most visible regression.
      const source = 'if(x) return;';
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.function), isEmpty);
      expect(textsOf(source, DartTokenKind.keyword), contains('if'));
    });

    test('a method name is function too', () {
      const source = '1.toString()';
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.function), ['toString']);
      // What the reference test guarded — the dot is not part of the number —
      // still holds.
      expect(tokenizeDart(source).first.text, '1');
    });

    test('a constructor call is, lexically, the same thing', () {
      // Starting with a capital does not make it a type. That is the ground on
      // which ADR-0001 rejected `type` vs `variable` — the official Dart
      // grammar decides that distinction with `[_$]*[A-Z]...`, a guess based
      // on convention. `Foo` is `function` here because the opening
      // parenthesis immediately follows it, regardless of the capital.
      const source = 'Foo(1)';
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.function), ['Foo']);
    });

    test('with whitespace in between, it is not treated as a call', () {
      // The **immediately before** rule is kept narrow. It is the simplest
      // lexically decidable form, and since `dart format` removes that
      // whitespace, it hardly ever comes up in real code. Widening the rule
      // has to change this test first.
      const source = 'foo (1);';
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.function), isEmpty);
    });

    test('a name after a dot is still plain without a parenthesis', () {
      const source = 'a.b + c;';
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.function), isEmpty);
    });
  });
}
