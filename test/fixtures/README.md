# The fixture corpus

**Input data** fed to the tokenizer. Not code.

## Why the extension is not `.dart`

The gates walk `test/**.dart`. And the point of this corpus is **untame
input** — it has to hold things that do not parse, such as an unclosed string
or an unclosed interpolation. Keeping that as `.dart`:

Measured with the four files kept as `.dart`:

```
dart format --output=none --set-exit-if-changed lib test   → 65
flutter analyze                                            → 1  (18 issues, 16 errors)
``` Making the corpus tame to get the gates to pass would be moving the
threshold, so the extension moved instead.

Why there are no line endings here is in the doc of `corpus_test.dart`.

## What it holds

The seven the reference's doc enumerated after checking with grep on
2026-09-02. That corpus had none of them, but the consumer's code is under no
obligation to be tame, so all of them are covered.

`malformed.dart.txt` is not among the seven. This file is the very ground for
the extension decision — the gates only actually die if there is input that
does not parse — and it stays because the partition has to hold on untame
input too.

| File | What it holds |
|---|---|
| `strings.dart.txt` | raw strings, triple quotes, escaped quotes, `//` inside a string |
| `comments.dart.txt` | a comment with an apostrophe, quotes inside a doc comment, nested block comments |
| `interpolation.dart.txt` | the three nested-interpolation sites and a brace in a string inside an interpolation |
| `malformed.dart.txt` | an unclosed string, an unclosed interpolation |

`corpus_test.dart` actually checks this list — because if a file goes empty or
a construct drops out, the partition checks pass while guarding nothing.
