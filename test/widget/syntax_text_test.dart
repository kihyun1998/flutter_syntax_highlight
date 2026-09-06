import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_syntax_highlight/flutter_syntax_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

/// 여덟 kind가 전부 나오는 조각. 가드가 닿지 않는 분기는 지키지 못하므로,
/// 아래 검사들이 `_styleFor`의 모든 갈래를 지나가게 한다.
const everyKind = "// a comment\n"
    "class Sentinel {\n"
    "  final s = 'a\\nb';\n"
    "  var n = f(1);\n"
    "}\n";

/// 비례 글꼴을 테마에 심는다. 고정폭 검사가 잡아야 하는 것이 정확히 이것이다.
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

/// 잎 스팬들. `EditableText.style`이 아니라 **여기**를 읽는 것이 요점이다.
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
  testWidgets('픽스처가 여덟 kind를 전부 낸다', (tester) async {
    // 부수 조건. 이 조각이 어떤 kind를 놓치면 아래 검사들이 그 갈래를 지나지
    // 않으면서 초록으로 남는다.
    expect(tokenizeDart(everyKind).map((t) => t.kind).toSet(),
        DartTokenKind.values.toSet());
  });

  group('하이라이터는 붙여넣을 것을 바꾸지 못한다', () {
    const tricky = "// somebody's file\r\n"
        "class Sentinel {\r\n"
        "  final s = '\${a ?? ''}';\r\n"
        "}\r\n";

    testWidgets('렌더된 트리를 평탄화하면 정확히 그 바이트다', (tester) async {
      await pump(tester, const SyntaxText(tricky));
      final selectable =
          tester.widget<SelectableText>(find.byType(SelectableText));
      // `includeSemanticsLabels: false`는 취향이 아니다 — 클립보드가 읽는
      // 문자열을 만들 때 컨트롤러가 하는 바로 그 호출이다.
      expect(
        selectable.textSpan!.toPlainText(includeSemanticsLabels: false),
        tricky,
      );
    });

    testWidgets('그리고 복사 컨트롤이 같은 것을 클립보드에 올린다', (tester) async {
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
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await pump(tester, const SyntaxText(tricky));
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(copied, tricky);
    });
  });

  group('고정폭', () {
    testWidgets('겉포장이 고정폭을 지목한다', (tester) async {
      await pump(tester, const SyntaxText(everyKind));
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.style.fontFamily, isNotNull);
      expect(editable.style.fontFamily, isNot(chromeFont));
    });

    testWidgets('fontFamily를 주지 않아도 non-null family가 지목된다', (tester) async {
      // nullable로 연 것이 옛 버그를 되살릴 새 경로다. null이 "설정하지 않음"으로
      // 해석되면 `inherit: true`가 앰비언트 스타일을 머지해 비례 글꼴로 그려진다.
      await pump(tester, const SyntaxText(everyKind));
      final style =
          tester.widget<EditableText>(find.byType(EditableText)).style;

      expect(style.fontFamily, isNotNull);
      expect(style.fontFamilyFallback, isNotNull);

      // family가 fallback에도 있으면 `fallback.first`가 family처럼 보여서,
      // family가 아예 설정되지 않았다는 사실을 가린다. 그 모양이 버그를 숨겼다.
      expect(style.fontFamilyFallback, isNot(contains(style.fontFamily)));

      // 그리고 해석은 반드시 제네릭에서 끝난다 — family 자체가 제네릭이거나
      // (Android가 그렇다), 아니면 fallback의 마지막이 제네릭이거나.
      expect(
        style.fontFamily == 'monospace' ||
            style.fontFamilyFallback!.last == 'monospace',
        isTrue,
        reason: '고정폭 해석이 제네릭으로 끝나지 않는다 — 목록의 어느 글꼴도 '
            '없는 기기에서 비례 글꼴로 떨어진다',
      );
    });

    test('플랫폼마다 고정폭을 지목하고, 그것을 fallback에서 뺀다', () {
      // 위젯 테스트는 Android로 돌므로 한 갈래만 지나간다. 나머지 갈래도 같은
      // 불변식을 지키는지는 여기서 본다.
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
          reason: '$platform에서 해석이 제네릭으로 끝나지 않는다',
        );
      }
    });

    testWidgets('그리고 어떤 잎도 자기 family를 들이지 않는다', (tester) async {
      // 위 검사는 **겉포장**을 읽는다. `SelectableText`는 받은 스팬 트리를
      // `TextSpan(style: ..., children: [주어진 것])`으로 감싸므로, 잎이 비례
      // 글꼴을 지목해도 위 검사는 초록으로 남는다. 그것이 이 저장소가 한 번
      // 지불한 버그이고, 이 검사는 대체가 아니라 추가다.
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
      // `TextSpan`이 아닌 자식은 복사되는 텍스트에 `\u{FFFC}`를 써 넣는다.
      expect(foreign, isEmpty);
    });
  });

  group('팔레트가 실제로 그려진다 — 객체가 아니라 잎에서 읽는다', () {
    testWidgets('넘긴 팔레트의 색이 잎에 나타난다', (tester) async {
      const marker = Color(0xFF123456);
      await pump(
        tester,
        const SyntaxText(
          everyKind,
          palette: SyntaxPalette(comment: TextStyle(color: marker)),
        ),
      );
      final commentLeaves =
          leavesOf(tester).where((s) => s.text!.contains('a comment')).toList();
      expect(commentLeaves, isNotEmpty);
      expect(commentLeaves.single.style?.color, marker);
    });

    testWidgets('주지 않으면 ColorScheme에서 파생된 것이 쓰인다', (tester) async {
      await pump(tester, const SyntaxText(everyKind));
      final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4));
      final expected = SyntaxPalette.fromColorScheme(scheme);
      final stringLeaf =
          leavesOf(tester).firstWhere((s) => s.text!.startsWith("'a"));
      expect(
        stringLeaf.style?.color,
        expected.styleFor(DartTokenKind.string)!.color,
      );
    });

    testWidgets('밝기를 바꾸면 그려진 색이 따라 바뀐다', (tester) async {
      await pump(tester, const SyntaxText(everyKind));
      final light = leavesOf(tester)
          .firstWhere((s) => s.text!.startsWith("'a"))
          .style
          ?.color;

      await pump(tester, const SyntaxText(everyKind), b: Brightness.dark);
      final dark = leavesOf(tester)
          .firstWhere((s) => s.text!.startsWith("'a"))
          .style
          ?.color;

      expect(light, isNotNull);
      expect(dark, isNot(light),
          reason: '파생 기본값의 존재 이유가 이것이다 — 설정 없이 양쪽에서 맞는다');
    });
  });

  group('스크롤', () {
    testWidgets('가로는 항상 위젯이 소유한다', (tester) async {
      await pump(tester, const SyntaxText(everyKind, scrollable: false));
      final views = tester.widgetList<SingleChildScrollView>(
          find.byType(SingleChildScrollView));
      expect(views.map((v) => v.scrollDirection), contains(Axis.horizontal));
    });

    testWidgets('scrollable: false면 세로 스크롤이 없다', (tester) async {
      await pump(tester, const SyntaxText(everyKind, scrollable: false));
      final views = tester.widgetList<SingleChildScrollView>(
          find.byType(SingleChildScrollView));
      expect(
          views.map((v) => v.scrollDirection), isNot(contains(Axis.vertical)));
    });

    testWidgets('scrollable: true면 자기 영역 안에서 세로로 스크롤한다', (tester) async {
      final long = List.generate(200, (i) => 'final x$i = $i;').join('\n');
      await pump(tester, SyntaxText(long));
      final views = tester.widgetList<SingleChildScrollView>(
          find.byType(SingleChildScrollView));
      expect(views.map((v) => v.scrollDirection), contains(Axis.vertical));

      final vertical = tester.widget<SingleChildScrollView>(
        find.byWidgetPredicate((w) =>
            w is SingleChildScrollView && w.scrollDirection == Axis.vertical),
      );
      // 컨트롤러를 패키지가 이름 붙여 소유한다. `primary`가 켜지면 두 스크롤
      // 뷰가 같은 `PrimaryScrollController`를 주장해 framework가 assert한다.
      expect(vertical.controller, isNotNull);
      expect(vertical.primary, isNot(true));
    });
  });

  group('복사 컨트롤', () {
    testWidgets('copyable: false면 없다', (tester) async {
      await pump(tester, const SyntaxText(everyKind, copyable: false));
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('확인 표시는 유한하다', (tester) async {
      // 불확정 인디케이터에서는 `pumpAndSettle`이 영원히 정착하지 않는다.
      await pump(tester, const SyntaxText(everyKind));
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(find.byIcon(Icons.check), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('source가 바뀌면 확인 표시가 리셋된다', (tester) async {
      // 확인 표시는 그것이 보여진 소스의 것이다. 리셋하지 않으면 A를 복사하고
      // 잠깐 뒤 B로 바꿨을 때 복사된 적 없는 것 옆에 초록 체크가 남는다.
      await pump(tester, const SyntaxText(everyKind));
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(find.byIcon(Icons.check), findsOneWidget);

      await pump(tester, const SyntaxText('var other = 1;'));
      expect(find.byIcon(Icons.check), findsNothing);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('트리가 사라져도 타이머가 남지 않는다', (tester) async {
      // 트리보다 오래 사는 타이머는 그것을 pump한 테스트를 실패시키며, 그것이
      // 옳은 동작이라 선택 사항이 아니다.
      await pump(tester, const SyntaxText(everyKind));
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      await pump(tester, const SizedBox());
      // 여기서 타이머가 살아 있으면 이 테스트가 실패한다.
    });
  });
}
