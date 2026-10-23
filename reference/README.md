# Reference snapshot

This directory is **not part of the package.** It is 4 files lifted as is from
the example app of `flutter_table_plus`, and they are left untouched.

## Source

| Item | Value |
|---|---|
| repo | `flutter_table_plus` (kihyun1998) |
| commit | `ac83b2719249a43c821d265ee5c3c4d46f5056dd` |
| commit subject | *fix(example): the CRLF guard was testing the checkout, and the machine moved* |
| date | 2026-09-04 |
| licence | MIT, © 2025 Ki Hyun Park (same author) |
| lifted on | 2026-09-05 |

Original path → here:

```
example/lib/shell/dart_highlighter.dart   (424 lines) → dart_highlighter.dart
example/lib/shell/source_pane.dart        (463 lines) → source_pane.dart
example/test/dart_highlighter_test.dart   (341 lines) → dart_highlighter_test.dart
example/test/source_pane_test.dart        (646 lines) → source_pane_test.dart
```

All four files are **byte-identical** to their contents at `ac83b27` (checked
against shasum).

## Why this commit and not the working tree

When the snapshot was taken, `flutter_table_plus`'s working tree had a large
uncommitted refactor in it — `example/lib/shell/` → `example/lib/gallery/src/shell/`.
Why that tree was not taken as the baseline:

1. **Every difference was something we would delete anyway.** The actual diff
   is only import path rewrites, `dart format` reflow, and host API changes
   inside tests we had decided to drop. The **behaviour** of the tokenizer and
   the pane **does not differ by a single line.**
2. **An uncommitted tree has no name.** When asked later "what exactly did we
   lift", there would be nothing to point at, and if that refactor were reverted
   or remade, the baseline itself would evaporate.
3. `ac83b27` **already holds the answer to the CRLF problem.** That commit is
   the fix itself — the escape literal is the CRLF witness, and an escape is
   immune to the checkout.

## Why here and not `lib/`

These files import `package:example/...`, so they do not compile here. And once
implementation starts, its output has to be checked against these originals; if
they were dropped into `lib/` and fixed in place, the original to check against
would vanish. The implementation **copies from here**, and this directory stays
untouched.
