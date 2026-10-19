# Changelog

## 0.4.0

On Android, the horizontal scrollbar of `SyntaxText` can now be dragged. Before
this, touch users there had no way to scroll sideways: dragging over the text
selects it, and the scrollbar was hidden and ignored drags.

- On Android, the horizontal scrollbar is always shown and draggable, unless
  your app's `ScrollbarThemeData` sets `thumbVisibility` or `interactive`. A
  value you set wins, even `false`. The vertical scrollbar is unchanged, and
  other platforms are unchanged.
- Because the bar is now interactive on Android, tapping along it also pages
  the code sideways. Flutter's scrollbar cannot allow dragging without that.
- With `scrollable: true`, the horizontal scrollbar is now drawn at the bottom
  of the widget on every platform, instead of after the last line of code.
- A palette with a background no longer replaces your app's scrollbar theme. It
  sets only the thumb color, and keeps the rest of your `ScrollbarThemeData`.

## 0.3.0

`SyntaxText` now glides on a mouse wheel instead of jumping a notch at a time.

**Breaking: the SDK floor is now Flutter 3.32 / Dart 3.8** (was 3.27 / 3.6). The
wheel motion comes from
[`flutter_smooth_wheel_scroll`](https://pub.dev/packages/flutter_smooth_wheel_scroll),
which needs that floor. On Flutter 3.27–3.31, stay on 0.2.0.

- A wheel notch animates to its target with a spring, and notches during the
  motion add to the target. It never passes the start or end of the code.
  Shift+wheel moves sideways the same way, and a wheel turned over the
  scrollbar glides too, because the scrollbar shares the view's controller.
- Dragging, dragging the scrollbar, the keyboard and the trackpad move exactly
  as before.
- `wheelMotion` picks the motion: `WheelMotion.spring` (the default),
  `.curve` or `.lerp`, or `null` to move at once. It applies to both axes, and
  changing it keeps the scroll position.
- `WheelMotion` is exported from this package, so you do not need to depend on
  `flutter_smooth_wheel_scroll` yourself to pass one.
- How far a notch travels is app-wide and not set here — use
  `SmoothWheelBinding` from `flutter_smooth_wheel_scroll` in your `main()`.
- The example gained a wheel demo: a code block longer and wider than the
  window, with a picker for the motion.

## 0.2.0

The palette derived from your `ColorScheme` now borrows your app's accent, in
two places, diluted. Nothing else changed; the tokenizer is untouched.

- `string` (and `escape`, which follows its literal) is pulled from
  `onSurfaceVariant` towards `tertiary`; `function`, which had no style at all,
  is pulled from `onSurface` towards `primary`. `number` and `punctuation` stay
  where they were, so the literals gain a distinction between them.
- It still introduces no hue of its own — every colour is a neutral role from
  your scheme or a neutral role mixed with one of your scheme's accents, and a
  monochrome scheme still yields a monochrome palette.
- How far to pull was measured over the whole hue circle in both brightnesses,
  against two scales this palette already contained. See
  `docs/adr/0003-the-derived-default-borrows-the-app-s-accent-diluted.md`.
- The example gained a seed picker, so the derivation is visible rather than
  merely claimed.

Named presets are unchanged. If you pass one, or your own `SyntaxPalette`,
nothing about this release affects you.

## 0.1.0

First release.

### Tokenizer

- `tokenizeDart(String source)` returns a `List<DartToken>` whose texts
  concatenate back to the input, byte for byte. Tokens are cut at recorded
  offsets and never rebuilt, so CRLF and letter case survive unchanged.
- The file imports nothing — not Flutter, not `dart:*` — and a test fails if
  that ever stops being true.
- Eight kinds, every one decidable by scanning characters left to right:
  `plain`, `comment`, `keyword`, `string`, `number`, `punctuation`, `escape`,
  `function`. Distinctions that need a parser are deliberately absent; the
  reasoning is in `docs/adr/0001-token-kinds-are-lexical-only.md`.
- The inside of `${...}` is scanned recursively with the same rules as the
  outside, so a string nested in an interpolation comes back out as a string.
  Nested block comments, raw strings, triple-quoted strings, and unterminated
  strings and interpolations are each handled, the last two by stopping at the
  end of the line.

### Widget

- `SyntaxText(source, {palette, copyable, scrollable, fontFamily,
  fontFamilyFallback, fontSize, height, padding, copyTooltip, copiedTooltip})`
  draws selectable, copyable code. It takes a string, not an asset key, so it
  has no loading state.
- Horizontal scrolling is always owned by the widget — code does not wrap.
  `scrollable` governs the vertical axis only.
- `SyntaxPalette` holds one optional `TextStyle` per kind plus an optional
  `background`. `SyntaxPalette.fromColorScheme` derives the default from the
  consumer's `ColorScheme` without introducing a hue of its own, and paints no
  background, so it is right in light and dark with nothing to configure.
- Ten named presets — `solarizedDark`, `solarizedLight`, `oneDark`, `oneLight`,
  `monokai`, `gruvboxDark`, `gruvboxLight`, `tokyoNight`, `tokyoNightLight`,
  `cobalt2` — each an excerpt of an MIT-licensed upstream theme, carrying the
  background its colours were chosen against. Provenance, pinned commit by
  pinned commit, is in `NOTICES`.
