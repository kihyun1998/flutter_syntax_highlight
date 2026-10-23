# Palette

## What it is

`SyntaxPalette`, the policy side of the seam: how each kind looks. A value type
of eight optional `TextStyle`s plus an optional `background`, with `styleFor`
mapping a kind to its style. Not a theme engine — no registry, no lookup by
name, no colour computation beyond the derived factory.

## Governing decisions

- [ADR-0001](../../adr/0001-token-kinds-are-lexical-only.md) — the eight slots
  are the eight kinds.
- [ADR-0002](../../adr/0002-a-palette-carries-its-own-background.md) — the
  `background` field, and why adding it was not breaking.

## Design model

From the `SyntaxPalette` doc comments and the ADRs:

- A slot left null inherits the root style; `plain` null means "the widget's
  root colour" (`scheme.onSurface`).
- Named fields and an exhaustive `switch` in `styleFor`, not a map: a new kind
  must fail to compile here (GLOSSARY.md, *Palette*).
- `background` is not a kind: it is where the glyphs sit, so it stays out of
  `styleFor`.
- Value equality over all nine fields (`==`, `hashCode`), and `const`
  constructible.
- No style names a font family — see the invariant below.
- No lookup by name: an app offering a picker writes its own list (README,
  *Named presets*; `example/lib/main.dart — palettes`).

## Code

- `lib/src/widget/syntax_palette.dart — SyntaxPalette` (constructor, fields,
  `==`, `hashCode`, `styleFor`); `part 'syntax_presets.dart'` holds preset data.
- Tests: `test/widget/syntax_palette_test.dart` groups `wiring of styleFor`, `value equality`, `building your own`.

## Reference behaviour

**None.**

## Cross-cutting invariants

- [eight-kinds](../invariant/eight-kinds.md)
- [one-face-at-the-root](../invariant/one-face-at-the-root.md)

## Blast radius

- [derived-default](derived-default.md) and [named-presets](named-presets.md) —
  both construct this type; a new field is unset in each until written.
- [code-rendering](code-rendering.md) — reads `styleFor` per token and
  `background` to decide whether to paint and how to colour its controls.
- [example-app](example-app.md) — its picker list is the documented substitute
  for a lookup by name.

## Known holes / open

**None.**
