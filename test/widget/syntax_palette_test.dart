import 'package:flutter/material.dart';
import 'package:flutter_syntax_highlight/flutter_syntax_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

/// 색이 있는 스킴과 없는 스킴 둘 다로 판다. 파생 기본값의 주장이 "무채색"이
/// 아니라 "**소비자의 스킴에 색상을 더하지 않는다**"이므로, 색이 있는 쪽에서
/// 확인해야 그 주장이 시험된다.
final colourful = ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4));
final monochrome = ColorScheme.fromSeed(
  seedColor: const Color(0xFF000000),
  dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
);

void main() {
  group('fromColorScheme — 설정 없이 라이트와 다크 양쪽에서 맞는 기본값', () {
    test('여덟 kind 전부를 다루고, 둘만 루트를 물려받는다', () {
      final palette = SyntaxPalette.fromColorScheme(colourful);
      final inherits = {DartTokenKind.plain, DartTokenKind.function};
      for (final kind in DartTokenKind.values) {
        expect(
          palette.styleFor(kind),
          inherits.contains(kind) ? isNull : isNotNull,
          reason: '$kind',
        );
      }
    });

    test('스타일을 주는 kind는 전부 plain과 구별된다', () {
      // 색상 없이 구분하는 팔레트가 빠지기 쉬운 함정: 루트가 이미 `onSurface`
      // 이므로 `onSurface`를 주는 것은 아무것도 하지 않는다. 실제로 한 번
      // 그렇게 썼다가 이 검사로 잡았다.
      final palette = SyntaxPalette.fromColorScheme(colourful);
      for (final kind in DartTokenKind.values) {
        final style = palette.styleFor(kind);
        if (style == null) continue;
        expect(
          style.color != colourful.onSurface ||
              style.fontWeight != null ||
              style.fontStyle != null,
          isTrue,
          reason: '$kind에 스타일을 줬지만 루트와 똑같이 그려진다',
        );
      }
    });

    test('스킴에 없는 색상을 만들어 내지 않는다', () {
      // 이것이 파생 기본값의 주장 전체다. 참조 구현은 "무채색"이라고 적었지만
      // 그 근거는 host 앱의 스킴이 애초에 monochrome이라 **가져올 색상이
      // 없었다**는 것이었다. 소비자의 스킴은 색이 있을 수 있으므로 그 문장은
      // 그대로 옮기면 거짓이 된다.
      //
      // 다시 쓴 주장은 더 보편적이다: 이 팔레트는 스킴의 세 역할만 읽고 자기
      // 색상을 도입하지 않는다. 앱이 무채색이면 무채색이 되고, 색이 있으면
      // 그 색에 섞인다.
      for (final scheme in [colourful, monochrome]) {
        final palette = SyntaxPalette.fromColorScheme(scheme);
        final allowed = {
          scheme.onSurface,
          scheme.onSurfaceVariant,
          scheme.outline,
        };
        for (final kind in DartTokenKind.values) {
          final colour = palette.styleFor(kind)?.color;
          if (colour == null) continue;
          expect(
            allowed,
            contains(colour),
            reason: '$kind가 스킴에 없는 색을 들여왔다',
          );
        }
      }
    });

    test('주석만 흐려지지 않는다', () {
      // 통념을 뒤집는다. 보통의 하이라이터는 주석을 흐리고 키워드를 밝히는데,
      // 그것은 **이미 아는 코드를 훑는** 상황을 가정한다. 이 패키지가 그리는
      // 코드는 대개 읽히려고 놓인 것이고, 거기서 주석은 곁다리가 아니다.
      //
      // 더 단단한 근거: 키워드와 구두점은 Dart를 아는 사람이라면 코드에서 다시
      // 읽어낼 수 있지만, **주석은 코드에서 복원되지 않는 유일한 부분**이다.
      // 복원되지 않는 것만 골라 흐리는 것은 거꾸로다.
      final palette = SyntaxPalette.fromColorScheme(colourful);
      final comment = palette.styleFor(DartTokenKind.comment)!;

      expect(comment.fontStyle, FontStyle.italic, reason: '기울임이 분리한다');
      expect(
        comment.color,
        anyOf(isNull, equals(colourful.onSurface)),
        reason: '주석이 흐려졌다 — 대비를 그대로 두는 것이 이 팔레트의 결정이다',
      );
    });

    test('물러나는 것은 punctuation이다', () {
      final palette = SyntaxPalette.fromColorScheme(colourful);
      expect(palette.styleFor(DartTokenKind.punctuation)!.color,
          colourful.outline);
      expect(
        palette.styleFor(DartTokenKind.string)!.color,
        colourful.onSurfaceVariant,
        reason: 'punctuation은 문자열보다 한 단계 더 흐려야 한다',
      );
    });

    test('키워드는 색이 아니라 굵기로 구분된다', () {
      // 색상을 쓰지 않고 구분하려면 색 말고 다른 축이 필요하다.
      final palette = SyntaxPalette.fromColorScheme(colourful);
      final keyword = palette.styleFor(DartTokenKind.keyword)!;
      expect(keyword.fontWeight, isNotNull);
      expect(keyword.color, isNull);
    });

    test('라이트와 다크가 다른 값을 낸다', () {
      // 하드코딩된 팔레트가 반대 밝기에서 조용히 깨지는 것을 파생이 막는다.
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

  group('직접 만들기', () {
    test('몇 줄이면 자기 팔레트가 된다', () {
      const mine = SyntaxPalette(
        comment: TextStyle(color: Color(0xFF888888)),
        keyword: TextStyle(color: Color(0xFF0000FF)),
      );
      expect(
          mine.styleFor(DartTokenKind.comment)!.color, const Color(0xFF888888));
      // 주지 않은 kind는 null이다 — 루트 스타일을 물려받는다.
      expect(mine.styleFor(DartTokenKind.string), isNull);
    });

    test('const로 만들 수 있다', () {
      // 소비자가 위젯 트리에 상수로 박을 수 있어야 리빌드마다 새 객체가
      // 생기지 않는다.
      const a = SyntaxPalette(comment: TextStyle(fontStyle: FontStyle.italic));
      const b = SyntaxPalette(comment: TextStyle(fontStyle: FontStyle.italic));
      expect(identical(a, b), isTrue);
    });
  });

  group('어떤 스타일도 fontFamily를 지정하지 않는다', () {
    // 하드 룰이다. family를 지목하는 잎은 비례 글꼴로 그려지면서, 겉포장인
    // `EditableText.style`을 읽는 가드는 초록으로 남는다. 이 저장소가 한 번
    // 지불한 버그이고, 팔레트가 그것을 다시 들여올 수 있는 자리다.
    test('파생 기본값도', () {
      final palette = SyntaxPalette.fromColorScheme(colourful);
      for (final kind in DartTokenKind.values) {
        final style = palette.styleFor(kind);
        expect(style?.fontFamily, isNull, reason: '$kind');
        expect(style?.fontFamilyFallback, isNull, reason: '$kind');
      }
    });
  });
}
