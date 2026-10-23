# Copy control

## What it is

The optional copy button in the top-right of `SyntaxText`: it puts the source on
the clipboard and shows a brief confirmation.

## Governing decisions

**None.** [ADR-0002](../../adr/0002-a-palette-carries-its-own-background.md)
governs only its colour.

## Design model

From the `SyntaxText.copyable` doc and `_SyntaxTextState`:

- **A convenience, not a guarantee.** The reference implementation's two
  justifications (discoverability, touch platforms) were withdrawn —
  `AdaptiveTextSelectionToolbar` already copies on Android. Paste fidelity is
  guarded by the span-tree flattening test, not the clipboard.
- Copies `widget.source`, not the rendered text.
- Confirmation is finite (1400 ms `Timer`) so `pumpAndSettle` settles; it
  resets when `source` changes (a check beside text never copied is a lie);
  the timer is cancelled in `dispose`.
- Tooltips default to English (`'Copy'`, `'Copied'`) and are parameters for
  localisation.

## Code

- `lib/src/widget/syntax_text.dart — SyntaxText.copyable`, `copyTooltip`,
  `copiedTooltip`; `_SyntaxTextState._copy`, `_confirmation`, `_copied`,
  `didUpdateWidget`, `dispose`; the `Stack`/`Positioned` in `build`.
- Tests: `test/widget/syntax_text_test.dart` group `복사 컨트롤`, and
  `그리고 복사 컨트롤이 같은 것을 클립보드에 올린다`.

## Reference behaviour

**None.**

## Cross-cutting invariants

- [pasted-bytes-are-the-input](../invariant/pasted-bytes-are-the-input.md)
- [colour-owner-sets-the-ground](../invariant/colour-owner-sets-the-ground.md)

## Blast radius

- [code-rendering](code-rendering.md) — the `Stack` it adds is why the
  background must be painted outside it.

## Known holes / open

**None.**
