# Publishing

## What it is

Shipping the package to pub.dev: the manifest and SDK floor, what goes into
the archive, the public docs a consumer reads (README, CHANGELOG, screenshots,
`NOTICES`, LICENSE), versioning, and dependency updates. Releases are
`release:` commits; no CI workflow publishes.

## Governing decisions

**None.** [ADR-0001](../../adr/0001-token-kinds-are-lexical-only.md) (a kind
change is breaking) and
[ADR-0003](../../adr/0003-the-derived-default-borrows-the-app-s-accent-diluted.md)
(a visible palette change is a minor bump) bear on versioning; neither governs
the shipping mechanism.

## Design model

From `pubspec.yaml`, `.pubignore` and `.github/dependabot.yml` comments:

- **SDK floor is borrowed**: `sdk: ^3.8.0`, `flutter: ">=3.32.0"` because
  `flutter_smooth_wheel_scroll` requires it; writing lower would be false.
  The one consumer took the same floor from here (`flutter_example_template`
  @ `5b18424`, `pubspec.yaml` comment).
- **`.pubignore` replaces `.gitignore`**, so everything git ignores that can
  actually appear is copied in; the first archive carried a 45 MB `build/`
  cache. `example/macos/` and `example/web/` stay out of the archive (pub.dev's
  example tab reads `example/lib/main.dart` and `example/README.md`).
- No `flutter:` section — an empty key reads as something removed.
- `NOTICES` must be in the archive — `test/widget/presets_test.dart` `ships in the package` checks `.pubignore` does not exclude it.
- Dependabot opens weekly pub PRs at the root only, labelled `needs-triage`
  (#33).

## Code

- `pubspec.yaml`, `.pubignore`, `CHANGELOG.md`, `README.md`, `NOTICES`,
  `LICENSE`, `screenshots/*.png`, `.github/dependabot.yml`,
  `lib/flutter_syntax_highlight.dart` (the export surface).

## Reference behaviour

**None.**

## Cross-cutting invariants

**None.**

## Blast radius

- [gates](gates.md) — `flutter pub publish --dry-run` is a gate; a change to
  `.pubignore` or the manifest shows there first.
- [example-app](example-app.md) — ships in the archive and is what pub.dev's
  example tab shows.
- [wheel-glide](wheel-glide.md) — owns the dependency that sets the floor.
- [token-kinds](token-kinds.md) — any kind change forces a major version for
  the consumer's exhaustive switch.

## Known holes / open

- No release automation or tag convention beyond `release:` commit subjects;
  how a release is cut is not written down in the repo.
- README screenshots are static PNGs; nothing checks they still match the
  derived default or presets.
