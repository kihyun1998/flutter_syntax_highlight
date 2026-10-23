import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_syntax_highlight/flutter_syntax_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

/// A snippet in which all eight kinds appear. A guard cannot protect a branch
/// it does not reach, so this makes the checks below pass through every arm
/// of `SyntaxPalette.styleFor`.
const everyKind =
    "// a comment\n"
    "class Sentinel {\n"
    "  final s = 'a\\nb';\n"
    "  var n = f(1);\n"
    "}\n";

/// Plants a proportional font in the theme. This is exactly what the monospace
/// checks must catch.
const chromeFont = 'NotAMonospaceFace';

Future<void> pump(WidgetTester tester, Widget child, {Brightness? b}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        fontFamily: chromeFont,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: b ?? Brightness.light,
        ),
      ),
      home: Scaffold(body: SizedBox(width: 400, height: 300, child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

/// The leaf spans. The point is to read **here**, not `EditableText.style`.
List<TextSpan> leavesOf(WidgetTester tester) {
  final selectable = tester.widget<SelectableText>(find.byType(SelectableText));
  final leaves = <TextSpan>[];
  selectable.textSpan!.visitChildren((span) {
    if (span is TextSpan && span.text != null) leaves.add(span);
    return true;
  });
  return leaves;
}

void main() {
  testWidgets('the fixture yields all eight kinds', (tester) async {
    // A side condition. If this snippet misses a kind, the checks below stay
    // green without passing through that arm.
    expect(
      tokenizeDart(everyKind).map((t) => t.kind).toSet(),
      DartTokenKind.values.toSet(),
    );
  });

  group('the highlighter cannot change what gets pasted', () {
    const tricky =
        "// somebody's file\r\n"
        "class Sentinel {\r\n"
        "  final s = '\${a ?? ''}';\r\n"
        "}\r\n";

    testWidgets('flattening the rendered tree gives exactly those bytes', (
      tester,
    ) async {
      await pump(tester, const SyntaxText(tricky));
      final selectable = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      // `includeSemanticsLabels: false` is not a matter of taste — it is the
      // very call the controller makes when building the string the
      // clipboard reads.
      expect(
        selectable.textSpan!.toPlainText(includeSemanticsLabels: false),
        tricky,
      );
    });

    testWidgets('and the copy control puts the same thing on the clipboard', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await pump(tester, const SyntaxText(tricky));
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(copied, tricky);
    });
  });

  group('monospace', () {
    testWidgets('the wrapper names a monospace face', (tester) async {
      await pump(tester, const SyntaxText(everyKind));
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.style.fontFamily, isNotNull);
      expect(editable.style.fontFamily, isNot(chromeFont));
    });

    testWidgets('a non-null family is named even with no fontFamily given', (
      tester,
    ) async {
      // Opening it up as nullable is a new path that could revive the old
      // bug. If null is read as "not set", `inherit: true` merges the ambient
      // style and it draws in a proportional font.
      await pump(tester, const SyntaxText(everyKind));
      final style = tester
          .widget<EditableText>(find.byType(EditableText))
          .style;

      expect(style.fontFamily, isNotNull);
      expect(style.fontFamilyFallback, isNotNull);

      // If the family is also in the fallback, `fallback.first` looks like the
      // family and hides the fact that no family was set at all. That shape
      // hid the bug.
      expect(style.fontFamilyFallback, isNot(contains(style.fontFamily)));

      // And resolution must end at a generic — either the family itself is
      // generic (as on Android), or the last of the fallback is.
      expect(
        style.fontFamily == 'monospace' ||
            style.fontFamilyFallback!.last == 'monospace',
        isTrue,
        reason:
            'monospace resolution does not end at a generic — on a device '
            'with none of the listed fonts it falls to a proportional font',
      );
    });

    test('names a monospace face per platform and leaves it out of the '
        'fallback', () {
      // Widget tests run as Android, so only one arm is exercised. Whether
      // the other arms keep the same invariant is checked here.
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      for (final platform in TargetPlatform.values) {
        debugDefaultTargetPlatformOverride = platform;
        final family = SyntaxText.defaultMonoFamily;
        final fallback = SyntaxText.fallbackWithout(family);
        expect(family, isNotEmpty, reason: '$platform');
        expect(fallback, isNot(contains(family)), reason: '$platform');
        expect(
          family == 'monospace' || fallback.last == 'monospace',
          isTrue,
          reason: 'resolution does not end at a generic on $platform',
        );
      }
    });

    testWidgets('and no leaf brings in a family of its own', (tester) async {
      // The check above reads **the wrapper**. `SelectableText` wraps the span
      // tree it is given in `TextSpan(style: ..., children: [what was
      // given])`, so even if a leaf names a proportional font the check above
      // stays green. That is the bug this repository has paid for once, and
      // this check is an addition, not a replacement.
      await pump(tester, const SyntaxText(everyKind));
      final families = <String>[];
      final foreign = <InlineSpan>[];
      tester
          .widget<SelectableText>(find.byType(SelectableText))
          .textSpan!
          .visitChildren((span) {
            if (span is! TextSpan) {
              foreign.add(span);
              return true;
            }
            if (span.style?.fontFamily != null) {
              families.add(span.style!.fontFamily!);
            }
            return true;
          });
      expect(families, isEmpty);
      // A child that is not a `TextSpan` writes `\u{FFFC}` into the copied
      // text.
      expect(foreign, isEmpty);
    });
  });

  group(
    'the palette is actually drawn — read from the leaves, not the object',
    () {
      testWidgets('the given palette\'s colour shows up on the leaves', (
        tester,
      ) async {
        const marker = Color(0xFF123456);
        await pump(
          tester,
          const SyntaxText(
            everyKind,
            palette: SyntaxPalette(comment: TextStyle(color: marker)),
          ),
        );
        final commentLeaves = leavesOf(
          tester,
        ).where((s) => s.text!.contains('a comment')).toList();
        expect(commentLeaves, isNotEmpty);
        expect(commentLeaves.single.style?.color, marker);
      });

      testWidgets('when none is given, one derived from ColorScheme is used', (
        tester,
      ) async {
        await pump(tester, const SyntaxText(everyKind));
        final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4));
        final expected = SyntaxPalette.fromColorScheme(scheme);
        final stringLeaf = leavesOf(
          tester,
        ).firstWhere((s) => s.text!.startsWith("'a"));
        expect(
          stringLeaf.style?.color,
          expected.styleFor(DartTokenKind.string)!.color,
        );
      });

      testWidgets('changing brightness changes the drawn colour with it', (
        tester,
      ) async {
        await pump(tester, const SyntaxText(everyKind));
        final light = leavesOf(
          tester,
        ).firstWhere((s) => s.text!.startsWith("'a")).style?.color;

        await pump(tester, const SyntaxText(everyKind), b: Brightness.dark);
        final dark = leavesOf(
          tester,
        ).firstWhere((s) => s.text!.startsWith("'a")).style?.color;

        expect(light, isNotNull);
        expect(
          dark,
          isNot(light),
          reason:
              'this is why the derived default exists — right on both sides '
              'with no setup',
        );
      });
    },
  );

  group('background', () {
    testWidgets('when the palette gives a background, that colour is painted', (
      tester,
    ) async {
      const marker = Color(0xFF123456);
      await pump(
        tester,
        const SyntaxText(
          everyKind,
          palette: SyntaxPalette(
            background: marker,
            plain: TextStyle(color: Color(0xFFEEEEEE)),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((w) => w is ColoredBox && w.color == marker),
        findsOneWidget,
      );
    });

    testWidgets('with no background given, nothing is painted', (tester) async {
      // What lies behind then is the app's surface. Painting anything here
      // breaks the derived default's decision to be "hue-neutral".
      await pump(tester, const SyntaxText(everyKind));

      final painted = tester.widgetList<ColoredBox>(
        find.descendant(
          of: find.byType(SyntaxText),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(painted, isEmpty);
    });

    testWidgets('the background sits outside the scroll view, so it covers the '
        'whole pane', (tester) async {
      // Placed inside, only the size of the scrolled content is painted, and a
      // pane wider than the code is left with an unpainted band. The code is
      // one line, but the pane is 400×300.
      const marker = Color(0xFF123456);
      await pump(
        tester,
        const SyntaxText(
          'var x = 1;',
          palette: SyntaxPalette(
            background: marker,
            plain: TextStyle(color: Color(0xFFEEEEEE)),
          ),
        ),
      );

      final box = tester.getSize(
        find.byWidgetPredicate((w) => w is ColoredBox && w.color == marker),
      );
      expect(box, const Size(400, 300));
    });

    testWidgets('scrollable: false shrinks the background vertically too', (
      tester,
    ) async {
      // This is the case of a code block inside prose. If the background fills
      // the pane's height, that use is gone — the opposite direction to the
      // check above, and both are needed.
      const marker = Color(0xFF123456);
      await pump(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: SyntaxText(
            'var x = 1;',
            scrollable: false,
            palette: SyntaxPalette(
              background: marker,
              plain: TextStyle(color: Color(0xFFEEEEEE)),
            ),
          ),
        ),
      );

      final box = tester.getSize(
        find.byWidgetPredicate((w) => w is ColoredBox && w.color == marker),
      );
      expect(box.height, lessThan(300));
      expect(box.height, greaterThan(0));
    });

    testWidgets('the copy icon follows the palette, not the app theme', (
      tester,
    ) async {
      // The app theme's `onSurfaceVariant` is a colour picked **against the
      // app's surface**, so on someone else's background it guarantees
      // nothing. A light app + a dark preset is exactly that case.
      const dim = Color(0xFF7F848E);
      await pump(
        tester,
        const SyntaxText(
          everyKind,
          palette: SyntaxPalette(
            background: Color(0xFF282C34),
            plain: TextStyle(color: Color(0xFFABB2BF)),
            comment: TextStyle(color: dim),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, dim);
    });
  });

  group('scrolling', () {
    testWidgets('the widget always owns horizontal', (tester) async {
      await pump(tester, const SyntaxText(everyKind, scrollable: false));
      final views = tester.widgetList<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(views.map((v) => v.scrollDirection), contains(Axis.horizontal));
    });

    testWidgets('with scrollable: false there is no vertical scroll', (
      tester,
    ) async {
      await pump(tester, const SyntaxText(everyKind, scrollable: false));
      final views = tester.widgetList<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(
        views.map((v) => v.scrollDirection),
        isNot(contains(Axis.vertical)),
      );
    });

    testWidgets(
      'with scrollable: true it scrolls vertically within its own area',
      (tester) async {
        final long = List.generate(200, (i) => 'final x$i = $i;').join('\n');
        await pump(tester, SyntaxText(long));
        final views = tester.widgetList<SingleChildScrollView>(
          find.byType(SingleChildScrollView),
        );
        expect(views.map((v) => v.scrollDirection), contains(Axis.vertical));

        final vertical = tester.widget<SingleChildScrollView>(
          find.byWidgetPredicate(
            (w) =>
                w is SingleChildScrollView &&
                w.scrollDirection == Axis.vertical,
          ),
        );
        // The package owns the controller by name. With `primary` on, two
        // scroll views claim the same `PrimaryScrollController` and the
        // framework asserts.
        expect(vertical.controller, isNotNull);
        expect(vertical.primary, isNot(true));
      },
    );
  });

  group('re-tokenizes when source changes', () {
    testWidgets('the new source is drawn', (tester) async {
      // Without this check, deleting the re-tokenize in `didUpdateWidget`
      // outright leaves the whole suite green — the source changed but the old
      // code is drawn.
      await pump(tester, const SyntaxText('const first = 1;'));
      String drawn() => tester
          .widget<SelectableText>(find.byType(SelectableText))
          .textSpan!
          .toPlainText(includeSemanticsLabels: false);
      expect(drawn(), 'const first = 1;');

      await pump(tester, const SyntaxText('const second = 2;'));
      expect(drawn(), 'const second = 2;');
    });

    testWidgets('and painted with the new source\'s kinds', (tester) async {
      // Separates out the case where only the text changes and the tokens stay
      // stale.
      await pump(tester, const SyntaxText('plain_identifier'));
      expect(leavesOf(tester).map((s) => s.text), ['plain_identifier']);

      await pump(tester, const SyntaxText('class X {}'));
      final texts = leavesOf(tester).map((s) => s.text).toList();
      expect(texts.first, 'class');
    });
  });

  group('values the consumer passes are actually used', () {
    testWidgets('font size and line height', (tester) async {
      await pump(
        tester,
        const SyntaxText(everyKind, fontSize: 33, height: 2.5),
      );
      final style = tester
          .widget<EditableText>(find.byType(EditableText))
          .style;
      expect(style.fontSize, 33);
      expect(style.height, 2.5);
    });

    testWidgets('font name and fallback', (tester) async {
      await pump(
        tester,
        const SyntaxText(
          everyKind,
          fontFamily: 'GivenMono',
          fontFamilyFallback: ['AlsoGiven'],
        ),
      );
      final style = tester
          .widget<EditableText>(find.byType(EditableText))
          .style;
      expect(style.fontFamily, 'GivenMono');
      expect(style.fontFamilyFallback, ['AlsoGiven']);
    });

    testWidgets('padding', (tester) async {
      await pump(
        tester,
        const SyntaxText(everyKind, padding: EdgeInsets.all(40)),
      );
      final padding = tester.widgetList<Padding>(find.byType(Padding));
      expect(padding.map((p) => p.padding), contains(const EdgeInsets.all(40)));
    });

    testWidgets('tooltip text', (tester) async {
      // If the package hard-codes user-visible strings, they cannot follow the
      // app's language.
      await pump(tester, const SyntaxText(everyKind, copyTooltip: 'Copy code'));
      expect(
        tester.widget<IconButton>(find.byType(IconButton)).tooltip,
        'Copy code',
      );
    });
  });

  group('scrolling actually moves', () {
    // **Drags from the viewport's centre, not the child's.** A long source's
    // `SelectableText` is bigger than the viewport, so its centre is off
    // screen, and a gesture dragged from there lands in thin air and moves
    // nothing — scrolling looks broken.
    final long = List.generate(
      80,
      (i) =>
          "final variable\$i = 'a rather long string literal number \$i here';",
    ).join('\n');

    ScrollController scrollOf(WidgetTester tester, Axis axis) => tester
        .widget<SingleChildScrollView>(
          find.byWidgetPredicate(
            (w) => w is SingleChildScrollView && w.scrollDirection == axis,
          ),
        )
        .controller!;

    ScrollController horizontalOf(WidgetTester tester) =>
        scrollOf(tester, Axis.horizontal);

    /// The bar that draws [controller].
    Finder barOf(ScrollController controller) => find.byWidgetPredicate(
      (w) => w is Scrollbar && w.controller == controller,
    );

    testWidgets('vertical scrolls by dragging', (tester) async {
      await pump(tester, SyntaxText(long));
      final vertical = tester.widget<SingleChildScrollView>(
        find.byWidgetPredicate(
          (w) =>
              w is SingleChildScrollView && w.scrollDirection == Axis.vertical,
        ),
      );
      expect(vertical.controller!.position.maxScrollExtent, greaterThan(0));

      await tester.dragFrom(
        tester.getCenter(find.byType(SyntaxText)),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();
      expect(vertical.controller!.position.pixels, greaterThan(0));
    });

    testWidgets('horizontal does not scroll by dragging — the price of being '
        'selectable', (tester) async {
      // Not a fault but a property. The selection gesture takes the
      // horizontal drag, and switching to `SelectionArea` is the same
      // (measured 2026-09-06). It cannot be fixed without giving up
      // selection, so the horizontal `Scrollbar` is the only affordance on
      // touch. This runs on the test default platform, Android; on iOS the
      // drag scrolls (#30).
      //
      // This check exists because once that fact is forgotten, someone strips
      // the scrollbar out as "decoration".
      await pump(tester, SyntaxText(long));
      final horizontal = tester.widget<SingleChildScrollView>(
        find.byWidgetPredicate(
          (w) =>
              w is SingleChildScrollView &&
              w.scrollDirection == Axis.horizontal,
        ),
      );
      expect(
        horizontal.controller!.position.maxScrollExtent,
        greaterThan(0),
        reason: 'lines were wrapped — a wrapped line is a different line',
      );

      await tester.dragFrom(
        tester.getCenter(find.byType(SyntaxText)),
        const Offset(-120, 0),
      );
      await tester.pumpAndSettle();
      expect(horizontal.controller!.position.pixels, 0);

      // That scrollbar merely being there is not enough — on Android it was
      // there but could not be dragged (#29). The group below measures
      // whether it drags.
    });

    group('the horizontal scrollbar drags on touch', () {
      // Measures whether the "only affordance" the check above speaks of is
      // actually usable. Material `Scrollbar` defaults `interactive` to false
      // on Android only, and the thumb appears only while scrolling and takes
      // no hits while transparent. The thumb is the only way to scroll
      // horizontally, so with the defaults as they are it can never be made
      // to appear in the first place. (#29, ADR-0004)

      /// The bottom of the widget area, near the left edge — where the
      /// horizontal thumb must be drawn. Does not move vertically. If the bar
      /// is drawn at the end of the content, it is not here.
      Future<void> dragThumb(WidgetTester tester) async {
        final box = tester.getRect(find.byType(SyntaxText));
        await tester.dragFrom(
          Offset(box.left + 30, box.bottom - 2),
          const Offset(140, 0),
        );
        await tester.pumpAndSettle();
      }

      for (final scrollable in [false, true]) {
        for (final (name, palette) in [
          ('derived default', null),
          ('preset with background', SyntaxPalette.oneDark),
        ]) {
          testWidgets('android, scrollable: $scrollable, $name', (
            tester,
          ) async {
            await pump(
              tester,
              SyntaxText(long, scrollable: scrollable, palette: palette),
            );
            await dragThumb(tester);
            expect(horizontalOf(tester).position.pixels, greaterThan(0));
          });
        }
      }

      testWidgets('a preset with a background does not wipe the app\'s '
          'scrollbar theme', (tester) async {
        // Only the colour is set by the palette. The remaining fields must read
        // as the app's — swapping the whole thing out would block the
        // consumer's way of turning bars on, for presets only.
        const appThumb = Color(0xFFFF0000);
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              scrollbarTheme: const ScrollbarThemeData(
                thickness: WidgetStatePropertyAll(11),
                thumbColor: WidgetStatePropertyAll(appThumb),
              ),
            ),
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: SyntaxText(long, palette: SyntaxPalette.oneDark),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final bars = ScrollbarTheme.of(
          tester.element(barOf(horizontalOf(tester))),
        );
        expect(bars.thickness?.resolve({}), 11);
        final thumb = bars.thumbColor?.resolve({});
        expect(thumb, isNot(appThumb));
        expect(
          thumb?.withAlpha(255),
          SyntaxPalette.oneDark.comment!.color!.withAlpha(255),
          reason:
              'the thumb colour must be a palette colour picked on the '
              'preset\'s background',
        );
      });

      testWidgets('on android, tapping where the bar is pages over', (
        tester,
      ) async {
        // Turning `interactive` on turns Flutter's track tap on with it. It
        // cannot be turned off separately, so it was accepted as the price
        // (ADR-0004). Touches in this band do not reach the text.
        await pump(tester, SyntaxText(long));
        final box = tester.getRect(find.byType(SyntaxText));
        await tester.tapAt(Offset(box.center.dx + 100, box.bottom - 2));
        await tester.pumpAndSettle();
        expect(horizontalOf(tester).position.pixels, greaterThan(0));
      });

      testWidgets(
        'a long press selects even with the bar always shown outermost',
        (tester) async {
          await pump(tester, SyntaxText(long));
          await tester.longPressAt(tester.getCenter(find.byType(SyntaxText)));
          await tester.pumpAndSettle();
          final selection = tester
              .state<EditableTextState>(find.byType(EditableText))
              .textEditingValue
              .selection;
          expect(selection.isCollapsed, isFalse);
        },
      );

      testWidgets('even with scrollable: true the horizontal bar is at the '
          'bottom of the widget area', (tester) async {
        await pump(tester, SyntaxText(long));
        expect(
          tester.getRect(barOf(horizontalOf(tester))).bottom,
          lessThanOrEqualTo(tester.getRect(find.byType(SyntaxText)).bottom),
          reason:
              'the horizontal bar is drawn at the end of the content — it '
              'shows only after scrolling all the way down',
        );
      });

      /// Whether [controller]'s bar is always shown. In exactly the order
      /// Material `Scrollbar` resolves it — the widget parameter, then the
      /// nearest theme, otherwise false.
      bool alwaysShown(WidgetTester tester, ScrollController controller) {
        final finder = barOf(controller);
        return tester.widget<Scrollbar>(finder).thumbVisibility ??
            ScrollbarTheme.of(
              tester.element(finder),
            ).thumbVisibility?.resolve({}) ??
            false;
      }

      testWidgets('if the app gives thumbVisibility: false, that wins', (
        tester,
      ) async {
        // The widget fills in only values nobody set. If the app turns it off,
        // the way to scroll horizontally on touch is gone, but that is the
        // app's choice.
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              scrollbarTheme: const ScrollbarThemeData(
                thumbVisibility: WidgetStatePropertyAll(false),
              ),
            ),
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: SyntaxText(long, scrollable: false),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(alwaysShown(tester, horizontalOf(tester)), isFalse);
        await dragThumb(tester);
        expect(horizontalOf(tester).position.pixels, 0);
      });

      testWidgets('does not fill in off android', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        try {
          await pump(tester, SyntaxText(long));
          final bar = tester.widget<Scrollbar>(barOf(horizontalOf(tester)));
          expect(bar.thumbVisibility, isNull);
          expect(bar.interactive, isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('the vertical bar is untouched on android too', (
        tester,
      ) async {
        // The defaults are filled in for the horizontal bar only. Vertical
        // scrolls by dragging, so there is no reason for its bar to be always
        // shown.
        await pump(tester, SyntaxText(long));
        final vertical = tester
            .widget<SingleChildScrollView>(
              find.byWidgetPredicate(
                (w) =>
                    w is SingleChildScrollView &&
                    w.scrollDirection == Axis.vertical,
              ),
            )
            .controller!;
        expect(alwaysShown(tester, vertical), isFalse);
        expect(alwaysShown(tester, horizontalOf(tester)), isTrue);
      });
    });

    group('scrollbars follow the widget area, not the screen inset', () {
      // Material `Scrollbar` passes `MediaQuery.paddingOf` straight into the
      // painter. That value is the **screen's** inset, but the bar is drawn
      // inside the widget area, so even with the widget in the middle of the
      // screen the bar was pushed in by that much and overlapped the last
      // line (#31). The default padding in widget tests is 0, so it is given
      // here explicitly.
      const inset = EdgeInsets.all(24);

      Future<void> pumpInset(
        WidgetTester tester,
        Widget child, {
        ScrollbarThemeData? bars,
      }) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(scrollbarTheme: bars),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 400,
                  height: 300,
                  child: Builder(
                    builder: (context) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(padding: inset),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      /// Whether [controller]'s bar hits its own track at screen position
      /// [at]. Asks about the painted track itself — the touch hit area widens
      /// to a radius of 24 around the thumb, so by dragging, a bar pushed in
      /// by 24 also hits.
      bool covers(WidgetTester tester, ScrollController controller, Offset at) {
        final finder = find
            .descendant(
              of: barOf(controller),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is CustomPaint && w.foregroundPainter is ScrollbarPainter,
              ),
            )
            .first;
        final painter =
            tester.widget<CustomPaint>(finder).foregroundPainter!
                as ScrollbarPainter;
        return painter.hitTest(at - tester.getTopLeft(finder)) ?? false;
      }

      for (final scrollable in [false, true]) {
        testWidgets(
          'the horizontal bar is at the widget bottom, edge to edge — '
          'scrollable: $scrollable',
          (tester) async {
            await pumpInset(tester, SyntaxText(long, scrollable: scrollable));
            final box = tester.getRect(find.byType(SyntaxText));
            final bar = horizontalOf(tester);
            expect(
              covers(tester, bar, box.bottomCenter - const Offset(0, 1)),
              isTrue,
            );
            expect(
              covers(tester, bar, box.bottomCenter - const Offset(0, 26)),
              isFalse,
              reason:
                  'the bar is raised by the bottom inset, over the last line',
            );
            expect(
              covers(tester, bar, box.bottomLeft + const Offset(1, -1)),
              isTrue,
            );
            expect(
              covers(tester, bar, box.bottomRight - const Offset(1, 1)),
              isTrue,
            );
          },
        );
      }

      testWidgets('the vertical bar is at the widget\'s right edge, top to '
          'bottom', (tester) async {
        // On android the vertical bar shows only while scrolling and
        // `interactive` is off too, so as is the track takes no hits. Both are
        // turned on through the app theme to measure it.
        await pumpInset(
          tester,
          SyntaxText(long),
          bars: const ScrollbarThemeData(
            thumbVisibility: WidgetStatePropertyAll(true),
            interactive: true,
          ),
        );
        final box = tester.getRect(find.byType(SyntaxText));
        final bar = scrollOf(tester, Axis.vertical);
        expect(covers(tester, bar, box.topRight + const Offset(-1, 1)), isTrue);
        expect(
          covers(tester, bar, box.bottomRight - const Offset(1, 1)),
          isTrue,
        );
        expect(
          covers(tester, bar, box.centerRight - const Offset(26, 0)),
          isFalse,
          reason: 'the bar is pushed in by the right inset',
        );
      });

      testWidgets('the code inside still sees the screen inset', (
        tester,
      ) async {
        // The selection toolbar and handles read this value to stay on screen.
        // What was removed must be the bars' share only.
        await pumpInset(tester, SyntaxText(long));
        expect(
          MediaQuery.paddingOf(tester.element(find.byType(EditableText))),
          inset,
        );
      });

      testWidgets('the code is not rebuilt as the keyboard rises and falls', (
        tester,
      ) async {
        // If the place that reads `MediaQuery` to remove the inset moves up
        // into this widget's build, every span is remade on every frame of the
        // keyboard animation. If it was rebuilt, `SelectableText` is a new
        // instance. The widget passed is the same instance both times —
        // making a new one would rebuild by that alone.
        final code = SyntaxText(long);
        Widget app(double keyboard) => MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(viewInsets: EdgeInsets.only(bottom: keyboard)),
              child: Scaffold(
                resizeToAvoidBottomInset: false,
                body: SizedBox(width: 400, height: 300, child: code),
              ),
            ),
          ),
        );
        await tester.pumpWidget(app(0));
        final before = tester.widget(find.byType(SelectableText));
        await tester.pumpWidget(app(100));
        expect(
          identical(tester.widget(find.byType(SelectableText)), before),
          isTrue,
        );
      });
    });

    group('on desktop there is one vertical bar', () {
      // Material's `MaterialScrollBehavior.buildScrollbar` attaches one more
      // bar to every vertical `Scrollable` on desktop. It drew the same
      // controller as the bar this widget already has, so the thumb was
      // painted twice (#32).

      testWidgets('only this widget\'s bar is attached to the vertical view', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        try {
          await pump(tester, SyntaxText(long));
          expect(barOf(scrollOf(tester, Axis.vertical)), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('the automatic bar inside EditableText is left alone', (
        tester,
      ) async {
        // Put `scrollable: false` in a place with a fixed height and
        // `EditableText` scrolls vertically inside itself. Then the only
        // vertical bar visible on desktop is this automatic one, so it is not
        // removed (decided by the maintainer in #32).
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        try {
          await pump(tester, SyntaxText(long, scrollable: false));
          final inner = tester
              .state<ScrollableState>(
                find.descendant(
                  of: find.byType(EditableText),
                  matching: find.byType(Scrollable),
                ),
              )
              .position;
          expect(inner.maxScrollExtent, greaterThan(0));
          expect(
            find.byWidgetPredicate(
              (w) =>
                  w is Scrollbar &&
                  (w.controller?.positions.contains(inner) ?? false),
            ),
            findsOneWidget,
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('the app\'s ScrollBehavior still applies to the vertical '
          'view', (tester) async {
        // Only the bar is turned off; the rest is inherited from the app.
        // Slotting in a new `ScrollBehavior` would lose the app's
        // `dragDevices`, and touch would scroll again.
        await tester.pumpWidget(
          MaterialApp(
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {PointerDeviceKind.mouse},
            ),
            home: Scaffold(
              body: SizedBox(width: 400, height: 300, child: SyntaxText(long)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final vertical = scrollOf(tester, Axis.vertical);
        expect(vertical.position.maxScrollExtent, greaterThan(0));

        await tester.dragFrom(
          tester.getCenter(find.byType(SyntaxText)),
          const Offset(0, -120),
        );
        await tester.pumpAndSettle();
        expect(vertical.position.pixels, 0);
      });
    });

    group('the mouse wheel glides', () {
      const frame = Duration(milliseconds: 16);

      ScrollPosition along(WidgetTester tester, Axis axis) => tester
          .widget<SingleChildScrollView>(
            find.byWidgetPredicate(
              (w) => w is SingleChildScrollView && w.scrollDirection == axis,
            ),
          )
          .controller!
          .position;

      /// Sends one mouse-wheel notch at [at]. Does not pump.
      Future<void> wheel(WidgetTester tester, Offset at, double dy) async {
        final pointer = TestPointer(1, PointerDeviceKind.mouse);
        await tester.sendEventToBinding(pointer.hover(at));
        await tester.sendEventToBinding(pointer.scroll(Offset(0, dy)));
      }

      testWidgets('one notch travels to the target without teleporting', (
        tester,
      ) async {
        await pump(tester, SyntaxText(long));
        await wheel(tester, tester.getCenter(find.byType(SyntaxText)), 120);
        await tester.pump();
        await tester.pump(frame);
        final mid = along(tester, Axis.vertical).pixels;
        expect(mid, greaterThan(0));
        expect(mid, lessThan(120));

        await tester.pumpAndSettle();
        expect(along(tester, Axis.vertical).pixels, 120);
      });

      testWidgets('a notch near the end stops exactly at the end', (
        tester,
      ) async {
        // macOS uses `BouncingScrollPhysics`, which allows positions past the
        // end. The only thing that stops it there is the wheel motion's own
        // clamp.
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          await pump(tester, SyntaxText(long));
          final position = along(tester, Axis.vertical);
          final max = position.maxScrollExtent;
          position.jumpTo(max - 30);
          await tester.pump();

          await wheel(tester, tester.getCenter(find.byType(SyntaxText)), 120);
          await tester.pump();
          await tester.pump(frame);
          expect(
            position.pixels,
            lessThan(max),
            reason: 'jumped without animating',
          );
          while (tester.binding.hasScheduledFrame) {
            await tester.pump(frame);
            expect(position.pixels, lessThanOrEqualTo(max));
          }
          expect(position.pixels, max);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('it glides when rolled over the scrollbar too', (
        tester,
      ) async {
        // Whoever registers first takes the wheel, and the view is inside the
        // scrollbar, so it registers first. The scrollbar gets the wheel only
        // when its painter intercepts the hit — when hovering over it on
        // desktop has revealed the track. So this runs as desktop and first
        // checks that the view has dropped out of the hit path. Otherwise this
        // check measures the one above again.
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        try {
          await pump(tester, SyntaxText(long));
          final box = tester.getRect(find.byType(SyntaxText));
          final bar = Offset(box.right - 3, box.center.dy);
          final view = tester.renderObject(
            find.byWidgetPredicate(
              (w) =>
                  w is SingleChildScrollView &&
                  w.scrollDirection == Axis.vertical,
            ),
          );
          final pointer = TestPointer(1, PointerDeviceKind.mouse);
          await tester.sendEventToBinding(pointer.hover(bar));
          await tester.pumpAndSettle();
          expect(
            tester
                .hitTestOnBinding(bar)
                .path
                .any((entry) => identical(entry.target, view)),
            isFalse,
            reason:
                'the view gets the wheel — the scrollbar path is not measured',
          );

          await wheel(tester, bar, 120);
          await tester.pump();
          await tester.pump(frame);
          final mid = along(tester, Axis.vertical).pixels;
          expect(mid, greaterThan(0));
          expect(mid, lessThan(120));

          await tester.pumpAndSettle();
          expect(along(tester, Axis.vertical).pixels, 120);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('Shift+wheel glides horizontally', (tester) async {
        await pump(tester, SyntaxText(long));
        final horizontal = along(tester, Axis.horizontal);
        final target = math.min(60.0, horizontal.maxScrollExtent);
        expect(target, greaterThan(16), reason: 'no room to move horizontally');

        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        try {
          await wheel(
            tester,
            tester.getCenter(find.byType(SyntaxText)),
            target,
          );
          await tester.pump();
          await tester.pump(frame);
          final mid = horizontal.pixels;
          expect(mid, greaterThan(0));
          expect(mid, lessThan(target));

          await tester.pumpAndSettle();
          expect(horizontal.pixels, target);
          expect(along(tester, Axis.vertical).pixels, 0);
        } finally {
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        }
      });

      group('wheelMotion', () {
        /// The argument omitted. Distinguished from passing `null`.
        const omitted = Object();

        Widget view(Object? motion) => identical(motion, omitted)
            ? SyntaxText(long)
            : SyntaxText(long, wheelMotion: motion as WheelMotion?);

        /// Sends one vertical notch on a fresh tree and returns the position
        /// after the first frame.
        Future<double> firstStep(WidgetTester tester, Object? motion) async {
          await pump(tester, const SizedBox());
          await pump(tester, view(motion));
          await wheel(tester, tester.getCenter(find.byType(SyntaxText)), 120);
          await tester.pump();
          await tester.pump(frame);
          return along(tester, Axis.vertical).pixels;
        }

        testWidgets('with null, both vertical and horizontal go instantly', (
          tester,
        ) async {
          await pump(tester, view(null));
          final center = tester.getCenter(find.byType(SyntaxText));
          await wheel(tester, center, 120);
          await tester.pump();
          expect(along(tester, Axis.vertical).pixels, 120);

          final horizontal = along(tester, Axis.horizontal);
          final target = math.min(60.0, horizontal.maxScrollExtent);
          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          try {
            await wheel(tester, center, target);
            await tester.pump();
            expect(horizontal.pixels, target);
          } finally {
            await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          }
        });

        for (final (name, motion) in [
          ('curve', const WheelMotion.curve(curve: Curves.easeOut)),
          ('lerp', const WheelMotion.lerp()),
        ]) {
          testWidgets('$name motion glides but travels differently from the '
              'default spring', (tester) async {
            final spring = await firstStep(tester, omitted);
            final step = await firstStep(tester, motion);
            expect(step, greaterThan(0));
            expect(step, lessThan(120));
            expect(step, isNot(moreOrLessEquals(spring)));

            await tester.pumpAndSettle();
            expect(along(tester, Axis.vertical).pixels, 120);
          });
        }

        testWidgets(
          'changing it keeps the position and applies from the next notch',
          (tester) async {
            await pump(tester, view(omitted));
            final center = tester.getCenter(find.byType(SyntaxText));
            await wheel(tester, center, 120);
            await tester.pumpAndSettle();
            expect(along(tester, Axis.vertical).pixels, 120);

            await pump(tester, view(null));
            expect(along(tester, Axis.vertical).pixels, 120);

            await wheel(tester, center, 120);
            await tester.pump();
            expect(along(tester, Axis.vertical).pixels, 240);
          },
        );
      });

      testWidgets('the outer view gets a vertical wheel over a scrollable: '
          'false block', (tester) async {
        // A code block embedded in prose. Rolling vertically over it must
        // scroll the prose — if the horizontal view the block owns takes the
        // vertical wheel, the page stops there.
        final outer = ScrollController();
        addTearDown(outer.dispose);
        await pump(
          tester,
          SingleChildScrollView(
            controller: outer,
            child: Column(
              children: [
                const SizedBox(height: 40),
                SyntaxText(long, scrollable: false),
                const SizedBox(height: 400),
              ],
            ),
          ),
        );
        await wheel(tester, const Offset(200, 150), 120);
        await tester.pumpAndSettle();
        expect(outer.position.pixels, 120);
      });
    });

    testWidgets('controllers are disposed with the tree', (tester) async {
      await pump(tester, SyntaxText(long));
      final controller = tester
          .widget<SingleChildScrollView>(
            find.byWidgetPredicate(
              (w) =>
                  w is SingleChildScrollView &&
                  w.scrollDirection == Axis.vertical,
            ),
          )
          .controller!;
      await pump(tester, const SizedBox());
      expect(() => controller.addListener(() {}), throwsFlutterError);
    });
  });

  group('copy control', () {
    testWidgets('sits at the top right', (tester) async {
      // On the left it would cover the first characters of the code.
      await pump(tester, const SyntaxText(everyKind));
      final widget = tester.getRect(find.byType(SyntaxText));
      final button = tester.getCenter(find.byType(IconButton));
      expect(button.dx, greaterThan(widget.center.dx));
      expect(button.dy, lessThan(widget.center.dy));
    });

    testWidgets('absent with copyable: false', (tester) async {
      await pump(tester, const SyntaxText(everyKind, copyable: false));
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('the confirmation mark is finite', (tester) async {
      // With an indeterminate indicator, `pumpAndSettle` never settles.
      await pump(tester, const SyntaxText(everyKind));
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(find.byIcon(Icons.check), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('the confirmation mark resets when source changes', (
      tester,
    ) async {
      // The confirmation mark belongs to the source it was shown for. Without
      // a reset, copying A and switching to B shortly after leaves a green
      // check next to something that was never copied.
      await pump(tester, const SyntaxText(everyKind));
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(find.byIcon(Icons.check), findsOneWidget);

      await pump(tester, const SyntaxText('var other = 1;'));
      expect(find.byIcon(Icons.check), findsNothing);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('no timer is left behind when the tree goes away', (
      tester,
    ) async {
      // A timer that outlives the tree fails the test that pumped it, and
      // since that is the right behaviour, it is not optional.
      await pump(tester, const SyntaxText(everyKind));
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      await pump(tester, const SizedBox());
      // If a timer is still alive here, this test fails.
    });
  });
}
