# Changelog

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
