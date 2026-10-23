# One face at the root

## The fact

The monospace face is named once, on the root style passed to
`SelectableText.rich`, and every token inherits it. No `TextStyle` a palette
produces sets `fontFamily` or `fontFamilyFallback`.

## Why it is cross-cutting

The widget names the face; the palettes — derived, preset, or a consumer's own
— supply the leaf styles that merge under it. They never call each other. A leaf
that names a family wins over the root for its span, while a guard that reads
the outer `EditableText.style` stays green (`syntax_palette.dart —
SyntaxPalette` class doc, *No style specifies `fontFamily`*: "This is a
hard rule"). So the root-side rule and the leaf-side rule must both hold.

## Territories it holds in

- [monospace-face](../territory/monospace-face.md) — `_SyntaxTextState.build`
  root `TextStyle(fontFamily: family, fontFamilyFallback: …)`.
- [palette](../territory/palette.md) — the rule is stated on `SyntaxPalette`.
- [derived-default](../territory/derived-default.md) — `fromColorScheme`
  styles carry no family.
- [named-presets](../territory/named-presets.md) — no preset const carries a
  family.

## What a violation looks like

Keywords or strings drawn in the app's proportional font, columns no longer
aligned, with the widget-level font tests still green.

## Discovery history

- Tests on both sides: `test/widget/syntax_palette_test.dart` group `no style specifies a fontFamily`; `test/widget/presets_test.dart` `no preset names a fontFamily`; `test/widget/syntax_text_test.dart`
  `and no leaf brings in a family of its own`.

## Where it will recur

Any new palette or preset, and any per-kind style that reaches for a font —
an italic comment face, a "code ligatures" option. A consumer's own
`SyntaxPalette` is outside every test; README does not warn about it.
