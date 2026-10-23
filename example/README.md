# flutter_syntax_highlight example

One screen. Its purpose is to show the things below **to the eye**.

## 1. Nested interpolation is drawn correctly

The sample shown contains this line:

```dart
return '${value ? '✓' : '✗'} $key\t$tidy\n$rows';
```

The inner `'✓'` and `'✗'` are drawn **as strings**. A scanner that simply pairs
quotes paints exactly the opposite — the code inside the interpolation as
string, and the string as code. It is the reason this package exists, and the
glyph a screenshot should point at.

## 2. The derived default comes from the app's scheme

Check it with the **seed swatches** in the app bar. Change the seed and the
colours of strings and call names move along with the scheme — this package
only borrows the app's hues and introduces no hue of its own.

The last swatch (achromatic) is the other side of that claim: with no colour to
borrow, no colour comes out.

## 3. And it is right in both light and dark

Check it with the brightness toggle in the app bar. The default palette is
derived from the consumer's `ColorScheme`, so it is right in both with nothing
to configure.

The same toggle also shows the difference from the presets: pick `oneDark` in
the dropdown and only the code block carries its own background and stands
apart from the app. The derived default does not — it paints no background and
uses the app's surface as is.

An earlier version of this paragraph claimed something else: that *a named
preset is invisible in the opposite brightness*, and it gave `cobalt2`'s
contrast ratio as 1.05. **The number was right and the thing measured against
was wrong** — at the time the palette had no background field, so white body
text was measured against *the app's* light background. Now it is drawn on its
own background `#193549`, and that contrast is 12.75. The account is in
[ADR-0002](../docs/adr/0002-a-palette-carries-its-own-background.md).

The reason for shipping pairs remains, but its grounds changed: not legibility
but **brightness preference**. `oneDark` in a light app reads fine, but only
the code block is dark.

## 4. The mouse wheel glides

The **mouse icon** in the app bar switches to the wheel demo. The sample above
fits entirely in an 800×600 window and does not scroll on either axis, so the
demo uses a sample longer and wider than the window. Roll the wheel, and push
sideways with Shift+wheel.

The dropdown changes `wheelMotion`: the default spring, a bouncy spring, curve,
lerp, and `null` (no animation). Switching keeps the scroll position, so you can
compare at the same spot. The first screen is what the screenshot points at, so
it was left untouched.

## This example holds the palette list itself

The package has no lookup by name — it was a decision not to build a registry.
So the eleven entries in the dropdown are the `palettes` constant in
`lib/main.dart`. This is exactly what a consumer who wants to offer a choice of
presets ends up doing.

## Running

```
cd example
flutter run -d macos      # or -d chrome
```

Only the macOS and web platform folders are included. If you need another
platform:

```
flutter create --platforms=android,ios,windows,linux .
```

## Why there are no tests

`flutter test` run from the root **does not run** this directory (confirmed by
planting a failing test — the root's 116 still passed as they were). A test put
here would be a test nobody runs, and that is worse than none.

Compilation is covered — the root's `flutter analyze` looks at this directory
too. Confirmed by planting an error. `analyze` **walks the tree**: at one point
this example was bound into a pub workspace and that was written down as the
reason for the coverage, but removing the workspace and measuring again, it was
caught all the same. It was a false justification, and the workspace was taken
out.

`dart format` is covered too. The gate is `lib test example/lib` — at first it
was `lib test` and this directory was left out, and #21 widened it. This code
is shown as is on pub.dev's example tab, where consumers read it.
