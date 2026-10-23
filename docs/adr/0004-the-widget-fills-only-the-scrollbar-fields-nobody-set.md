# The widget fills only the scrollbar fields nobody set, and the palette decides the colour

The `ScrollbarTheme` that `SyntaxText` puts around its own scrollbars **does not replace the outer `ScrollbarTheme.of(context)` but sits on top of it.** Each field has a different owner:

- **The palette decides `thumbColor`** (when there is a background). It is [ADR-0002](0002-a-palette-carries-its-own-background.md)'s rule as is — whoever picks a colour also decides where it sits. A colour the app gave was picked against the app's surface, so on a preset's background it guarantees nothing.
- **The consumer decides behaviour and shape (`interactive`, `thumbVisibility`, `thickness`, `radius`…).** They are values unrelated to the background.
- **The widget fills the values nobody set.** On `TargetPlatform.android`, if the app theme's `interactive` and `thumbVisibility` are empty, it passes `true` as widget parameters of the **horizontal** `Scrollbar`. It does not fill them through the theme because the theme would also apply to the vertical bar beneath it, and the vertical bar would end up always visible too.

There is one rule: **what a value was picked against decides who owns it.**

Decided in the grilling on [#29](https://github.com/kihyun1998/flutter_syntax_highlight/issues/29) (2026-10-19).

## Context

The class doc calls the horizontal `Scrollbar` **"the only horizontal affordance on touch"**, because the selection gesture takes a horizontal drag over the text (measured 2026-09-06). But on Android that bar could not be dragged. Measured 2026-10-19:

| | Horizontal position after dragging |
|---|---|
| widget test, android, `scrollable` true / false | **0.0** / 0.0 |
| widget test, windows (control) | 302.3 |
| emulator (Medium Phone API 36.1), default | **0.0** |
| emulator, `interactive`·`thumbVisibility` turned on in the app theme | 127.4 / 127 (all the way) |

The cause has two layers. Only on Android does Material `Scrollbar` default `interactive` to false, and the thumb appears only while scrolling, and while transparent it does not take hit tests either. Since that thumb is the only way to scroll horizontally, there is no way to make it visible in the first place.

**And the path for the consumer to turn it on themselves was blocked too.** To match the thumb colour when there is a background, the widget put in `ScrollbarTheme(data: ScrollbarThemeData(thumbColor: …))`. Themes do not merge; only the nearest one is read. So a theme meant to change one colour wiped out, on top of it, every other field the app had set:

| With the bar turned on in the app theme (android, widget test) | |
|---|---|
| derived default (no background → widget puts in no theme) | 302.3 |
| `SyntaxPalette.oneDark` (has background) | **0.0** |

## Considered

- **The widget forces it.** Always on, on Android. The consumer cannot turn it off — in an app that does not want an always-visible bar, the package decides the look of the screen unilaterally.
- **Leave it to the consumer.** Only fix the merging. A default-state Android user still cannot scroll horizontally, and the doc's "only affordance" stays false.
- **Fill only the empty fields (adopted).** It works straight away for a first-time user, and leaves a way to override it. It only slots into the order Flutter themes are already resolved in (widget parameter → nearest theme → platform default), and does not overturn it.

## Consequences

**If the consumer states `thumbVisibility: false` or `interactive: false`, Android touch users cannot scroll horizontally.** That value winning is the point of this decision, so it is not blocked. Instead the class doc warns about it.

**Turning on `interactive` turns on track taps too.** On Android, just tapping where the bar is moves one page (400×300, 80 lines: 0 → 320), and touches in that strip do not reach the text. Material `Scrollbar` has no parameter to turn off dragging and track taps separately. When `interactive: true` was decided in the grilling this result had not been seen, and after measurement the maintainer accepted it as the cost (2026-10-19). A test pins this behaviour.

**It fills them only on Android.** Android is the only place confirmed by measurement, and it is also the only platform where Material `Scrollbar` takes its own Android branch (`interactive` defaulting to false). That does not mean the problem is only on Android — the second cause (a transparent thumb takes no hits) can apply anywhere the thumb starts hidden and selection takes the horizontal drag. iOS gave the same 0.0 in a widget test, but Cupertino has a different gesture system and it was not measured on a device, so it was split out to [#30](https://github.com/kihyun1998/flutter_syntax_highlight/issues/30). Other platforms were not measured.

**With `scrollable: true`, the horizontal bar is placed outside** (`notificationPredicate: depth == 1`). Inside the vertical scroll view the bar is drawn at the very end of the content (y≈1472 for 80 lines), so even if it can be dragged it cannot be seen.

**The bar does not follow the screen inset.** In the grilling this was not asked separately, on the reckoning that "the default `padding` of 16 wraps the 4px Android thumb, so it does not cover the last line", and that reckoning was wrong. Material `Scrollbar` passes `MediaQuery.paddingOf(context)` straight into the painter (`updateScrollbarPainter` in Flutter 3.41.9 `material/scrollbar.dart`), and there is no parameter to turn that off. Even with the widget in the middle of the screen that value comes down, and on the emulator (bottom padding 24) the horizontal bar overlapped the glyphs of the last line (2026-10-19). The reckoning was the same before the fix too, but on Android the bar was transparent and could not be seen.

In [#31](https://github.com/kihyun1998/flutter_syntax_highlight/issues/31) the maintainer decided (2026-10-20): that padding is removed for **both bars, on all four sides.** It follows the paragraph above's "inset is the app's job" as is — a screen-based inset is the wrong value, in any direction, for the bar of a widget that does not know its own position. The alternatives put forward with it were "only the horizontal bar's bottom" (the issue's first step) and "all four sides of the horizontal bar". When choosing, how the vertical bar changes was not measured. Now a widget test pins it (with 24 on all four sides, the vertical track reaches the top and bottom ends). The widget removes the padding only around the bars, and gives the code inside them back the outer `MediaQuery`, because the selection toolbar and handles have to see the screen's inset.

**The automatic vertical bar on desktop is turned off only in the vertical view.** Material's `MaterialScrollBehavior.buildScrollbar` attaches a `Scrollbar` to every vertical `Scrollable` on desktop. So with `scrollable: true` the vertical view had one more bar drawing the same controller as this widget's bar, and scrolling showed both (widget test, windows, 400×300, 80 lines: two of the 4 bars were `_vertical`, 2026-10-20). The vertical view is wrapped in `ScrollConfiguration.of(context).copyWith(scrollbars: false)`. It copies the app's `ScrollBehavior` rather than making a new one, so the rest of the app's settings, such as `dragDevices`, still apply.

The automatic bar of the `EditableText` inside `SelectableText` is kept. `EditableText` turns the outer behaviour back on with `copyWith(scrollbars: _isMultiline)`, so the wrapping above does not catch it (Flutter 3.41.9 `widgets/editable_text.dart`). In normal use its scroll extent is 0, so it is not visible. When `scrollable: false` is placed somewhere with a fixed height, `EditableText` scrolls inside itself (max 1172 under the same conditions), and then this is the only vertical bar visible on desktop. In [#32](https://github.com/kihyun1998/flutter_syntax_highlight/issues/32) the maintainer decided (2026-10-20): **turn off only the duplicate bar.** The alternative put forward with it was turning this bar off too with `SelectableText.scrollBehavior`, and put forward with that was its cost: the vertical bar in the case above would disappear on desktop as well (the same as Android now). A test pins that this bar stays.

**The system gesture area is the app layer's job.** If the widget sits at the very bottom of the screen, the thumb falls into that area. On the emulator, drags there were only partly delivered (30.8, 77.1 / 127). The widget does not know where on the screen it sits, so it does not read `systemGestureInsets` to avoid it. The doc says so.

**This narrows ADR-0002's "The widget's own controls follow the palette too".** What follows is the **colour**. Implementing that sentence as replacing the theme wholesale is why the consumer's opt-in became 0.0 under a preset.

## Later record

**iOS was fixed by the placement, not by a fill.** [#30](https://github.com/kihyun1998/flutter_syntax_highlight/issues/30) measured it on the iPhone 17 simulator (Flutter 3.47.1, 2026-10-23): with the defaults, dragging the horizontal thumb 140 px moves 361.3, and dragging the text itself moves 120 — on iOS the selection gesture does not take the horizontal drag. The 0.0 above reproduced only on the code before #29, where with `scrollable: true` the bar sat after the last line. So the fill stays Android-only, and "the only horizontal affordance on touch" holds on Android only.
