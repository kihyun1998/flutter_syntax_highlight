# flutter_syntax_highlight

Syntax highlighting for **Dart source**, in two layers: a pure-Dart tokenizer
underneath and a thin widget on top. The tokens rejoin into the exact input,
byte for byte.

|                          Light                          |                         Dark                          |
| :-----------------------------------------------------: | :---------------------------------------------------: |
| ![Light](https://raw.githubusercontent.com/kihyun1998/flutter_syntax_highlight/main/screenshots/light.png) | ![Dark](https://raw.githubusercontent.com/kihyun1998/flutter_syntax_highlight/main/screenshots/dark.png) |

Look at `'${value ? '✓' : '✗'}'` on the `return` line: the nested `'✓'` and
`'✗'` are drawn as strings, and the conditional around them as code.

```yaml
dependencies:
  flutter_syntax_highlight: ^0.1.0
```

```dart
import 'package:flutter_syntax_highlight/flutter_syntax_highlight.dart';

SyntaxText(sourceCode)
```

## 1. Two layers, and you may take just one

**The lower layer is a tokenizer.** `tokenizeDart(String source)` returns a
`List<DartToken>`, each a slice of the source plus a `DartTokenKind`.

```dart
for (final token in tokenizeDart(source)) {
  print('${token.kind.name}: ${token.text}');
}
```

This file imports **nothing** — not Flutter, not `dart:*`. So it runs in a
server, in a CLI, in a build step, and it is tested with plain `test()` calls,
no widget and no pump.

**The upper layer is a widget.** `SyntaxText` takes a `String` and draws it as
selectable, copyable code.

```dart
SyntaxText(
  source,
  palette: SyntaxPalette.solarizedDark,
  scrollable: false,
)
```

**One seam holds them apart.** The tokenizer decides *what* a kind is; the
widget decides *how* a kind looks. The moment a tokenizer knows about `Color`,
nothing about it can be checked without rendering.

## 2. Dart only, and deliberately coarse

Both halves of that are decisions, not gaps.

**Dart only.** The scanner is written by hand against Dart's lexical grammar —
its nested block comments, its raw strings, its recursive interpolation. There
is no grammar table to swap out, and a second hand-written scanner per language
is exactly the shape this package exists to avoid.

**Deliberately coarse.** There are eight kinds:

`plain` · `comment` · `keyword` · `string` · `number` · `punctuation` ·
`escape` · `function`

Finer distinctions that other tools draw — type versus variable, method call
versus field access — are **not** here. Telling a type from a variable needs a
parser; a scanner can only guess from a capital letter, and that guess is wrong
on `const PI`, on enum values, on generic parameters. A half-right answer about
what a name *means* is worse than no answer, because the reader believes it.

Every kind that is here is decidable by looking at characters left to right. A
backslash and the character after it is an escape. An identifier immediately
before `(` is a name at a call site — function call, constructor call and method
declaration all land there, and the scanner does not tell those apart. The
reasoning, including the four distinctions that were considered and rejected, is
in [`docs/adr/0001-token-kinds-are-lexical-only.md`](docs/adr/0001-token-kinds-are-lexical-only.md).

## 3. The tokens rejoin into the input

`tokenizeDart` returns a **partition**. Concatenate every token's text in order
and you have the input back, byte for byte. That is the property, and it is one
line to state:

```dart
expect(tokenizeDart(source).map((t) => t.text).join(), source);
```

It holds by construction rather than by care. The scanner records end offsets
into the source; a token's text is always `source.substring(previousEnd, thisEnd)`,
and ends increase monotonically. There is no path along which a character is
dropped, duplicated or rewritten, because nothing is ever rebuilt.

Two consequences worth naming:

- **CRLF survives.** Line endings are a property of a checkout, not of a
  repository, and a library handed arbitrary consumer source has no standing to
  normalise them.
- **Case survives.** Keyword matching never emits a lower-cased form.

So the text on screen is the text you passed in, and what a reader copies out of
it runs.

## 4. Interpolation is scanned recursively

The inside of `${...}` is re-scanned with the same rules as the outside, so a
string nested inside an interpolation comes back out as a string. These three
lines tokenize like this:

```dart
final text = '${newValue ?? ''}'.trim();
final rows = 'selectedRows: ${selected.join(', ')}';
return '${value ? '✓' : '✗'} $key';
```

The last of those is fifteen tokens. Pipes mark each one's edges, so the
whitespace is visible too — it is part of the partition, not a gap between
tokens:

```text
keyword      |return|
plain        | |
string       |'|
punctuation  |${|
plain        |value |
punctuation  |?|
plain        | |
string       |'✓'|
plain        | |
punctuation  |:|
plain        | |
string       |'✗'|
punctuation  |}|
string       | $key'|
punctuation  |;|
```

A string literal is therefore **not** one token. `'a\n'` is three — `'a`, `\n`,
`'` — and a literal containing interpolation is as many as its contents need.
The kinds are still correct at every offset, and §3 still holds: the pieces
rejoin.

Note the second-to-last token. A bare `$key` stays inside the literal; only
`${...}` opens a re-scan. Dart's `$identifier` form can hold nothing but an
identifier, so there is no nesting to get wrong there.

The same recursion covers the boundaries that are easy to run past:

- `/* /* */ */` — Dart nests block comments; the first `*/` does not end it.
- `// somebody's problem` — an apostrophe in a comment opens nothing.
- `r'a\'` — in a raw string a backslash is just a character.
- `'''…'''` — triple-quoted strings span lines.
- `'unterminated` and `'${oops` — damage stops at the end of that line, so an
  in-progress edit does not paint the rest of the file.

## 5. Themes

### The default is derived from your `ColorScheme`

Pass no palette and `SyntaxPalette.fromColorScheme` is used. It reads three
roles — `onSurface`, `onSurfaceVariant`, `outline` — and **introduces no hue of
its own**. If your app is grey the code block is grey; if your scheme has colour
the code block is mixed from that colour. Because it is derived, it is right in
light and dark with nothing to configure.

It separates kinds along the three axes that are left once hue is given up:
comments are italic, keywords are semi-bold, strings and numbers and escapes take
`onSurfaceVariant`, punctuation takes `outline`. `plain` and `function` are left
unset, so they inherit the root style — there is no fourth axis to spend on them.

### Writing your own is a constructor call

```dart
const mine = SyntaxPalette(
  background: Color(0xFFFFFFFF),
  plain: TextStyle(color: Color(0xFF24292E)),
  comment: TextStyle(color: Color(0xFF6A737D), fontStyle: FontStyle.italic),
  keyword: TextStyle(color: Color(0xFFD73A49), fontWeight: FontWeight.w600),
  string: TextStyle(color: Color(0xFF032F62)),
  number: TextStyle(color: Color(0xFF005CC5)),
);
```

Every field is optional. A kind you leave out stays `null` and inherits the root
style. No palette sets `fontFamily` — the widget names one monospace family once
and every token inherits it.

`background` is not a kind: it is the surface the other eight are drawn on, and
leaving it `null` means the widget paints nothing and your app's surface shows
through. **If you set it, set `plain` too** — the root text colour otherwise
comes from your `ColorScheme`, which was chosen against a surface that is no
longer behind the text.

### Named presets

Ten palettes carry colours taken from well-known editor themes. They are an
**excerpt, not a reproduction**: the originals colour dozens or hundreds of
TextMate scopes and this package has eight kinds, so each preset carries what
the original gave to the scopes matching those eight, plus the background those
colours were chosen against. They do not look identical to the original editor.

| Dark              | Light                  |
| ----------------- | ---------------------- |
| `solarizedDark`   | `solarizedLight`       |
| `oneDark`         | `oneLight`             |
| `gruvboxDark`     | `gruvboxLight`         |
| `tokyoNight`      | `tokyoNightLight`      |
| `monokai`         | —                      |
| `cobalt2`         | —                      |

**A preset brings its own background, so it stays legible whatever brightness
your app is in.** Measured 2026-09-07, body text against each preset's own
background: 4.13:1 (`solarizedLight`) at the low end, 13.94:1 (`monokai`) at the
high end. A test holds that floor.

What a preset does not do is match your app. A dark preset in a light app is
perfectly readable and visibly a different surface:

![oneDark in a light app](https://raw.githubusercontent.com/kihyun1998/flutter_syntax_highlight/main/screenshots/preset-one-dark.png)

That is why themes with an upstream counterpart ship as a pair — so there is
something to pick when the code block should agree with the app — and why the
derived default, which paints no background at all, is what you get when you
pass nothing.

There is no lookup by name. An app that lets users pick a preset writes its own
list, which is exactly what
[`example/lib/main.dart`](example/lib/main.dart) does.

Provenance for every value, with a pinned upstream commit per colour, is in
[`NOTICES`](NOTICES).

## `SyntaxText`

```dart
SyntaxText(
  source, {
  SyntaxPalette? palette,
  bool copyable = true,
  bool scrollable = true,
  String? fontFamily,
  List<String>? fontFamilyFallback,
  double fontSize = 12.5,
  double height = 1.45,
  EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  String copyTooltip = 'Copy',
  String copiedTooltip = 'Copied',
})
```

- **`source`** is a string, not an asset key. Where the bytes came from is the
  app's business, so there is no loading state here and no failure screen for it.
- **Horizontal scrolling is always owned by the widget** and is not a parameter.
  Code does not wrap, because a wrapped line is a different line. `scrollable`
  governs the vertical axis only: `false` shrink-wraps vertically, for a code
  block inside prose; `true` scrolls within its own box.
- **Dragging sideways over the text does not scroll it.** The selection gesture
  takes horizontal drags — measured, and the same for `SelectionArea`, so it is
  the price of being selectable rather than a defect of one widget. The
  horizontal scrollbar is therefore the only sideways affordance on touch; on
  desktop, trackpad and wheel work.
- **The font is named, not passed as a `TextStyle`.** A whole `TextStyle` hands
  you the `inherit: true` trap: merged with the ambient `DefaultTextStyle`, a
  style that lists fallbacks without naming a family renders in the app's
  proportional font. A family is always named, even when `fontFamily` is null.
- **There are no line numbers.** This shows a fragment you can paste, and the
  natural implementation of a gutter is the broken one — inline placeholder
  spans put `\u{FFFC}` into every copied line.

## Example

```
cd example
flutter run
```

One screen: a fragment with nested interpolation, a dropdown over the derived
default plus all ten presets, and a brightness toggle.

## License

MIT. Colour values excerpted from third-party themes are attributed, upstream by
upstream, in [`NOTICES`](NOTICES).
