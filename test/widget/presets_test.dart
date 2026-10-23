import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_syntax_highlight/flutter_syntax_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every named preset.
///
/// **This list is written out again by hand, and that is the point.** The
/// package decided not to have a name lookup (the decision not to build a
/// registry), so lib has no list to iterate here. A preset that is added but
/// not put in this list ships without passing a single check below — that
/// risk remains, and it is not hidden.
const presets = <String, SyntaxPalette>{
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

void main() {
  test('there are ten', () {
    expect(presets, hasLength(10));
  });

  group('shape', () {
    test('all seven slots have a colour', () {
      // The survey filled seven slots. An empty slot drops that kind to the
      // root colour, and in a coloured palette that is an accident, not a
      // decision.
      const seven = [
        DartTokenKind.plain,
        DartTokenKind.comment,
        DartTokenKind.keyword,
        DartTokenKind.string,
        DartTokenKind.number,
        DartTokenKind.escape,
        DartTokenKind.function,
      ];
      presets.forEach((name, palette) {
        for (final kind in seven) {
          expect(
            palette.styleFor(kind)?.color,
            isNotNull,
            reason: '$kind of $name',
          );
        }
      });
    });

    test('punctuation equals plain', () {
      // None of the 9 surveyed themes gives punctuation a colour of its own.
      // Only the derived default dims punctuation, and that is because it has
      // to distinguish without hue — a coloured preset has no such need.
      presets.forEach((name, palette) {
        expect(
          palette.styleFor(DartTokenKind.punctuation)?.color,
          palette.styleFor(DartTokenKind.plain)?.color,
          reason: name,
        );
      });
    });

    test('no preset names a fontFamily', () {
      // A hard rule. A leaf that names a family is drawn in a proportional
      // font while a guard that reads the wrapper stays green.
      presets.forEach((name, palette) {
        for (final kind in DartTokenKind.values) {
          final style = palette.styleFor(kind);
          expect(style?.fontFamily, isNull, reason: '$kind of $name');
          expect(style?.fontFamilyFallback, isNull, reason: '$kind of $name');
        }
      });
    });

    test('they differ from each other', () {
      // Catches a preset copied and pasted without changing its values.
      final seen = <SyntaxPalette, String>{};
      presets.forEach((name, palette) {
        expect(
          seen,
          isNot(contains(palette)),
          reason: '$name is identical to ${seen[palette]}',
        );
        seen[palette] = name;
      });
    });
  });

  group('background', () {
    test('all ten carry their own background', () {
      for (final e in presets.entries) {
        expect(
          e.value.background,
          isNotNull,
          reason:
              '${e.key} has no background — the colours were picked on a '
              'particular background, so shipping them without it loses the '
              'contrast the original set',
        );
      }
    });

    test('the derived default gives no background', () {
      // The surface the app has already painted is the right background for
      // this palette. Painting anything here detaches the code block alone
      // from the app.
      final derived = SyntaxPalette.fromColorScheme(
        ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
      );
      expect(derived.background, isNull);
    });

    test('body text is at least 4.1:1 on its own background', () {
      // **This check replaces the docs' claim.** An earlier version wrote that
      // presets "are invisible at the opposite brightness" and gave `cobalt2`
      // a contrast ratio of 1.00, but that was white body text measured
      // against *the app's* surface — the palette carried no background, so
      // there was nothing else to measure against.
      //
      // The floor sits at 4.1 not for WCAG AA (4.5) but **just under the
      // measured minimum**: solarizedLight is 4.13, and upstream set that
      // value, so we cannot raise it. Requiring AA would require something
      // that cannot pass; going lower would stay quiet even if upstream
      // changed the values.
      for (final e in presets.entries) {
        final ratio = _contrast(e.value.background!, e.value.plain!.color!);
        expect(
          ratio,
          greaterThan(4.1),
          reason:
              '${e.key}: body text is '
              '${ratio.toStringAsFixed(2)}:1 on its own background',
        );
      }
    });

    test('cobalt2 reads on its own background, not the app surface', () {
      // While the check above runs over all ten at once, this one names and
      // keeps **what changed**. The same white body text, two backgrounds.
      const white = Color(0xFFFFFFFF);
      expect(SyntaxPalette.cobalt2.plain!.color, white);
      expect(_contrast(const Color(0xFFFDF7FF), white), lessThan(1.1));
      expect(
        _contrast(SyntaxPalette.cobalt2.background!, white),
        greaterThan(12.0),
      );
    });
  });

  group('does not drift from the values the survey recorded', () {
    test('exactly four have escape equal to number', () {
      // What the survey (#9) counted: only the one family and the tokyoNight
      // family have a dedicated rule for `constant.character.escape`; the
      // other four are absorbed by the parent `constant` rule. **The
      // originals really are like that** — we did not extract them wrongly.
      //
      // This check catches errors made while copying the values over.
      final same = presets.entries
          .where(
            (e) =>
                e.value.styleFor(DartTokenKind.escape)?.color ==
                e.value.styleFor(DartTokenKind.number)?.color,
          )
          .map((e) => e.key)
          .toSet();
      expect(same, {'monokai', 'gruvboxDark', 'gruvboxLight', 'cobalt2'});
    });

    test('monokai is the only one whose comments are not italic', () {
      final upright = presets.entries
          .where(
            (e) =>
                e.value.styleFor(DartTokenKind.comment)?.fontStyle !=
                FontStyle.italic,
          )
          .map((e) => e.key)
          .toSet();
      expect(upright, {'monokai'});
    });

    test('there are four brightness pairs and each differs', () {
      // A named preset is a hard-coded palette, so it breaks at the opposite
      // brightness. That is why a preset whose original has a pair ships as a
      // pair — there must be something to pick when brightness changes.
      const pairs = {
        'solarizedDark': 'solarizedLight',
        'oneDark': 'oneLight',
        'gruvboxDark': 'gruvboxLight',
        'tokyoNight': 'tokyoNightLight',
      };
      pairs.forEach((dark, light) {
        expect(
          presets[dark]!.styleFor(DartTokenKind.plain)?.color,
          isNot(presets[light]!.styleFor(DartTokenKind.plain)?.color),
          reason: '$dark and $light have the same body colour',
        );
      });
    });
  });

  group('NOTICES', () {
    late final String notices;
    setUpAll(() => notices = File('NOTICES').readAsStringSync());

    test('the file exists and is not empty', () {
      expect(notices.trim(), isNotEmpty);
    });

    test('every upstream copyright line is present', () {
      // The one thing the seven MIT licences all require is **keeping the
      // notice**. This file does that, which makes the "are hex values
      // copyrightable" debate moot.
      for (final holder in [
        'Ethan Schoonover',
        'Microsoft Corporation',
        'GitHub Inc.',
        'Colorsublime.com',
        'Enkia',
        'Wes Bos',
        'JD', // copyright holder of the gruvbox port
      ]) {
        expect(notices, contains(holder), reason: holder);
      }
      // The canonical gruvbox has no copyright line, so there is nothing to
      // copy over. The original author goes in as **attribution**, not as a
      // copyright notice.
      expect(notices, contains('Pavel Pertsev'));
    });

    test('names the files the values came from, down to the commit', () {
      // The same theme has different licences in different versions. Without
      // which file the values came from, that judgement cannot be made again
      // later.
      // Pins the exact count. With `>= 5`, two could vanish and it stays green.
      expect(
        RegExp(r'[0-9a-f]{40}').allMatches(notices).length,
        7,
        reason: 'commit-pinned sources went down',
      );
    });

    test('background values are also listed with their source', () {
      // Backgrounds were added later, so they are the values most easily left
      // out of the notice.
      for (final e in presets.entries) {
        final hex = e.value.background!
            .toARGB32()
            .toRadixString(16)
            .substring(2);
        expect(
          notices.toUpperCase(),
          contains('#${hex.toUpperCase()}'),
          reason: 'background #$hex of ${e.key} is not in NOTICES',
        );
      }
    });

    test('ships in the package', () {
      // `.pubignore` replaces `.gitignore`, so what is not listed here is not
      // left out but **goes in**. Conversely, it can be left out by mistake.
      final ignore = File('.pubignore').readAsStringSync();
      expect(ignore, isNot(contains('NOTICES')));
    });
  });
}

/// WCAG relative luminance contrast.
double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}
