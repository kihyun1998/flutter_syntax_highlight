import 'package:flutter/material.dart';
import 'package:flutter_syntax_highlight/flutter_syntax_highlight.dart';

void main() => runApp(const ExampleApp());

/// The sample to show.
///
/// **The point is that it contains a nested interpolation.** In
/// `'${term.value ? '✓' : '✗'}'` the inner `'✓'` is visibly drawn **as a
/// string** — a scanner that simply pairs quotes paints exactly the opposite.
/// It is the reason this package exists, and the glyph a screenshot should
/// point at.
///
/// The rest was chosen so that all eight kinds appear: comment, keyword,
/// string, number, punctuation, escape, call name, and plain identifier.
const sample = r'''
// A ledger line, rendered by the package that draws this page.
class Term {
  const Term(this.key, {this.value = false});

  final String key;
  final bool value;

  /// The three interpolation sites this package exists for.
  String describe(List<String> selected, String? newValue) {
    final tidy = '${newValue ?? ''}'.trim();
    final rows = 'selectedRows: ${selected.join(', ')}';
    return '${value ? '✓' : '✗'} $key\t$tidy\n$rows';
  }

  static const limit = 0xFF;
  static const ratio = 1.5e3;
}
''';

/// The palettes to choose from.
///
/// **The package has no lookup by name** — a consumer who wants to offer a
/// choice of presets writes their own list. This is that list, and this file
/// is the only consumer of that decision.
///
/// Only the first entry is null: passing no palette means
/// `SyntaxPalette.fromColorScheme` is used, and only that one is right in both
/// light and dark with nothing to configure.
const palettes = <String, SyntaxPalette?>{
  'Derived from ColorScheme (default)': null,
  'solarizedDark': SyntaxPalette.solarizedDark,
  'solarizedLight': SyntaxPalette.solarizedLight,
  'oneDark': SyntaxPalette.oneDark,
  'oneLight': SyntaxPalette.oneLight,
  'monokai': SyntaxPalette.monokai,
  'gruvboxDark': SyntaxPalette.gruvboxDark,
  'gruvboxLight': SyntaxPalette.gruvboxLight,
  'tokyoNight': SyntaxPalette.tokyoNight,
  'tokyoNightLight': SyntaxPalette.tokyoNightLight,
  'cobalt2': SyntaxPalette.cobalt2,
};

/// The seeds to choose from.
///
/// **A device that demonstrates the claim that the derived default comes from
/// the app's scheme.** A claim made only in words is shown to the eye by
/// changing the seed — the colours of strings and call names move along with
/// the scheme.
///
/// The last entry is the point: with an achromatic scheme **the palette becomes
/// achromatic too.** This package only borrows the app's hues and introduces no
/// hue of its own, so with nothing to borrow, no colour comes out.
class Seed {
  const Seed(
    this.label,
    this.colour, {
    this.variant = DynamicSchemeVariant.tonalSpot,
  });

  final String label;
  final Color colour;
  final DynamicSchemeVariant variant;
}

/// The motions to choose from in the wheel demo.
///
/// The first entry is `SyntaxText`'s default, and the last, `null`, turns the
/// animation off. Switching keeps the scroll position, so you can roll the
/// wheel at the same spot and compare.
const motions = <String, WheelMotion?>{
  'spring (default)': WheelMotion.spring(),
  'spring 250ms, bounce 0.2': WheelMotion.spring(
    duration: Duration(milliseconds: 250),
    bounce: 0.2,
  ),
  'curve easeOut': WheelMotion.curve(curve: Curves.easeOut),
  'lerp': WheelMotion.lerp(),
  'off (null)': null,
};

/// The wheel demo's sample. **It has to be longer and wider than the window**
/// for the wheel to have something to move — [sample] fits entirely in an
/// 800×600 window and does not scroll on either axis. Horizontal movement is
/// Shift+wheel.
final wheelSample = [
  '// Long and wide on purpose: turn the wheel, then Shift+wheel.',
  'class Ledger {',
  for (var i = 0; i < 120; i++)
    "  static const line$i = 'a deliberately long string literal, so that this "
        "line runs well past the right edge of the window: $i';",
  '}',
].join('\n');

