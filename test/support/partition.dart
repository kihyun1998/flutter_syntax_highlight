import 'package:flutter_syntax_highlight/flutter_syntax_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every character, in order, exactly once.
///
/// This is the paste contract itself. Repeated by hand in several places, one
/// of them drifts, so it is written once, and that is why it lives outside the
/// test files.
///
/// **Checking only the partition makes a test that cannot fail.** A tokenizer
/// that spits out the whole source as a single `plain` token satisfies the
/// partition perfectly — measured, not a guess. Changed that way and run, the
/// whole corpus check was green.
///
/// So for an input with content, a side condition that **the scanner actually
/// classified** is applied too. Without this one line, every call site of this
/// file guards nothing.
///
/// [expectClassified] turns that side condition off. There are inputs where
/// being one token whole is **that test's claim itself** — such as a single
/// string literal that includes an interpolation. There one kind is right, so
/// the condition is turned off, but by name, so the call site keeps why it
/// was turned off.
void expectPartitions(
  String source, {
  String? label,
  bool expectClassified = true,
}) {
  final tokens = tokenizeDart(source);
  final where = label == null ? '' : ' ($label)';

  expect(
    tokens.map((t) => t.text).join(),
    source,
    reason:
        'the input changed on its way through tokenizing$where — '
        'what is drawn on screen is no longer the bytes the consumer handed '
        'over',
  );

  // An input of only whitespace is right to come out as one kind. Demanding
  // variety there too would turn something true red.
  if (!expectClassified || source.trim().isEmpty) return;

  expect(
    tokens.map((t) => t.kind).toSet().length,
    greaterThan(1),
    reason:
        'the partition is satisfied even if one token covers everything'
        '$where. This condition catches the scanner giving up on classifying',
  );
}
