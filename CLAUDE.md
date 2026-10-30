# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Agent skills

- **Issues** live in GitHub Issues for `kihyun1998/flutter_syntax_highlight`,
  managed with the `gh` CLI. Before opening, labelling or closing an issue, read
  `docs/agents/issue-tracker.md` (labels: `docs/agents/triage-labels.md`).
- **Domain docs** are single-context: `GLOSSARY.md` and `docs/adr/` at the repo
  root. Before naming a concept or reversing a decision, read them
  (`docs/agents/domain.md`).

## Gates

Four, and each runs **bare**, never through a pipe — a pipeline returns the last
command's status, so a check whose output is filtered always passes.

```
flutter analyze
dart format --output=none --set-exit-if-changed lib test example/lib
flutter test
flutter pub publish --dry-run
```

`flutter test` does **not** reach `example/`, so the example carries no tests.
To change that, fix the gate first.

Hold the bar where it is; never move it to get green. Lowering the floor admits exactly that
much regression, and the real regression settles just below it.

Before changing a gate or its scope, read `docs/map/territory/gates.md`.

## Map

The territory map is [`docs/map/README.md`](docs/map/README.md). Read it before
designing a change: open the territory that holds the code, and follow its
blast radius and cross-cutting invariants. After the change lands, write back
whatever it made false, and add any why, trap or measured value it revealed.
When a fix reveals a fact, ask whether it holds at every site that shares the
same assumption. If it does, the fix lands with an invariant note under
`docs/map/invariant/`.

## Comments

A comment says what the code is. Why it is this way, what it deliberately
leaves out, the trap and the measured value go to the territory note under
`docs/map/`. Where none seems to hold it, search the folder and the code symbol
first; only then start a new note, named for what the system does there, not
for the file. History goes to the commit message. Comments written before this
rule still carry the rest: never delete one whose content the map does not yet
hold — move it there first.
