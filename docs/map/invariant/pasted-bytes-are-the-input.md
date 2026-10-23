# Pasted bytes are the input

## The fact

What a reader copies off a `SyntaxText` is byte for byte the `source` string it
was given: no character dropped, added, reordered, re-cased or line-ending
normalised. Checkable as `tokenizeDart(s).map((t) => t.text).join() == s`, and
as the rendered `TextSpan` tree flattening (`toPlainText(includeSemanticsLabels:
false)`) to `s`.

## Why it is cross-cutting

Three sites hold it, and none of them can hold it for the others:

- the scanner, by cutting every token at a recorded end offset
  (`source.substring(previousEnd, thisEnd)`), never rebuilding text;
- the span tree, by putting exactly one `TextSpan(text: token.text)` per token
  under a root span that carries no text and no placeholder child;
- the copy button, by sending `widget.source` itself to the clipboard.

The widget calls the scanner, but nothing in the scanner stops the widget from
adding a gutter `WidgetSpan` (which writes `\u{FFFC}` into every copied line),
and nothing in the span tree stops the scanner from normalising `\r\n`. A
change to either alone breaks the package's central claim (GLOSSARY.md,
*Partition*: "It is this package's central claim").

## Territories it holds in

- [dart-scanner](../territory/dart-scanner.md) — `tokenizeDart`: parallel
  `kinds`/`ends` lists, `emit`'s monotonic-end guard, run merging by substring.
- [code-rendering](../territory/code-rendering.md) — `_SyntaxTextState.build`:
  one `TextSpan` per token, root span with no own text.
- [copy-control](../territory/copy-control.md) — `_SyntaxTextState._copy`:
  `Clipboard.setData(ClipboardData(text: widget.source))`.

## What a violation looks like

Code copied off the screen does not compile, or differs in a diff tool, from
what the app passed in. Reproduces with CRLF input (a split-on-`\n` scanner
drops `\r`), with mixed-case keywords (a lower-cased match emitted), or with any
placeholder child in the span tree (`\u{FFFC}` per line).

## Discovery history

- Stated as the package's claim from the first scanner port (commit `0ad9765`,
  2026-09-06) and asserted over the fixture corpus, this package's own `lib/`,
  and both again as CRLF — `test/tokenizer/corpus_test.dart`, group
  `partition — the property the paste contract leans on`.
- Broken once on valid Dart: a defensive end-offset clamp moved an end backwards
  and `substring` threw (commit `c8be0a8`, 2026-09-06; ADR-0001 *Later record*).
- A partition check alone passes on a scanner that emits one `plain` token for
  everything — measured by doing it; `test/support/partition.dart` —
  `expectPartitions` adds the "more than one kind" side condition.
- Widget side asserted by `test/widget/syntax_text_test.dart`, group
  `the highlighter cannot change what gets pasted`.

## Where it will recur

Any change that adds a child to the span tree that is not a `TextSpan` built
from `token.text`, that transforms `source` before it reaches `tokenizeDart`, or
that emits a token whose text is not a substring at recorded offsets. Line
numbers, folding, inline badges and "trim trailing whitespace" are all this.
README, *There are no line numbers*, names the first.
