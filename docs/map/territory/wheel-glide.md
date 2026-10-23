# Wheel glide

## What it is

Mouse-wheel scrolling that animates each notch to its target instead of
jumping, on both axes, through `flutter_smooth_wheel_scroll`. `wheelMotion`
picks the motion; `null` moves at once.

## Governing decisions

**None.** Introduced by #26/#27 (commits `ba491f3`, `82e8a29`, 2026-10-17); the
rules are in the `SyntaxText.wheelMotion` doc and the class doc *마우스 휠은
미끄러진다*.

## Design model

From source only:

- Both controllers are `SmoothScrollController`s; scrollbars share them, so a
  wheel over a bar glides too. Shift+wheel moves sideways.
- Only the wheel animates; drag, scrollbar drag, keyboard and trackpad move at
  once and stop any running motion.
- `null` maps to a zero-duration spring (`_instant`) rather than a different
  controller, because swapping controllers loses position. Changing
  `wheelMotion` keeps the position and applies from the next notch
  (`didUpdateWidget`).
- Distance per notch is app-wide (`SmoothWheelBinding`), not per widget.
- `WheelMotion` is re-exported from the package barrel so consumers need no
  direct dependency.

## Code

- `lib/src/widget/syntax_text.dart — SyntaxText.wheelMotion`;
  `_SyntaxTextState._vertical`, `_horizontal`, `_instant`, `_motion`,
  `didUpdateWidget`, `dispose`.
- `lib/flutter_syntax_highlight.dart` — `export … show WheelMotion`.
- Tests: `test/widget/syntax_text_test.dart` groups `마우스 휠은 미끄러진다`,
  `wheelMotion`.

## Reference behaviour

**None.**

## Cross-cutting invariants

**None.**

## Blast radius

- [publishing](publishing.md) — the dependency sets the SDK floor (Flutter
  3.32 / Dart 3.8, a breaking change in 0.3.0) and is re-exported as public API.
- [scroll-axes](scroll-axes.md) — owns the controllers this territory types.

## Known holes / open

**None.**
