# Monospace face

## What it is

How `SyntaxText` guarantees a fixed-width face: it always names a non-null
family on the root style, picked per platform, with a fallback list that does
not repeat it, and it takes font settings as separate values rather than a
`TextStyle`.

## Governing decisions

**None.** The rules come from the `SyntaxText` class doc (*글꼴은 `TextStyle`
하나가 아니라 숫자 몇 개로 받는다*) and the `defaultMonoFamily` /
`monoCandidates` docs.

## Design model

From source only:

- **Never take a whole `TextStyle`** — with `inherit: true` the ambient
  `DefaultTextStyle` merges in, and a style naming only fallbacks draws in the
  app's proportional font.
- **Always name a family.** `fontFamily: null` means "pick the platform
  default", never "unset" (`SyntaxText.defaultMonoFamily`: Menlo on
  macOS/iOS, Consolas on Windows, `monospace` on Android and web, DejaVu Sans
  Mono on Linux/Fuchsia).
- **The fallback excludes the chosen family** (`fallbackWithout`): when the
  family was also the first fallback, nobody noticed for a long time that no
  family was set at all.

## Code

- `lib/src/widget/syntax_text.dart — SyntaxText.fontFamily`,
  `fontFamilyFallback`, `fontSize`, `height`, `defaultMonoFamily`,
  `monoCandidates`, `fallbackWithout`; `_SyntaxTextState.build` root
  `TextStyle`.
- Tests: `test/widget/syntax_text_test.dart` group `고정폭`.

## Reference behaviour

**None.**

## Cross-cutting invariants

- [one-face-at-the-root](../invariant/one-face-at-the-root.md)

## Blast radius

- [code-rendering](code-rendering.md) — the root style it names is the one
  every span inherits; moving the face to leaves breaks the inheritance the
  palettes rely on.

## Known holes / open

- Whether each named family exists on the target is not checked; the fallback
  list is the only recourse. Not measured on devices.
