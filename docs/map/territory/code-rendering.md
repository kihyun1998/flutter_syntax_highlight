# Code rendering

## What it is

How `SyntaxText` turns tokens into a selectable picture: it tokenizes once per
`source`, builds one `TextSpan` per token styled by the palette, sets the root
style, paints the palette's background, and works out the colour of its own
controls. It takes a source string, not an asset key — no loading state, no
failure screen.

## Governing decisions

- [ADR-0002](../../adr/0002-a-palette-carries-its-own-background.md) — paint
  the background outside the `Stack`; controls follow the palette under a
  background.
- [ADR-0004](../../adr/0004-the-widget-fills-only-the-scrollbar-fields-nobody-set.md)
  — narrows "controls follow the palette" to colour.

## Design model

From the `SyntaxText` class doc and `_SyntaxTextState` comments:

- **Tokens are cached in state** (`_tokens`), re-scanned only when `source`
  changes, not on theme or brightness change. This avoids re-scans only:
  `SelectableText` still deep-compares a fresh span tree each build. No test
  can fail without the cache (stated in its doc).
- **Root span carries no text**; `SelectableText.rich` wraps it with the root
  `style`, which is what every token inherits and what `EditableText.style`
  reports.
- **Root colour is `scheme.onSurface`**; a palette that leaves `plain` null
  draws plain code in it.
- **`ColoredBox` sits outside the `Stack`** (loose `fit` would shrink it to the
  content), so it fills a tight pane and shrinks with `scrollable: false`.
- **`chrome`/`chromeStrong`**: with no background, `onSurfaceVariant` and
  `onSurface`; with one, the palette's `comment`/`plain` colours.
- **No line numbers** — a placeholder gutter puts `\u{FFFC}` in every copied
  line, and `SelectableText` does not assert `TextSpan` children.

## Code

- `lib/src/widget/syntax_text.dart — SyntaxText` (fields, class doc),
  `_SyntaxTextState.initState`, `didUpdateWidget`, `build` (span tree, root
  style, `ColoredBox`, `chrome`).
- Tests: `test/widget/syntax_text_test.dart` groups `the highlighter cannot change what gets pasted`, `the palette is actually drawn — read from the leaves, not the object`, `background`, `re-tokenizes when source changes`, `values the consumer passes are actually used`.

## Reference behaviour

**None.**

## Cross-cutting invariants

- [pasted-bytes-are-the-input](../invariant/pasted-bytes-are-the-input.md)
- [colour-owner-sets-the-ground](../invariant/colour-owner-sets-the-ground.md)

## Blast radius

- [dart-scanner](dart-scanner.md) — rendering cost assumes merged runs; a
  scanner that stops merging multiplies spans and per-build comparisons.
- [monospace-face](monospace-face.md) — the root style built here is where the
  face is named.
- [scroll-axes](scroll-axes.md) — the span tree is wrapped by the scroll views
  built in the same `build`; the background must stay outside them.
- [copy-control](copy-control.md) and [scrollbars](scrollbars.md) — both take
  `chrome` colours computed here.

## Known holes / open

- The token cache is unguarded by any test (by design, see its doc); removing it
  is invisible to the suite.