const seeds = <Seed>[
  Seed('Purple', Color(0xFF6750A4)),
  Seed('Teal', Color(0xFF006B5F)),
  Seed('Orange', Color(0xFFB3541E)),
  Seed('Blue', Color(0xFF0B57D0)),
  Seed(
    'Achromatic',
    Color(0xFF5A5A5A),
    variant: DynamicSchemeVariant.monochrome,
  ),
];

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  var _brightness = Brightness.light;
  var _seed = seeds.first;
  var _palette = palettes.keys.first;
  var _wheelDemo = false;
  var _motion = motions.keys.first;

  @override
  Widget build(BuildContext context) {
    final isLight = _brightness == Brightness.light;
    return MaterialApp(
      title: 'flutter_syntax_highlight',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed.colour,
          brightness: _brightness,
          dynamicSchemeVariant: _seed.variant,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('flutter_syntax_highlight'),
          actions: [
            // Seed swatches. A device that shows to the eye that the derived
            // default comes from the app's scheme, and the last swatch
            // (achromatic) shows "introduces no hue of its own" — with no
            // colour to borrow, no colour comes out.
            for (final seed in seeds)
              IconButton(
                tooltip: seed.label,
                onPressed: () => setState(() => _seed = seed),
                icon: Icon(
                  seed == _seed ? Icons.circle : Icons.circle_outlined,
                  color: seed.colour,
                  size: 18,
                ),
              ),
            const SizedBox(width: 8),
            // Brightness toggle. A device that shows to the eye the claim that
            // the derived default is right in both, and it also shows a named
            // preset becoming invisible in the opposite brightness.
            IconButton(
              tooltip: isLight ? 'Switch to dark' : 'Switch to light',
              icon: Icon(
                isLight ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              ),
              onPressed: () => setState(
                () =>
                    _brightness = isLight ? Brightness.dark : Brightness.light,
              ),
            ),
            // Wheel demo toggle. The first screen is what the screenshot
            // points at, so it is left as is, and the wheel is shown on a
            // sample long enough to overflow.
            IconButton(
              tooltip: _wheelDemo ? 'Back to the first screen' : 'Wheel demo',
              icon: Icon(_wheelDemo ? Icons.mouse : Icons.mouse_outlined),
              onPressed: () => setState(() => _wheelDemo = !_wheelDemo),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          // The default, `center`, leaves only the vertical that `Expanded`
          // stretches, and horizontally shrinks the code block to its own text
          // width and centres it. A code viewer has to fill the pane, and if it
          // does not, horizontal scrolling never even shows up on screen —
          // caught while taking screenshots.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _wheelDemo
                  ? _motionPicker()
                  : Row(
                      children: [
                        const Text('Palette'),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _palette,
                            items: [
                              for (final name in palettes.keys)
                                DropdownMenuItem(
                                  value: name,
                                  child: Text(name),
                                ),
                            ],
                            onChanged: (name) =>
                                setState(() => _palette = name ?? _palette),
                          ),
                        ),
                      ],
                    ),
            ),
            Expanded(
              child: SyntaxText(
                _wheelDemo ? wheelSample : sample,
                palette: palettes[_palette],
                wheelMotion: motions[_motion],
                copyTooltip: 'Copy',
                copiedTooltip: 'Copied',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _motionPicker() => Row(
    children: [
      const Text('Wheel'),
      const SizedBox(width: 12),
      Expanded(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _motion,
          items: [
            for (final name in motions.keys)
              DropdownMenuItem(value: name, child: Text(name)),
          ],
          onChanged: (name) => setState(() => _motion = name ?? _motion),
        ),
      ),
    ],
  );
}
