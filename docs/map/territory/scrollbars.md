# Scrollbars

## What it is

The Material `Scrollbar`s `SyntaxText` draws over its two scroll views, and how
their behaviour, placement and colour are decided between the widget, the app's
`ScrollbarThemeData` and the palette.

## Governing decisions

- [ADR-0004](../../adr/0004-the-widget-fills-only-the-scrollbar-fields-nobody-set.md)
  — whoever a value was chosen against owns it: the palette owns thumb colour
  (under a background), the app owns behaviour and shape, the widget fills only
  what nobody set; Android only; insets removed on both bars (#31); desktop's
  duplicate vertical bar removed (#32).

## Design model

From ADR-0004 and `_SyntaxTextState.build` comments:

- **Android fill**: if the app theme leaves `thumbVisibility` / `interactive`
  null, the *horizontal* bar gets `true` as widget parameters — not as theme,
  which would also force the vertical bar visible. An app's `false` wins, and
  then Android touch users cannot scroll sideways. `interactive` also turns on
  track taps (one page per tap), accepted by the maintainer (2026-10-19).
- **Horizontal bar outside the vertical view** with
  `notificationPredicate: depth == (scrollable ? 1 : 0)`, so it sits at the
  widget's bottom, not after the last line.
- **Insets removed around the bars only** (`insetFree`): Material's
  `Scrollbar` feeds `MediaQuery.paddingOf` to its painter with no opt-out
  (Flutter 3.41.9). The code inside gets the original `MediaQuery` back, for
  selection toolbars and handles. Read inside a `Builder` so keyboard
  animation does not rebuild the whole widget.
- **Desktop duplicate**: the vertical view is wrapped in
  `ScrollConfiguration.of(context).copyWith(scrollbars: false)` — a copy of the
  app's behaviour, not a new one. `EditableText`'s own bar is kept (it re-enables
  itself; visible only for `scrollable: false` in a bounded height).
- **Colour only**: under a background, `ScrollbarTheme(data:
  bars.copyWith(thumbColor: …))` merges onto the app's theme instead of
  replacing it.
- System gesture areas are the app's job (`SafeArea`); the widget does not
  read `systemGestureInsets`.

## Code

- `lib/src/widget/syntax_text.dart — _SyntaxTextState.build`: `insetFree`,
  both `Scrollbar`s, `ScrollConfiguration`, `bars`, `android`, the final
  `ScrollbarTheme`.
- Tests: `test/widget/syntax_text_test.dart` groups `가로 스크롤바는 터치에서
  끌린다`, `스크롤바는 화면 inset이 아니라 위젯 영역을 따른다`, `데스크톱에서
  세로 바는 하나다`.

## Reference behaviour

- Flutter 3.41.9 `material/scrollbar.dart — updateScrollbarPainter` (inset
  feed) and `widgets/editable_text.dart` (`copyWith(scrollbars:
  _isMultiline)`), as read in ADR-0004.
- Emulator measurements (Medium Phone API 36.1, 2026-10-19) in ADR-0004.

## Cross-cutting invariants

- [colour-owner-sets-the-ground](../invariant/colour-owner-sets-the-ground.md)

## Blast radius

- [scroll-axes](scroll-axes.md) — the depth predicate and bar placement assume
  the current nesting of views.
- [wheel-glide](wheel-glide.md) — a wheel over a bar glides because the bar
  shares the view's controller.
- [publishing](publishing.md) — scrollbar behaviour is consumer-visible and
  documented in README and CHANGELOG.

## Known holes / open

- iOS: the horizontal bar measured 0.0 when dragged in widget tests; not
  measured on simulator or device; Cupertino gestures differ. Tracked: #30.
- Other non-Android platforms with a hidden thumb and selection-owned drags
  were not measured (ADR-0004).
- `interactive: true` brings track taps with no separate switch in Material.
