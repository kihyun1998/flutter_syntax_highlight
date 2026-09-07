# flutter_syntax_highlight

Syntax highlighting for **Dart source**, in two layers: a pure-Dart tokenizer
underneath and a thin widget on top. What you pass in is what gets drawn — the
tokens rejoin into the exact input, byte for byte.

| Light | Dark |
| :---: | :--: |
| ![Light](https://raw.githubusercontent.com/kihyun1998/flutter_syntax_highlight/main/screenshots/light.png) | ![Dark](https://raw.githubusercontent.com/kihyun1998/flutter_syntax_highlight/main/screenshots/dark.png) |

On the `return` line, inside `'${value ? '✓' : '✗'}'`: the nested `'✓'` and
`'✗'` are drawn as strings and the conditional around them as code.

## Install

```yaml
dependencies:
  flutter_syntax_highlight: ^0.2.0
```

```dart
import 'package:flutter/material.dart';
import 'package:flutter_syntax_highlight/flutter_syntax_highlight.dart';

void main() => runApp(
      const MaterialApp(
        home: Scaffold(
          body: SyntaxText("void main() => print('hi');"),
        ),
      ),
    );
```

That is the whole setup. No theme to register, no asset to bundle.

## Two layers, and you may take just one

**`tokenizeDart(String source)`** returns a `List<DartToken>` — a slice of the
source plus a kind, for every character in order.

```dart
for (final token in tokenizeDart(source)) {
  print('${token.kind.name}: ${token.text}');
}
```

It imports **nothing** — not Flutter, not `dart:*` — so it also runs in a server,
a CLI or a build step, and unit-tests without a widget.

**`SyntaxText`** draws that as selectable, copyable code. The tokenizer decides
*what* a kind is; the widget decides *how* it looks.

## Dart only, and deliberately coarse

Both halves are decisions.

**Dart only.** The scanner is written by hand against Dart's lexical grammar —
nested block comments, raw strings, recursive interpolation. There is no grammar
table to swap out.

**Deliberately coarse.** Eight kinds, every one decidable by reading characters
left to right:

| Kind | Covers |
| --- | --- |
| `plain` | identifiers, whitespace, anything unclassified |
| `comment` | `//` to end of line, and `/* */` including nested pairs |
| `keyword` | reserved words, built-in and contextual identifiers |
| `string` | the parts of a literal not split off as escape or interpolation |
| `number` | int, double, hex |
| `punctuation` | brackets, operators, separators |
| `escape` | `\n`, `\t`, `\'`, `\\` inside a string |
| `function` | an identifier immediately before `(` |

Finer distinctions other tools draw — type versus variable, call versus field —
are **not** here. Telling a type from a variable needs a parser; a scanner can
only guess from a capital letter, and that guess is wrong on `const PI`, on enum
values, on generic parameters. A half-right answer about what a name *means* is
worse than none, because the reader believes it.

What was considered and rejected is in
[ADR-0001](https://github.com/kihyun1998/flutter_syntax_highlight/blob/main/docs/adr/0001-token-kinds-are-lexical-only.md).

## Your bytes come back unchanged

`tokenizeDart` returns a **partition**: concatenate every token's text in order
and you have the input back. One line states it, and the suite asserts it over
this package's own source:

```dart
expect(tokenizeDart(source).map((t) => t.text).join(), source);
```

Two things that follow:

- **CRLF survives.** Line endings belong to a checkout, not a repository, and a
  library handed arbitrary source has no standing to normalise them.
- **Case survives.** Keyword matching never emits a lower-cased form.

So what a reader copies off the screen is what you passed in, and it runs.

## Interpolation is scanned recursively

The inside of `${...}` is re-scanned with the same rules as the outside, so a
string nested in an interpolation comes back out as a string. All three of these
highlight correctly:

```dart
final text = '${newValue ?? ''}'.trim();
final rows = 'selectedRows: ${selected.join(', ')}';
return '${value ? '✓' : '✗'} $key';
```

The same scanner covers the boundaries that are easy to run past:

- `/* /* */ */` — Dart nests block comments; the first `*/` does not end it.
- `// somebody's problem` — an apostrophe in a comment opens nothing.
- `r'a\'` — in a raw string a backslash is just a character.
- `'''…'''` — triple-quoted strings span lines.
- `'unterminated` and `'${oops` — damage stops at the end of that line, so an
  in-progress edit does not paint the rest of the file.

## Themes

### The default is derived from your `ColorScheme`

Pass no palette and `SyntaxPalette.fromColorScheme` is used. It **introduces no
hue of its own**: every colour is a neutral role from your scheme, or a neutral
role pulled part-way towards your `primary` or `tertiary`. Your app's colour
comes through, this package's does not — a monochrome scheme yields a
monochrome palette. And because it is derived, it is right in light and dark
with nothing to configure.

How far it pulls was measured rather than eyeballed, over the whole hue circle
in both brightnesses
([ADR-0003](https://github.com/kihyun1998/flutter_syntax_highlight/blob/main/docs/adr/0003-the-derived-default-borrows-the-app-s-accent-diluted.md)).

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

Every field is optional; a kind you leave out inherits the root style. Leave
`background` null and your app's surface shows through — but if you set it, set
`plain` too, or the text keeps a colour that was chosen against a surface no
longer behind it.

### Named presets

| Dark | Light |
| --- | --- |
| `solarizedDark` | `solarizedLight` |
| `oneDark` | `oneLight` |
| `gruvboxDark` | `gruvboxLight` |
| `tokyoNight` | `tokyoNightLight` |
| `monokai` | — |
| `cobalt2` | — |

Each is an **excerpt, not a reproduction**: the originals colour hundreds of
TextMate scopes and this package has eight kinds, so a preset carries what the
original gave to those eight plus the background they were chosen against. They
do not look identical to the original editor.

A preset therefore stays legible whatever brightness your app is in — but it
will not match your app:

![oneDark in a light app](https://raw.githubusercontent.com/kihyun1998/flutter_syntax_highlight/main/screenshots/preset-one-dark.png)

That is why themes with an upstream counterpart ship as a pair, and why the
default is the derived palette rather than one of these
([ADR-0002](https://github.com/kihyun1998/flutter_syntax_highlight/blob/main/docs/adr/0002-a-palette-carries-its-own-background.md)).
There is no lookup by name — an app offering a picker writes its own list, as
[`example/lib/main.dart`](example/lib/main.dart) does. Provenance for every
value, pinned to an upstream commit, is in [`NOTICES`](NOTICES).

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

- **`source` is a string, not an asset key.** Where the bytes came from is your
  app's business, so there is no loading state and no failure screen.
- **Code never wraps, so horizontal scrolling is always on** and is not a
  parameter — a wrapped line is a different line. `scrollable` governs the
  vertical axis only: `false` shrink-wraps, for a code block inside prose;
  `true` scrolls within its own box.
- **Dragging sideways over the text does not scroll it** — the selection gesture
  takes horizontal drags. The scrollbar is the sideways affordance on touch; on
  desktop, trackpad and wheel work.
- **There are no line numbers.** A gutter would put `\u{FFFC}` into every copied
  line, which is the one thing this package exists not to do.

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
