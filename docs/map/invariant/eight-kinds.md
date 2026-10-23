# Eight kinds

## The fact

`DartTokenKind` has exactly eight values — `plain comment keyword string number
punctuation escape function` — and every place that maps a kind to a look
enumerates all eight. Adding or removing one is a breaking change after
publication ([ADR-0001](../../adr/0001-token-kinds-are-lexical-only.md),
*이 목록은 사실상 영구적이다*).

## Why it is cross-cutting

The enum and the places that enumerate it do not share a primitive that would
carry an addition: `SyntaxPalette` holds eight named fields, not a map keyed by
kind (GLOSSARY.md, *Palette*, records why: a map would let a missing slot pass
as null). Only `styleFor`'s exhaustive `switch` turns an addition into a
compile error; the fields, `==`, `hashCode`, the constructor, every preset and
the derived default would silently lack the new slot. Outside this repo, the one
known consumer switches exhaustively too, so an addition breaks its build.

## Territories it holds in

Tool-visible half — `git grep -n 'DartTokenKind\.' -- lib test` lists the
sites that name kinds; it does not list the field-per-kind sites below.

Hand-written half:

- [token-kinds](../territory/token-kinds.md) — `dart_tokenizer.dart —
  DartTokenKind`, the list itself.
- [palette](../territory/palette.md) — `syntax_palette.dart — SyntaxPalette`:
  the eight `TextStyle?` fields, the constructor, `==`, `hashCode`, `styleFor`.
- [derived-default](../territory/derived-default.md) —
  `SyntaxPalette.fromColorScheme`, which deliberately leaves `plain` null.
- [named-presets](../territory/named-presets.md) — each `_solarizedDark` …
  `_cobalt2` const in `syntax_presets.dart` fills all eight.
- Outside the repo: `flutter_example_template` @ `5b18424` (2026-10-23),
  `lib/src/shell/code_pane.dart — _CodeState._styleFor`, an exhaustive
  `switch (kind)` over all eight (maintainer, 2026-10-23: the only consumer).

## What a violation looks like

A ninth kind compiles in the tokenizer, fails `styleFor` — and once that one
case is added, every preset draws the new kind in the root style, the derived
default too, two palettes differing only in it compare equal, and the consumer
stops compiling on `pub upgrade`.

## Discovery history

- Fixed at eight by ADR-0001 after the theme survey (#3, 2026-09-05) and the
  decision (#5).
- `styleFor`'s exhaustiveness was chosen as the alarm, and the palette's
  "plain Map" description was corrected to named fields (GLOSSARY.md,
  *Palette*; commit `76ef1e4`, 2026-09-06).
- `test/widget/syntax_palette_test.dart`, `styleFor의 배선` — each kind reaches
  its own field.

## Where it will recur

Anything that wants a finer distinction (type vs variable, annotation,
operator, interpolation — all rejected in ADR-0001) or any new field on
`SyntaxPalette`. A new field that is *not* a kind, as `background` was, is not
breaking (ADR-0002, *breaking change가 아니다*) — the question to ask is whether
the new thing is a kind.
