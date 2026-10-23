# Example app

## What it is

The one-screen demo under `example/`: a nested-interpolation fragment, a
palette dropdown (derived default plus all ten presets), a brightness toggle,
seed swatches, and a wheel demo with a `wheelMotion` picker. It is also what
pub.dev's example tab shows.

## Governing decisions

**None.**

## Design model

From `example/lib/main.dart`, `example/pubspec.yaml` and `CLAUDE.md`:

- It is the documented substitute for a lookup by name: the app writes its own
  palette list (`palettes`), as README tells consumers to.
- The seeds demonstrate hue-neutrality; the last swatch is monochrome, so with
  no colour to borrow none appears.
- The wheel sample is deliberately longer and wider than an 800×600 window.
- Depends on the package by `path: ../`, without `resolution: workspace` —
  the reason once given for the workspace was measured false
  (`example/pubspec.yaml` comment).
- **No tests here**: `flutter test` does not run `example/` (CLAUDE.md, verified
  by planting a failing test). It is covered by `flutter analyze` and, since
  #21, by `dart format`.

## Code

- `example/lib/main.dart — sample`, `palettes`, `Seed`, `seeds`, `motions`,
  `wheelSample`, `ExampleApp`
- `example/README.md`, `example/pubspec.yaml`

## Reference behaviour

**None.**

## Cross-cutting invariants

**None.**

## Blast radius

- [publishing](publishing.md) — it is in the archive and on pub.dev; README's
  *Example* section describes it.
- [gates](gates.md) — it is inside analyze and format scope, outside test.

## Known holes / open

- The palette list is hand-kept; a new preset is missing until added (see
  [named-presets](named-presets.md)).
