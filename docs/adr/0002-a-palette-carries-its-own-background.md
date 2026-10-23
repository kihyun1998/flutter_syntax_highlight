# A palette carries its own background, and the derived default does not

`SyntaxPalette` has a `Color? background`. All ten named presets fill it, and `SyntaxPalette.fromColorScheme` **leaves it empty.** The two decisions look opposite but are two cases of the same rule: **whoever picks a colour also decides where it sits.**

The derived default draws its colours from the app's `ColorScheme`. The app picked those colours, and the app has already painted its own surface — so the right background is the app's, and painting `scheme.surface` again here would lay the same colour on one more time while taking away the app's freedom to put just the code block on a different surface.

The named presets are the opposite. Their colours were picked upstream **against a particular background.** Carried over without it, the contrast the original set disappears, and what is left is chance, measured against the app's surface.

## Context

When the presets went in (#6 → #9), the frame was *"take the colours the original gave to the scopes matching our eight kinds"*. The frame was the kind list, and **the background is not a kind, so it was not there.** So nobody asked, and `SyntaxPalette` stayed with eight fields that were all `TextStyle?`, with not a single `ColoredBox` anywhere in `lib/`.

The discovery came from a screenshot in #21. Picking `oneDark` in a light app turned only the text into One Dark colours, and the background stayed the app's light surface.

## The false argument that absence produced

`syntax_palette.dart` and `example/README.md` said:

> A named preset is a hard-coded palette, so in the opposite brightness it does not just break, it is **invisible** — `cobalt2`'s body text `#FFFFFF` has a contrast ratio of **1.00**.

And from there they derived *"if the original has a pair, ship it as a pair"* and *"the default is not a preset"*.

**The number was right and the thing measured against was wrong.** 1.00 is white body text measured against *the app's* light surface. Because the palette did not carry a background, there was nothing else to measure against, and so the missing field read as a property of the preset. Measured against its own background `#193549`, it is **12.75** (measured 2026-09-07).

Measuring all ten against their own backgrounds, the body contrast ratio is **4.13 – 13.94**. The floor, 4.13, is `solarizedLight`, and that value was set upstream, so this package cannot raise it.

## Consequences

**The reason for shipping pairs changes.** It is not legibility but **brightness preference** — `oneDark` in a light app reads fine, but only the code block is dark. There has to be something to choose. The conclusion (ship them as pairs) stands; the grounds were replaced.

**It is not a breaking change.** It is a named optional field, and the background is not a kind, so it touches neither the exhaustive `switch` in `styleFor` nor a consumer's `switch`. It is a different axis from [ADR-0001](0001-token-kinds-are-lexical-only.md) nailing down adding a kind as breaking after publishing — written down here so that sentence is not read as *"nothing can be added to a palette"*.

**A palette that gives a background must also give `plain`.** The root style's colour is `ColorScheme.onSurface`, which was picked against the app's surface, and what is behind it is now not that surface. All ten presets give both.

**The widget's own controls follow the palette too.** If the copy button and the scrollbar are drawn with the app theme's `onSurfaceVariant`, they sink into someone else's background. When there is a background, they take the palette's `comment`/`plain` colours. ([ADR-0004](0004-the-widget-fills-only-the-scrollbar-fields-nobody-set.md) narrowed this to **colour** for the scrollbar — the behaviour and shape are decided by the app's scrollbar theme.)

**The background is painted outside the `Stack`.** The default `fit` of a `Stack` is loose, so inside it the background shrinks to the size of the code content and leaves unpainted area in a pane wider than the code. A test catches that regression.
