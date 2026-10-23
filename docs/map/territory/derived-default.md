# Derived default

## What it is

`SyntaxPalette.fromColorScheme`, the palette `SyntaxText` uses when none is
passed. It derives every style from the app's `ColorScheme` and introduces no
hue of its own, so it is right in light and dark with nothing to configure.

## Governing decisions

- [ADR-0003](../../adr/0003-the-derived-default-borrows-the-app-s-accent-diluted.md)
  — `string`/`escape` pulled from `onSurfaceVariant` towards `tertiary`,
  `function` from `onSurface` towards `primary`, both by 0.70; `number` and
  `punctuation` not pulled. Reverses one acceptance criterion of #17.
- [ADR-0002](../../adr/0002-a-palette-carries-its-own-background.md) — gives
  no `background`.

## Design model

From ADR-0003 and the `fromColorScheme` comments:

- **Hue-neutral**: every colour is a neutral role (`onSurfaceVariant`,
  `outline`; `onSurface` via the root) or a neutral role lerped part-way to
  `primary`/`tertiary`. A monochrome scheme yields a monochrome palette.
- **Comments are not dimmed** — italic, full contrast; `punctuation` recedes to
  `outline`; `keyword` is `w600`. Reason: a comment is the one part not
  recoverable from the code (`SyntaxPalette` class doc).
- `_accentMix = 0.7` was chosen by a ΔE (CIE Lab) sweep over 12 hues × light and
  dark (2026-09-07): new distinctions all fall between ΔE 9.9 (barely visible)
  and 29.9 (clearly visible). Contrast ratio was not the constraint, and could
  not measure the change.
- Tests check the *property*, not the coefficient: pulled colours lie between
  anchor and target (ADR-0003, *계수를 값으로 못 박지 않는다*).
- `plain` and `background` are left unset.

## Code

- `lib/src/widget/syntax_palette.dart — SyntaxPalette.fromColorScheme`,
  `SyntaxPalette._accentMix`, `SyntaxPalette._towards`
- Tests: `test/widget/syntax_palette_test.dart` group `fromColorScheme — …`;
  `test/widget/derived_sweep_test.dart` (the hue-circle sweep).

## Reference behaviour

- The nine-theme survey (#3) — 9/9 themes colour call names, which is why
  `function` is pulled.
- The preset survey (#9) — 4 of 10 colour `escape` like `number`, which is why
  `escape` follows `string` instead of standing apart.

## Cross-cutting invariants

- [eight-kinds](../invariant/eight-kinds.md)
- [colour-owner-sets-the-ground](../invariant/colour-owner-sets-the-ground.md)
- [one-face-at-the-root](../invariant/one-face-at-the-root.md)

## Blast radius

- [code-rendering](code-rendering.md) — the widget's root colour
  `scheme.onSurface` is this palette's `plain`; changing either alone changes
  plain code's colour.
- [example-app](example-app.md) — its seed swatches (including the monochrome
  one) are the visual demonstration of hue-neutrality; README screenshots show
  this palette.
- [publishing](publishing.md) — a visible change here is a minor-version bump
  (0.2.0 was one, ADR-0003 *Consequences*) and the screenshots go stale.

## Known holes / open

- Two source texts still say the derived default reads only three roles:
  `SyntaxPalette`'s class doc (*기본값은 소비자의 `ColorScheme`에서 파생된다*)
  and GLOSSARY.md (*색상을 더하지 않는다*). Since ADR-0003 it also reads
  `primary` and `tertiary`.
