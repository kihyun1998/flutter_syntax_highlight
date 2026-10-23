# The derived default borrows the app's accent, diluted

`SyntaxPalette.fromColorScheme` now pulls towards the app's accent colours in two places. `string` (and `escape`, which follows it) from `onSurfaceVariant` towards `tertiary`, and `function` from `onSurface` towards `primary`, each by **0.70**. `number` and `punctuation` are not pulled.

This overturns one acceptance criterion of [#17](https://github.com/kihyun1998/flutter_syntax_highlight/issues/17) — *"`fromColorScheme` uses only `onSurface` / `onSurfaceVariant` / `outline`."*

## What is overturned is an implementation decision, not the principle

The principle was **"introduces no hue of its own"**. Reading only three roles was one way to keep it, not the only way.

Using `scheme.primary` as is would dress the code block in the app's whole accent colour, and a palette meant to be quiet would turn loud. But **with the anchor on a neutral role and only a partial move away from it**, every hue that comes in is the app's, and this package brings in none. If the app is achromatic, the result is achromatic — a test catches that property.

## The coefficient was chosen by measurement

Two gauges were already inside this palette. These values were measured by sweeping `fromSeed` over 12 directions of the colour wheel × light and dark (2026-09-07):

- `onSurfaceVariant` vs `onSurface` — **ΔE 9.9**. This was the difference between `string` and `plain`, and cropping the screenshot showed it was **almost invisible.** The README's hero image could not show what the caption right below it pointed to.
- `outline` vs `onSurface` — **ΔE 29.9**. This is clearly visible.

At `t = 0.70`, every new distinction falls between the two:

| | ΔE (minimum over the whole colour wheel) |
|---|---|
| string ↔ plain | 15.4 |
| string ↔ number | 11.4 |
| function ↔ plain | 17.4 |
| function ↔ string | 15.9 |

**Contrast ratio was not a constraint.** At first it was expected to set the upper limit, and that was wrong — even at `t = 1.0` the worst against the surface is 6.1, while `outline`, which this palette already carries, is 4.23. That is because M3's `fromSeed` maps `primary`/`tertiary` to fixed tones and makes them legible in the first place.

And **contrast ratio could not measure this change.** Contrast ratio looks only at luminance — red and green can have the same contrast ratio. The first sweep produced "separation 1.07" and nearly got read as invisible, but that ruler was one that cannot measure hue difference. Only after switching to CIE Lab ΔE did the numbers match the eye.

## Why these two places

**`function` was the only empty slot.** In the survey [ADR-0001](0001-token-kinds-are-lexical-only.md) cites, **9/9** themes paint call names differently, and only this palette gave it nothing. The reason was *"there is no axis left"*, and this document removes that reason.

**`string` is where the hero image failed.** This package's reason to exist is that `'✓'` in a nested interpolation is drawn as a string, and in the derived default that distinction was a single step of brightness, so it was invisible on screen.

**`number` is left on purpose.** If all three literals moved, they would stay in place relative to each other. Moving only `string` creates a distinction between strings and numbers that was not there.

**`escape` follows.** It is part of its own literal, and in the preset survey ([#9](https://github.com/kihyun1998/flutter_syntax_highlight/issues/9)) four of the ten painted escape in the same colour as number — always distinguishing it is not the universal choice.

## Consequences

**The look changes, so it is `0.2.0`.** `flutter_example_template` pins `^0.1.0` and so does not follow automatically — it has to be bumped explicitly, and so nobody is surprised.

**The derived default has to be checked differently from the presets.** The presets have fixed values, so measuring the ten is the end of it, but consumers' schemes are infinite. A coefficient picked by eye on one's own seed is right only on that seed, so the colour-wheel sweep stays as a test.

**The coefficient is not nailed down as a value.** The palette test checks that a pulled colour lies **between the anchor and the destination**. The coefficient may be measured again, and this property must survive when it is. Putting in an arbitrary colour gets caught regardless of the coefficient.

**It looks like the opposite direction from [ADR-0002](0002-a-palette-carries-its-own-background.md), but it is the same rule** — whoever picks a colour also decides where it sits. Upstream picked the presets, so they bring upstream's background too; the app picked the derived default's colours, so it uses the app's background and borrows the app's hues too.
