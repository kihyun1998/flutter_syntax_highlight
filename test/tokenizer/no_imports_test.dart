import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Seals the seam between the two layers.
///
/// **The pubspec can no longer enforce this,** because this package has come
/// to depend on Flutter. In the reference the tokenizer lived in a package
/// that did not know Flutter, so the dependency graph itself was the guard;
/// here that guard is gone.
///
/// Without this, the first person to reach for `Color` in the scanner quietly
/// welds the two layers, and nothing reports it. From then on the claim "the
/// hard part is a pure function that can be tested without a widget" is
/// false, but the green stays.
void main() {
  // Looking only at `import` leaks in three directions:
  //
  //  * `export 'package:flutter/...'` is exactly the same hole.
  //  * **`part` is the most realistic hole.** Make the tokenizer a `part` of a
  //    library that imports Flutter, and `Color` comes in without a single
  //    directive line in this file. A check that counts directives is
  //    bypassed whole.
  //  * `import'dart:math';` is valid Dart even with no space. Requiring `\\s+`
  //    misses it.
  //
  // So it does not require a quote and looks at the directive keyword itself.
  // That is the direction false positives fall in (a line starting with an
  // identifier that begins with `part`), and that is the safe direction.
  final directive = RegExp(r'^\s*(import|export|part)\b');

  test('the tokenizer layer imports nothing', () {
    final dir = Directory('lib/src/tokenizer');
    expect(
      dir.existsSync(),
      isTrue,
      reason: 'without a tokenizer layer this test guards nothing',
    );

    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    // Two side conditions. This guard's boundary is a **directory**, so if
    // what it protects moves out of it, the loop passes vacuously.
    expect(
      files,
      isNotEmpty,
      reason: 'no files to read — this test has become unable to fail',
    );
    expect(
      files.map((f) => f.uri.pathSegments.last),
      contains('dart_tokenizer.dart'),
      reason:
          'the scanner is not in this directory. Even with only one other '
          '.dart file left, the isNotEmpty above passes, so the guard turns '
          'green while quietly empty',
    );

    final offenders = <String>[];
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var n = 0; n < lines.length; n++) {
        if (directive.hasMatch(lines[n])) {
          offenders.add('${file.path}:${n + 1}  ${lines[n].trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'the tokenizer layer pulled something in. Once the two layers are '
          'welded, what a kind is and what a kind looks like live in one '
          'place, and then the former cannot be tested without the '
          'latter:\n${offenders.join('\n')}',
    );
  });
}
