# Token kinds

## What it is

The vocabulary the two layers share: what a stretch of source *is*, for the
purpose of drawing it differently. `DartTokenKind` and `DartToken` are the
tokenizer layer's whole public type surface, and the seam the widget layer and
the one outside consumer build on.

## Governing decisions

- [ADR-0001](../../adr/0001-token-kinds-are-lexical-only.md) — a distinction
  becomes a kind only if a left-to-right scanner can decide it from characters
  alone; the list is eight and effectively permanent.

[ADR-0002](../../adr/0002-a-palette-carries-its-own-background.md) is adjacent:
it adds a palette field that is explicitly *not* a kind.

## Design model

From ADR-0001 and the `DartTokenKind` doc comments:

- A kind names what something *looks like*, never what it *means*. Type vs
  variable is a guess (capitalisation) and is rejected; a half-right answer is
  worse than none because the reader believes it.
- `function` is a lexical position — an identifier *immediately* before `(` —
  not a semantic class: calls, constructor calls and method declarations all
  land there; whitespace before `(` makes it `plain`; a keyword wins (`if(x)`).
- `string` is not a whole literal: escapes and interpolations are cut out, and
  the inside of `${…}` comes back as ordinary kinds. That is why there is no
  `interpolation` kind ("there is nothing for it to do").
- `escape` is a backslash and one following character, never in a raw string.
- `DartToken.text` is a slice of the source, never rewritten.

## Code

- `lib/src/tokenizer/dart_tokenizer.dart — DartTokenKind`, `DartToken`
- `lib/flutter_syntax_highlight.dart` — exports the tokenizer library.

## Reference behaviour

- `dart-lang/dart-syntax-highlight` (the official Dart TextMate grammar),
  read as an example per `docs/agents/thegraph.md`: its type rule
  `[_$]*[A-Z][a-zA-Z0-9_$]*` is the guess ADR-0001 rejected.
- The nine-theme survey, issue #3 (2026-09-05), settles which distinctions
  themes actually paint.

## Cross-cutting invariants

- [eight-kinds](../invariant/eight-kinds.md)

## Blast radius

- [dart-scanner](dart-scanner.md) — every kind is emitted by some branch; a
  kind with no branch never appears, and a changed definition (what counts as
  `function`) is a scanner change.
- [palette](palette.md) — eight fields and an exhaustive `styleFor` assume this
  exact list.
- [derived-default](derived-default.md) and [named-presets](named-presets.md) —
  each assigns a look to every kind; a new kind is undrawn there.
- [publishing](publishing.md) — a changed list is a breaking release, and the
  README kind table describes it.

## Known holes / open

**None.**
