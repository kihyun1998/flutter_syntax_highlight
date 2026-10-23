import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/partition.dart';

/// Puts the partition to **real chunks of code**.
///
/// The reference ran this property over eleven files read from the host app's
/// bundle. That corpus is not here, so two things this package owns stand in
/// for it:
///
///  * `test/fixtures/` — written by hand to hold the hard constructs the
///    reference doc enumerated with grep on 2026-09-02. Why the extension is
///    not `.dart` is in that directory's README.
///  * this package's own source under `lib/` — free, the corpus grows as the
///    code grows, and it is always real Dart.
///
/// **Line endings are made here, not in the files.** `.gitattributes` is
/// `* text=auto`, so a file holding CRLF is normalised on checkout, and then
/// the test tests that machine rather than the code. Each input runs once as
/// LF as it is, and once with `\r\n` substituted.
void main() {
  final fixtures = Directory('test/fixtures')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart.txt'))
      .toList();

  final ownSource = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  group('partition — the property the paste contract leans on', () {
    // A loop over an empty list passes vacuously. So the guard is not a
    // separate test but sits **inside the same test as the loop** —
    // `no_imports_test.dart` uses the same shape for the same reason. Kept
    // apart, the partition checks in this file could each be green while
    // running nothing.
    test('holds over the whole fixture corpus', () {
      expect(
        fixtures,
        isNotEmpty,
        reason: 'no fixtures — this check runs nothing',
      );
      for (final file in fixtures) {
        expectPartitions(file.readAsStringSync(), label: file.path);
      }
    });

    test('and over this package\'s own source too', () {
      expect(
        ownSource,
        isNotEmpty,
        reason: 'no source under lib/ — the growing half of the corpus is gone',
      );
      for (final file in ownSource) {
        expectPartitions(file.readAsStringSync(), label: file.path);
      }
    });

    test('and all of it once more, converted to CRLF', () {
      expect([...fixtures, ...ownSource], isNotEmpty);
      // Puts carriage returns through regardless of what the checkout
      // produced. A scanner that splits on newlines and re-joins dies here.
      for (final file in [...fixtures, ...ownSource]) {
        final crlf = file.readAsStringSync().replaceAll('\n', '\r\n');
        expect(
          crlf,
          contains('\r\n'),
          reason: '${file.path} has no newline, so this conversion did nothing',
        );
        expectPartitions(crlf, label: '${file.path} converted to CRLF');
      }
    });
  });

  group('the corpus actually holds what it says it holds', () {
    // The partition checks alone cannot tell what the corpus covers. Four
    // empty files satisfy the partition too. If a construct drops out while a
    // fixture is being edited, the checks above stay green while guarding
    // nothing, so the list is pinned here.
    late final String all;

    setUpAll(() {
      all = fixtures.map((f) => f.readAsStringSync()).join('\n');
    });

    final constructs = <String, String>{
      "raw string": r"r'",
      "triple-quoted string": "'''",
      "escaped quote": r"\'",
      "// inside a string": '// not a comment',
      "nested block comment": '/* outer /* inner */',
      "comment with an apostrophe": "// somebody's",
      "nested interpolation": r"${term.value ? '",
      "brace in a string inside an interpolation": r"${map['{']}",
      "unclosed string": "final a = 'oops",
      "unclosed interpolation": r"'${oops",
      // The kinds ADR-0001 added as the eighth and seventh. The corpus has to
      // hold them so that later partition work passes through both kinds.
      "escape sequence": r"'a\nb\tc'",
      "call name": '.trim()',
    };

    constructs.forEach((name, needle) {
      test(name, () {
        expect(
          all,
          contains(needle),
          reason:
              'gone from the fixtures — the corpus no longer covers this '
              'construct',
        );
      });
    });
  });
}
