# Named presets

## What it is

The ten `SyntaxPalette` constants excerpted from third-party editor themes —
`solarizedDark/Light`, `oneDark/Light`, `gruvboxDark/Light`,
`tokyoNight/Light`, `monokai`, `cobalt2` — with the attribution that ships with
them in `NOTICES`, and the record of themes deliberately left out.

## Governing decisions

- [ADR-0002](../../adr/0002-a-palette-carries-its-own-background.md) — each
  preset carries the background its colours were chosen on, and `plain` with
  it; themes with an upstream counterpart ship as a brightness pair, for taste
  rather than legibility.

## Design model

From the preset doc comments, `NOTICES` and ADR-0002:

- **An excerpt, not a reproduction**: the colours the original gave the scopes
  matching our eight kinds, plus its editor background. Values are binding on
  their upstreams (`docs/agents/thegraph.md`): a value that differs from the
  pinned source is a bug, including ones that look wrong (`tokyoNightLight`'s
  `escape` near its `plain`, kept "because the original defines it").
- **Never mix value sets**: gruvbox comes from the MIT port only, at the cost of
  two slots' fidelity to the unlicensed original.
- **Names avoid live marks**: `oneDark`, not `atomOneDark` (ATOM, US Reg.
  4,819,136, checked on mirrors, not the register). Dracula, Nord, GitHub,
  Everforest and Monokai Pro are excluded with reasons in `NOTICES`.
- Data lives in `syntax_presets.dart` (a `part`), declarations in
  `SyntaxPalette`, because the two change for different reasons (that file's
  header).
- Measured body contrast on own background 4.13 (`solarizedLight`) – 13.94
  (`monokai`), 2026-09-07; the floor is upstream's.

## Code

- `lib/src/widget/syntax_presets.dart — _solarizedDark … _cobalt2`
- `lib/src/widget/syntax_palette.dart — SyntaxPalette.solarizedDark …
  SyntaxPalette.cobalt2`
- `NOTICES` (shipped; checked by `test/widget/presets_test.dart` group
  `NOTICES`, which also checks the archive includes it).
- Tests: `test/widget/presets_test.dart` (count, shape, backgrounds, ≥ 4.1
  contrast, survey facts: escape = number in exactly four, only monokai
  non-italic comments, four pairs).

## Reference behaviour

- Each upstream at the commit `NOTICES` pins — binding
  (`docs/agents/thegraph.md`). The `NOTICES` *Backgrounds* section records
  where each background was read.
- The preset survey, issue #9.

## Cross-cutting invariants

- [eight-kinds](../invariant/eight-kinds.md)
- [colour-owner-sets-the-ground](../invariant/colour-owner-sets-the-ground.md)
- [one-face-at-the-root](../invariant/one-face-at-the-root.md)

## Blast radius

- [publishing](publishing.md) — `NOTICES` must ship and stay in step with the
  values; README's preset table and screenshot name them.
- [example-app](example-app.md) — the picker lists all ten by hand; a new
  preset is missing there until added.
- [scrollbars](scrollbars.md) and [copy-control](copy-control.md) — their
  colours come from a preset's `comment`/`plain` when it carries a background.

## Known holes / open

- `syntax_presets.dart`'s header comment still says named presets "break in the
  opposite brightness, so they ship as pairs". ADR-0002 replaced that reason
  (legible on their own background; pairs are for taste).
- The preset list is written by hand in three places with no lookup to derive
  them from: `test/widget/presets_test.dart — presets`,
  `example/lib/main.dart — palettes`, and README's preset table. A preset
  added without the test entry ships having passed none of the preset checks
  (that test's own doc says so).
- Trademark lines rest on second-hand searches; tsdr.uspto.gov was unreachable
  (`NOTICES`).
