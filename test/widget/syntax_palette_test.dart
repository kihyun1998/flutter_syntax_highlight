import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_syntax_highlight/flutter_syntax_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

/// Judged with both a coloured and an uncoloured scheme. The derived default's
/// claim is not "achromatic" but "**hue-neutral to the consumer's scheme**",
/// so the claim is only tested when checked on the coloured side.
final colourful = ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4));
final monochrome = ColorScheme.fromSeed(
  seedColor: const Color(0xFF000000),
  dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
);

void main() {
  group('fromColorScheme — a default right in both light and dark with no '
      'setup', () {
    test('covers all eight kinds, and only plain inherits the root', () {
      // `function` used to be here too. The reason was that there was no axis
      // to give it, and ADR-0003 removed that reason — there is an axis that
      // borrows the app's accent, diluted.
      final palette = SyntaxPalette.fromColorScheme(colourful);
      final inherits = {DartTokenKind.plain};
      for (final kind in DartTokenKind.values) {
        expect(
          palette.styleFor(kind),
          inherits.contains(kind) ? isNull : isNotNull,
          reason: '$kind',
        );
      }
    });

    test('every kind given a style is distinguishable from plain', () {
      // A trap a palette that distinguishes without hue falls into easily:
      // the root is already `onSurface`, so giving `onSurface` does nothing.
      // It was actually written that way once and this check caught it.
      final palette = SyntaxPalette.fromColorScheme(colourful);
      for (final kind in DartTokenKind.values) {
        final style = palette.styleFor(kind);
        if (style == null) continue;
        expect(
          style.color != colourful.onSurface ||
              style.fontWeight != null ||
              style.fontStyle != null,
          isTrue,
          reason: '$kind was given a style but draws the same as the root',
        );
      }
    });

    test('invents no hue absent from the scheme', () {
      // This is the derived default's whole claim. The reference wrote
      // "achromatic", but the ground for that was that the host app's scheme
      // was monochrome to begin with, so **there was no hue to take**. A
      // consumer's scheme can be coloured, so that sentence, carried over as
      // is, becomes false.
      //
      // The claim is not "uses only the three roles' values" but **"introduces
      // no hue of its own"**. ADR-0003 overturned the first form; the second
      // stands. So it is measured in two directions.

      // (a) If the app is achromatic, so is the palette. A colour brought in
      // leaks here.
      final grey = SyntaxPalette.fromColorScheme(monochrome);
      for (final kind in DartTokenKind.values) {
        final colour = grey.styleFor(kind)?.color;
        if (colour == null) continue;
        expect(colour.r, closeTo(colour.g, 0.02), reason: '$kind');
        expect(colour.g, closeTo(colour.b, 0.02), reason: '$kind');
      }

      // (b) On a coloured scheme, a pulled colour lies **between the anchor
      // and the target**. This is used instead of pinning values because the
      // dilution coefficient is set by measurement and can be measured again
      // — the property must hold when the coefficient changes, and an
      // arbitrary colour is caught here regardless of the coefficient.
      final palette = SyntaxPalette.fromColorScheme(colourful);
      void between(Color got, Color anchor, Color target, String what) {
        for (final read in <double Function(Color)>[
          (c) => c.r,
          (c) => c.g,
          (c) => c.b,
        ]) {
          final lo = min(read(anchor), read(target));
          final hi = max(read(anchor), read(target));
          expect(
            read(got),
            inInclusiveRange(lo - 0.01, hi + 0.01),
            reason: '$what left the range between anchor and target',
          );
        }
      }

      between(
        palette.string!.color!,
        colourful.onSurfaceVariant,
        colourful.tertiary,
        'string',
      );
      between(
        palette.function!.color!,
        colourful.onSurface,
        colourful.primary,
        'function',
      );
      for (final kind in [DartTokenKind.number, DartTokenKind.punctuation]) {
        expect(
          {colourful.onSurfaceVariant, colourful.outline},
          contains(palette.styleFor(kind)!.color),
          reason: '$kind is a kind that is not pulled',
        );
      }
    });

    test('comments are not dimmed', () {
      // This turns the convention over. The usual highlighter dims comments
      // and brightens keywords, which assumes **skimming code one already
      // knows**. The code this package draws is mostly placed there to be
      // read, and there a comment is not a side note.
      //
      // The firmer ground: anyone who knows Dart can read keywords and
      // punctuation back out of the code, but **a comment is the only part
      // that cannot be recovered from the code**. Picking out exactly what
      // cannot be recovered and dimming it is backwards.
      final palette = SyntaxPalette.fromColorScheme(colourful);
      final comment = palette.styleFor(DartTokenKind.comment)!;

      expect(
        comment.fontStyle,
        FontStyle.italic,
        reason: 'italic sets it apart',
      );
      expect(
        comment.color,
        anyOf(isNull, equals(colourful.onSurface)),
        reason:
            'the comment was dimmed — keeping its contrast is this '
            'palette\'s decision',
      );
    });

    test('punctuation is what recedes', () {
      // The order must hold even after strings gained hue: punctuation recedes
      // furthest, and literals sit in front of it. Comparing values would
      // break every time the dilution coefficient changes, so **the order**
      // is measured.
      final palette = SyntaxPalette.fromColorScheme(colourful);
      expect(
        palette.styleFor(DartTokenKind.punctuation)!.color,
        colourful.outline,
      );

      double gap(Color c) =>
          (c.computeLuminance() - colourful.surface.computeLuminance()).abs();

      expect(
        gap(palette.styleFor(DartTokenKind.punctuation)!.color!),
        lessThan(gap(palette.styleFor(DartTokenKind.string)!.color!)),
        reason: 'punctuation must recede one step further than strings',
      );
    });

    test('keywords are set apart by weight, not colour — and heavier', () {
      // Distinguishing without hue needs an axis other than colour. But using
      // an axis is not enough — **lowering** the weight makes keywords fainter
      // than ordinary code. Unless the direction is pinned too, that mutant
      // passes.
      final palette = SyntaxPalette.fromColorScheme(colourful);
      final keyword = palette.styleFor(DartTokenKind.keyword)!;
      expect(keyword.color, isNull);
      expect(
        keyword.fontWeight!.value,
        greaterThan(FontWeight.normal.value),
        reason: 'keywords draw fainter than ordinary code',
      );
    });

    test('escape follows the literal, and number stays behind on purpose', () {
      // The three sat in the same place. They split when ADR-0003 pulled
      // `string`, and the direction of that split is the decision.
      //
      // `escape` **follows** — it is part of its literal, and in the preset
      // survey (#9) four of the ten painted escape the same colour as number.
      // `number` **stays** — that is what creates the distinction between
      // strings and numbers that did not exist before.
      final palette = SyntaxPalette.fromColorScheme(colourful);

      expect(
        palette.escape,
        palette.string,
        reason: 'escape came apart from the literal',
      );
      expect(
        palette.number!.color,
        colourful.onSurfaceVariant,
        reason:
            'moving number along too leaves the two unmoved relative to each '
            'other',
      );
      expect(palette.number!.color, isNot(palette.string!.color));

      // None of the three drops to punctuation's place. If one did, the
      // literal would look as if it switched off halfway.
      for (final kind in [
        DartTokenKind.string,
        DartTokenKind.number,
        DartTokenKind.escape,
      ]) {
        expect(
          palette.styleFor(kind)!.color,
          isNot(colourful.outline),
          reason: '$kind',
        );
      }
    });

    test('light and dark produce different values', () {
      // Deriving prevents what a hard-coded palette does: break quietly at the
      // opposite brightness.
      final light = SyntaxPalette.fromColorScheme(
        ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
      );
      final dark = SyntaxPalette.fromColorScheme(
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
      );
      expect(
        light.styleFor(DartTokenKind.string)!.color,
        isNot(dark.styleFor(DartTokenKind.string)!.color),
      );
    });
  });

  group('wiring of styleFor', () {
    // **Plugs a different marker into each kind to check the wiring itself.**
    // Without this, a switch that swaps two slots, like `escape => number`,
    // passes everything — because in the derived default the two are the
    // same style. Four such mutants actually survived.
    //
    // `fontSize` is the marker because the palette never uses it. With colour
    // or weight, markers and real values mix.
    const wired = SyntaxPalette(
      plain: TextStyle(fontSize: 1),
      comment: TextStyle(fontSize: 2),
      keyword: TextStyle(fontSize: 3),
      string: TextStyle(fontSize: 4),
      number: TextStyle(fontSize: 5),
      punctuation: TextStyle(fontSize: 6),
      escape: TextStyle(fontSize: 7),
      function: TextStyle(fontSize: 8),
    );
    const expected = <DartTokenKind, double>{
      DartTokenKind.plain: 1,
      DartTokenKind.comment: 2,
      DartTokenKind.keyword: 3,
      DartTokenKind.string: 4,
      DartTokenKind.number: 5,
      DartTokenKind.punctuation: 6,
      DartTokenKind.escape: 7,
      DartTokenKind.function: 8,
    };

    test('each of the eight kinds goes to its own slot', () {
      // There must be as many markers as kinds — miss one and that wiring
      // goes unchecked.
      expect(expected.keys.toSet(), DartTokenKind.values.toSet());
      for (final entry in expected.entries) {
        expect(
          wired.styleFor(entry.key)?.fontSize,
          entry.value,
          reason: 'wiring of ${entry.key} is off',
        );
      }
    });
  });

  group('value equality', () {
    // When `SyntaxText` takes a palette as a parameter, `didUpdateWidget` uses
    // this to decide whether to recompute. Without it, two palettes derived
    // from the same scheme look different and the tokens get repainted on
    // every rebuild.
    test('equal values are equal', () {
      final a = SyntaxPalette.fromColorScheme(colourful);
      final b = SyntaxPalette.fromColorScheme(colourful);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differing in one slot makes them differ', () {
      const a = SyntaxPalette(comment: TextStyle(fontSize: 1));
      const b = SyntaxPalette(comment: TextStyle(fontSize: 2));
      expect(a, isNot(b));
    });
  });

  group('building your own', () {
    test('a few lines make your own palette', () {
      const mine = SyntaxPalette(
        comment: TextStyle(color: Color(0xFF888888)),
        keyword: TextStyle(color: Color(0xFF0000FF)),
      );
      expect(
        mine.styleFor(DartTokenKind.comment)!.color,
        const Color(0xFF888888),
      );
      // A kind not given is null — it inherits the root style.
      expect(mine.styleFor(DartTokenKind.string), isNull);
    });

    test('can be built const', () {
      // The consumer must be able to embed it in the widget tree as a
      // constant, so that no new object is made on every rebuild.
      const a = SyntaxPalette(comment: TextStyle(fontStyle: FontStyle.italic));
      const b = SyntaxPalette(comment: TextStyle(fontStyle: FontStyle.italic));
      expect(identical(a, b), isTrue);
    });
  });

  group('no style specifies a fontFamily', () {
    // A hard rule. A leaf that names a family is drawn in a proportional font
    // while a guard that reads the wrapper, `EditableText.style`, stays green.
    // This repository has paid for that bug once, and the palette is a place
    // that could bring it back.
    test('nor does the derived default', () {
      final palette = SyntaxPalette.fromColorScheme(colourful);
      for (final kind in DartTokenKind.values) {
        final style = palette.styleFor(kind);
        expect(style?.fontFamily, isNull, reason: '$kind');
        expect(style?.fontFamilyFallback, isNull, reason: '$kind');
      }
    });
  });
}
