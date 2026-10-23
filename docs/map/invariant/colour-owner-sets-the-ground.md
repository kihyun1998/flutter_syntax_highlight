# Colour owner sets the ground

## The fact

Whoever chose a colour also decides what it sits on. Colours the app chose
(the derived default) sit on the app's own surface, so the palette carries no
`background`. Colours an upstream theme chose (a named preset) sit on that
theme's background, so the palette carries it — and carries `plain` with it.
When a palette carries a background, the widget's own controls take their
colour from the palette, not from the app's theme, and only their colour.

Stated as one rule in [ADR-0002](../../adr/0002-a-palette-carries-its-own-background.md),
extended in [ADR-0003](../../adr/0003-the-derived-default-borrows-the-app-s-accent-diluted.md)
(*같은 규칙이다*) and narrowed to colour in
[ADR-0004](../../adr/0004-the-widget-fills-only-the-scrollbar-fields-nobody-set.md).

## Why it is cross-cutting

Three sites decide their half independently, and none calls the others:

- the derived default omits `background` and `plain`;
- each preset sets `background` and `plain`;
- the widget reads `palette.background` and switches the root text colour's
  surroundings — the copy icon colour (`chrome`, `chromeStrong`) and the
  scrollbar thumb colour — to palette colours.

A preset that sets a background without `plain` leaves the root colour
`ColorScheme.onSurface`, chosen against a surface that is no longer behind it.
A widget that themed its controls from the app under a preset buries them in a
foreign background.

## Territories it holds in

- [derived-default](../territory/derived-default.md) —
  `SyntaxPalette.fromColorScheme` leaves `background` and `plain` unset.
- [named-presets](../territory/named-presets.md) — every const in
  `syntax_presets.dart` sets both.
- [code-rendering](../territory/code-rendering.md) — `_SyntaxTextState.build`:
  `ColoredBox` only when `background != null`; root `color: scheme.onSurface`;
  `chrome`/`chromeStrong`.
- [copy-control](../territory/copy-control.md) — the icon colour comes from
  `chrome`/`chromeStrong`.
- [scrollbars](../territory/scrollbars.md) — `ScrollbarTheme(data:
  bars.copyWith(thumbColor: …))` only under a background.

## What a violation looks like

`oneDark` in a light app with letters in One Dark colours on the app's light
surface (the original defect, found on #21's screenshot); or a copy button and
thumb invisible on a dark preset in a light app; or, before #29, a preset that
replaced the app's whole `ScrollbarThemeData` to change one colour, turning the
app's Android opt-in into 0.0 (ADR-0004, *Context*).

## Discovery history

- The absent `background` field made a contrast of 1.00 for `cobalt2` read as
  a property of presets; measured against its own `#193549` it is 12.75
  (ADR-0002, 2026-09-07; commit `9cc268c`).
- ADR-0004 (#29, 2026-10-19) found the "controls follow the palette" sentence
  implemented as a whole-theme replacement, and narrowed it to colour.
- Tests: `test/widget/presets_test.dart` group `배경`;
  `test/widget/syntax_text_test.dart` `복사 아이콘이 앱 테마가 아니라 팔레트를
  따라간다`, `배경 있는 프리셋이 앱의 스크롤바 테마를 지우지 않는다`.

## Where it will recur

Any new palette (a preset, a consumer's constructor call), and any new
widget-drawn control (a button, a gutter, a selection colour): "does this
colour have to read against whatever `palette.background` is?" README, *Writing
your own*, tells consumers the `plain` half.
