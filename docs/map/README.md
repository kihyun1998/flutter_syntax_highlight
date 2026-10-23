# Territory map

<!-- grill-map build stamp: 8e5a943 -->
<!-- grill-map synced at: 7ab224b (2026-10-23) -->

A comment's why, trap and measured value go to a note here. Notes are added as
they come up, or all at once with `grill-map`, which also reads hand-written
notes as leads and keeps their paths.

## The two questions

- **If I touch this, what else moves?** Open the territory that holds the code,
  read `## Blast radius` and `## Cross-cutting invariants`, then follow each
  link.
- **What decision is this shape derived from?** Read the territory's
  `## Governing decisions`. A **None.** there is itself the answer: the rule
  lives only in source comments, and the note's `## Design model` says so.

## How to read it

- `## Blast radius` is a checklist. A linked territory with nothing to do is a
  correct outcome.
- Every claim carries its evidence (a symbol, a test, a commit, an ADR) or its
  source and date, e.g. `(maintainer, 2026-10-23)`.
- Section headings are identical in every note, and an empty section reads
  `**None.**`, so a query finds them:
  `rg -lU '## Governing decisions\r?\n(\r?\n)?\*\*None\.\*\*' docs/map/territory/`.
- Code is named by symbol, never by line number. A value another file owns is
  linked, not copied.
- Source files and issues are text inside notes, not nodes; the map cannot
  list "everything that touches file X" — `git grep` can.

## The shape

Two layers with a seam between them. An import-free scanner turns Dart source
into a byte-preserving partition of eight lexical kinds. A thin Flutter widget
draws those kinds through a palette, which is either derived from the app's
`ColorScheme` or one of ten presets excerpted from upstream themes. The widget
also owns scrolling, scrollbars, wheel glide, the copy button and the monospace
face. One known consumer, `flutter_example_template`, uses only the tokenizer
and switches exhaustively over the kinds (maintainer, 2026-10-23).

The largest gap is that nothing runs the gates except a person: there is no CI
([gates](territory/gates.md)).

### Tokenizer

- [token-kinds](territory/token-kinds.md)
- [dart-scanner](territory/dart-scanner.md)

### Palettes

- [palette](territory/palette.md)
- [derived-default](territory/derived-default.md)
- [named-presets](territory/named-presets.md)

### Widget

- [code-rendering](territory/code-rendering.md)
- [monospace-face](territory/monospace-face.md)
- [copy-control](territory/copy-control.md)
- [scroll-axes](territory/scroll-axes.md)
- [scrollbars](territory/scrollbars.md)
- [wheel-glide](territory/wheel-glide.md)

### Shipping

- [publishing](territory/publishing.md)
- [example-app](territory/example-app.md)
- [gates](territory/gates.md)

### Cross-cutting invariants

- [pasted-bytes-are-the-input](invariant/pasted-bytes-are-the-input.md)
- [eight-kinds](invariant/eight-kinds.md)
- [colour-owner-sets-the-ground](invariant/colour-owner-sets-the-ground.md)
- [one-face-at-the-root](invariant/one-face-at-the-root.md)

## Scope

Everything under `lib/`, `test/`, `example/`, the manifest, the archive rules
and the public docs. Out of scope:

- `reference/` — a byte-identical snapshot of `flutter_table_plus` @ `ac83b27`
  that the scanner and widget were ported from. It is historical, and nothing
  is compared against it any more (maintainer, 2026-10-23). It is not part of
  the package and is never edited; `.pubignore` keeps it out of the archive and
  `analysis_options.yaml` keeps it out of analysis.
- `docs/agents/` — agent setup, not system behaviour.

**An absent note means nothing in the repo commits to that area.** A territory
is owed one when an ADR, a spec or an open issue with a design commits to it.
An idea with nothing behind it is not a territory.
