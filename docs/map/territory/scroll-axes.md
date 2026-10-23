# Scroll axes

## What it is

Which scroll views `SyntaxText` builds and owns. Horizontal scrolling is always
on and not a parameter, because code never wraps; `scrollable` governs the
vertical axis only (`false` shrink-wraps for a block in prose, `true` scrolls
in its own box). Both controllers are named and owned by the widget.

## Governing decisions

**None** for the axes themselves; the rules are in the `SyntaxText` class doc.
[ADR-0004](../../adr/0004-the-widget-fills-only-the-scrollbar-fields-nobody-set.md)
governs the bars drawn over them.

## Design model

From the `SyntaxText` class doc, measured where marked:

- **A wrapped line is a different line**, so horizontal scroll is never
  negotiable.
- **Named controllers** so each `Scrollbar` has an unambiguous target. The
  reference's other reason (two views claiming `PrimaryScrollController`
  assert) was measured false, 2026-09-06.
- **Horizontal drag over text does not scroll** — the selection gesture takes
  it. Measured 2026-09-06 (300×300, 120 px drag): `SelectableText` and
  `SelectionArea` 0.0 horizontal, plain `Text` 100.0. Hence the horizontal
  scrollbar is the only horizontal affordance on touch.
- Nesting: horizontal `SingleChildScrollView` inside, vertical outside it when
  `scrollable`; the horizontal bar is outside both (see scrollbars).

## Code

- `lib/src/widget/syntax_text.dart — SyntaxText.scrollable`;
  `_SyntaxTextState._vertical`, `_horizontal`; the `SingleChildScrollView`s in
  `build`.
- Tests: `test/widget/syntax_text_test.dart` groups `스크롤`, `스크롤이 실제로
  움직인다`.

## Reference behaviour

**None.**

## Cross-cutting invariants

**None.**

## Blast radius

- [scrollbars](scrollbars.md) — each bar tracks one of these controllers, and
  the horizontal bar's `notificationPredicate` depth assumes this nesting.
- [wheel-glide](wheel-glide.md) — both controllers are
  `SmoothScrollController`s; replacing a controller loses position.
- [code-rendering](code-rendering.md) — the background and copy `Stack` wrap
  these views and must stay outside them.

## Known holes / open

**None.**
