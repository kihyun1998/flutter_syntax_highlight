# CONTEXT

The glossary for this repository. Implementation detail does not go here.

## Tokens

**Token kind** — a name for a class of text span, classified *in order to draw it differently*. It decides what the span *looks like*, not what it *means*. `DartTokenKind` is the list.

**Lexically decidable** — a distinction that a scanner sweeping characters left to right can decide for certain. The one character after `\` is an escape. The identifier directly before `(` is the name at a call site.

**Guess** — a distinction that the lexicon alone does not decide, so it has to lean on convention. It starts with a capital, so it is probably a type, and the like. **It cannot become a kind.** A half-right answer is worse than no answer, because the reader believes it.

**Partition** — the property that concatenating the `text` of the tokens `tokenizeDart` returns, in order, equals the input byte for byte. Tokens are cut at recorded offsets (`source.substring(previousEnd, thisEnd)`) and never rebuilt. It is this package's central claim.

## Layers

**Tokenizer** — decides *what* a kind is. Pure Dart, and imports nothing. Not Flutter, not `dart:*`.

**Widget** — decides *how* a kind looks. The opinions the tokenizer cannot hold live here.

**Seam** — the line between the two above. The moment the tokenizer knows about `Color`, the two layers are welded, and then it cannot be tested without rendering.

**Palette** — a value that holds one `TextStyle` per kind. Not a theme engine but eight slots of data; a slot not given stays null and inherits the root style.

At first this was written down as "a plain Map". In fact it is named fields and an exhaustive `switch` — when one more kind is added, that `switch` **does not compile.** With a Map the missing slot would pass silently as null, and since [[adr-0001]] recorded adding a kind as a breaking change after publishing, that moment must not pass silently.

**Hue-neutral** — the character of the default palette. It reads only three roles of the `ColorScheme`, `onSurface` / `onSurfaceVariant` / `outline`, and **introduces no hue of its own.** If the app is achromatic it is achromatic; if the app has colour it blends into that colour. Because it is derived, it is right in both light and dark with nothing to configure.

**Do not call it "achromatic".** The reference called it that, but the ground was that the host app's scheme was monochrome, so **there was no hue to take in the first place**. A consumer's scheme may have colour, and measured, the `outline` of `ColorScheme.fromSeed(0xFF6750A4)` is hue 270 — that palette is not achromatic. Name the property, not the condition.

## Material

**Reference** — the 4 files in `reference/`, lifted byte for byte from `flutter_table_plus`. Not part of the package, and not touched. The implementation copies from here and checks its own output against it.

**Corpus** — the body of Dart code fed to the tokenizer to test the partition property. It is made of hand-written fixtures and this package's own `lib/` source.
