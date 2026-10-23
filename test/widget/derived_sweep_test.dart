import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_syntax_highlight/flutter_syntax_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

/// Measures the derived default against **the whole colour wheel, not one
/// scheme**.
///
/// Presets have fixed values, so measuring the ten is the end of it, but for
/// the derived palette the consumer's schemes are unbounded. A coefficient
/// picked by eye on one's own seed is right only on that seed.
///
/// The palette already carries both marks itself: `onSurfaceVariant` and
/// `onSurface` differ by ΔE 9.9, and **that was barely visible in the
/// screenshot**. `outline` and `onSurface` are 29.9 apart, and that is clearly
/// visible. The new distinctions must sit between the two, and every floor
/// below is above the lower mark.
const _hueStep = 30;
const _tooSubtle =
    9.9; // onSurfaceVariant vs onSurface, measured on the same sweep

double _lin(double v) =>
    v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b);

double _contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

/// CIE Lab (D65). Contrast ratio looks **only at luminance**, so it cannot
/// measure a difference in hue — red and green can have the same contrast
/// ratio. What this palette adds is hue, so this is the ruler needed here.
List<double> _lab(Color c) {
  final r = _lin(c.r), g = _lin(c.g), b = _lin(c.b);
  final x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047;
  final y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
  final z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883;
  double f(double t) =>
      t > 0.008856 ? pow(t, 1 / 3).toDouble() : (7.787 * t) + 16 / 116;
  final fx = f(x), fy = f(y), fz = f(z);
  return [116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)];
}

double _deltaE(Color a, Color b) {
  final p = _lab(a), q = _lab(b);
  return sqrt(pow(p[0] - q[0], 2) + pow(p[1] - q[1], 2) + pow(p[2] - q[2], 2));
}

/// The whole colour wheel × brightness. Calls [probe] for each scheme.
void _sweep(void Function(ColorScheme scheme, SyntaxPalette palette) probe) {
  for (var hue = 0; hue < 360; hue += _hueStep) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      final scheme = ColorScheme.fromSeed(
        seedColor: HSLColor.fromAHSL(1, hue.toDouble(), 0.7, 0.5).toColor(),
        brightness: brightness,
      );
      probe(scheme, SyntaxPalette.fromColorScheme(scheme));
    }
  }
}

void main() {
  group('Derived default — across the whole colour wheel', () {
    test('all four new distinctions sit above the "barely visible" mark', () {
      // These four are everything this palette buys by borrowing the app's
      // accent. If any one drops below the mark, that kind might as well not
      // be there.
      final floors = <String, double>{};
      _sweep((scheme, p) {
        void note(String k, double v) =>
            floors[k] = floors.containsKey(k) ? min(floors[k]!, v) : v;

        final plain = scheme.onSurface;
        note('string↔plain', _deltaE(p.string!.color!, plain));
        note('string↔number', _deltaE(p.string!.color!, p.number!.color!));
        note('function↔plain', _deltaE(p.function!.color!, plain));
        note('function↔string', _deltaE(p.function!.color!, p.string!.color!));
      });

      for (final e in floors.entries) {
        expect(
          e.value,
          greaterThan(_tooSubtle),
          reason:
              '${e.key} is at ΔE ${e.value.toStringAsFixed(1)}, below the '
              '"barely visible" mark ($_tooSubtle)',
        );
      }
    });

    test('pulled colours are safer on surface than this palette\'s existing '
        'floor', () {
      // No new floor is set. **What is already shipped** is used as the floor
      // — `outline` (punctuation) is the worst value this palette already
      // claims is readable, and a new colour worse than that is a regression.
      _sweep((scheme, p) {
        final floor = _contrast(scheme.outline, scheme.surface);
        for (final e in {
          'string': p.string!.color!,
          'escape': p.escape!.color!,
          'function': p.function!.color!,
        }.entries) {
          expect(
            _contrast(e.value, scheme.surface),
            greaterThanOrEqualTo(floor),
            reason: '${e.key} is harder to read than punctuation',
          );
        }
      });
    });

    test('escape is the same colour as its literal', () {
      _sweep((scheme, p) => expect(p.escape, p.string));
    });

    test('still introduces no hue of its own', () {
      // The anchor is always a neutral role and the target is **the app's**
      // role. So on a grey scheme the derived palette must be grey too — if
      // it brought in a colour, it shows here.
      final grey = ColorScheme.fromSeed(
        seedColor: const Color(0xFF000000),
        dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
      );
      final p = SyntaxPalette.fromColorScheme(grey);
      for (final c in [p.string!.color!, p.function!.color!]) {
        expect(c.r, closeTo(c.g, 0.02));
        expect(c.g, closeTo(c.b, 0.02));
      }
    });
  });
}
