# Gates

## What it is

The four commands that decide green, run by hand and each run bare, and the
test suite and fixtures they run over. The command list and its scope are in
`CLAUDE.md`, *Gates*; this note holds what depends on them.

## Governing decisions

**None.** The rules are in `CLAUDE.md` (*Gates*).

## Design model

From `CLAUDE.md` and `test/fixtures/README.md`:

- Each gate runs bare, never through a pipe (a pipeline returns the last
  command's status).
- The bar is not moved to get green.
- Format scope includes `example/lib` (#21): `flutter analyze` already walked
  it, and pub.dev's example tab shows it to consumers as written.
- `flutter test` does not reach `example/` (verified by planting a failing
  test there).
- Fixtures are `.dart.txt` because malformed input is the point and as `.dart`
  it failed format and analyze (65 / 16 errors, measured); making the corpus
  tidy would have moved the bar.
- `test/support/partition.dart — expectPartitions` is shared so the paste
  contract is written once, with a "more than one kind" condition so it can
  fail.

## Code

- `CLAUDE.md` *Gates*; `analysis_options.yaml`; `test/**`;
  `test/fixtures/README.md`.

## Reference behaviour

**None.**

## Cross-cutting invariants

**None.**

## Blast radius

- [dart-scanner](dart-scanner.md) — the corpus test feeds the scanner the
  fixtures and this package's own `lib/`; a new `lib/` file joins the corpus.
- [example-app](example-app.md) — a test placed there never runs.
- [publishing](publishing.md) — the dry-run gate checks the archive.

## Known holes / open

- No CI runs the gates; they hold only when someone runs them.
