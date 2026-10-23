# Dart scanner

## What it is

The hand-written, import-free scanner behind `tokenizeDart`: it walks the
source left to right, decides a kind for each stretch, and returns adjacent
same-kind runs merged. It owns comments (nested), strings (raw, triple, escapes),
recursive interpolation, numbers, identifiers and the keyword list, and how far
damage from malformed input can spread.

## Governing decisions

- [ADR-0001](../../adr/0001-token-kinds-are-lexical-only.md) — decided which
  kinds exist, and its *Consequences* decided that interpolation insides are
  re-tokenized with the outside rules; its *Later record* records the one partition
  break and how it was removed.

## Design model

From the `dart_tokenizer.dart` library doc, its function docs and ADR-0001:

- **The layer imports nothing** — not Flutter, not `dart:*`. Sealed by
  `test/tokenizer/no_imports_test.dart`, which rejects `import`, `export` and
  `part` directives under `lib/src/tokenizer/` (the pubspec can no longer
  enforce it, since the package depends on Flutter).
- **Partition by construction.** Branches only append end offsets through one
  `emit` closure; tokens are cut at those offsets afterwards. `emit` drops an
  end that does not increase (and `assert`s in debug) — the last barrier,
  measured never reached by fuzzing (see Known holes for the count).
- **Comments are consumed whole in one step** (`_lineCommentEnd`,
  `_blockCommentEnd`). That, not branch order, is why an apostrophe in a
  comment opens nothing — measured by reversing the order (no change) and by
  crippling `_lineCommentEnd` (tests red). Block comments nest.
- **`_scanStringLiteral` and `_interpolationEnd` are mutually recursive**, and
  `_scanRange` re-scans the inside of each `${…}` with the outside rules. The
  boundary finder and the emitter use the same sub-scanners (strings and
  comments), so they cannot disagree; they did once, when `_interpolationEnd`
  did not know comments (`'${a /* } */ + 1}'`, commit `c8be0a8`).
- **Damage stops at the line.** An unclosed single-line string, and an unclosed
  interpolation inside one, stop at `\n`; only triple-quoted literals span
  lines. `\r` before `\n` stays inside the preceding token.
- **Keywords before `function`.** `_keywords` is checked first; then an
  identifier immediately followed by `(` is `function`. Any listed word is a
  keyword wherever it appears (`show`, `base` as variable names) — the cost of
  not parsing.
- **`r` is a raw prefix only where an identifier could not continue**, in both
  `_scanRange` and `_interpolationEnd`.
- **Runs are merged** because the widget makes one `TextSpan` per token and
  `TextSpan` equality is a deep walk (`tokenizeDart` doc).
- **Input bounds:** none. `source` is any string; interpolation nesting depth
  is bounded only by the call stack (`_scanRange` → `_scanStringLiteral` →
  `_interpolationEnd` recursion).

## Code

- `lib/src/tokenizer/dart_tokenizer.dart — tokenizeDart` (with its `emit`
  closure), `_scanRange`, `_lineCommentEnd`, `_blockCommentEnd`,
  `_scanStringLiteral`, `_interpolationEnd`, `_numberEnd`, `_identifierEnd`,
  `_isPunctuation`, `_keywords`
- Tests: `test/tokenizer/dart_tokenizer_test.dart`,
  `test/tokenizer/new_kinds_test.dart`, `test/tokenizer/corpus_test.dart`,
  `test/tokenizer/no_imports_test.dart`, `test/support/partition.dart —
  expectPartitions`, fixtures in `test/fixtures/*.dart.txt` (`.txt` so the
  gates do not parse malformed input — `test/fixtures/README.md`).

## Reference behaviour

- The ported origin, `reference/dart_highlighter.dart` (flutter_table_plus @
  `ac83b27`), is historical, no longer compared against (maintainer,
  2026-10-23). Its corpus counts (54 apostrophe comment lines; three nested
  interpolation cases; no raw/triple/block/escaped-quote cases), measured
  2026-09-02, are kept in the library doc as measurements.

## Cross-cutting invariants

- [pasted-bytes-are-the-input](../invariant/pasted-bytes-are-the-input.md)

## Blast radius

- [token-kinds](token-kinds.md) — what each kind means is defined by which
  branch emits it; changing a branch changes the documented meaning.
- [code-rendering](code-rendering.md) — the widget assumes merged runs (one
  span per run) and that tokenizing is cheap enough to do synchronously in
  `initState`/`didUpdateWidget`.
- [gates](gates.md) — the fixture corpus and this package's own `lib/` are the
  partition test's input; a fixture that becomes valid-looking or a `.dart`
  fixture changes what the gates see.

## Known holes / open

- Nothing bounds nesting depth; deeply nested `${'${'…` recursion is
  bounded only by the stack. Not measured.
- The fuzz count behind "the guard is never reached" differs between sources,
  both dated 2026-09-06: `tokenizeDart`'s `emit` comment says 200,000 inputs,
  ADR-0001's *Later record* says 300,000.
- Size: `tokenizeDart` runs on the UI isolate inside `SyntaxText`; the largest
  measured input is this file itself (3101 tokens, 2026-09-06). No bound or
  off-thread path exists.
