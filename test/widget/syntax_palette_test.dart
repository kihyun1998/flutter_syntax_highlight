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

    test('키워드는 색이 아니라 굵기로, 그리고 더 굵게 구분된다', () {
      // 색상을 쓰지 않고 구분하려면 색 말고 다른 축이 필요하다. 그런데 축을
      // 쓰는 것만으로는 부족하다 — 굵기를 **낮추면** 키워드가 평범한 코드보다
      // 흐려진다. 방향까지 못 박지 않으면 그 변형이 통과한다.
      final palette = SyntaxPalette.fromColorScheme(colourful);
      final keyword = palette.styleFor(DartTokenKind.keyword)!;
      expect(keyword.color, isNull);
      expect(
        keyword.fontWeight!.value,
        greaterThan(FontWeight.normal.value),
        reason: '키워드가 평범한 코드보다 흐리게 그려진다',
      );
    });

    test('리터럴의 내용물 셋은 같은 자리에서 흐려진다', () {
      // `string` / `number` / `escape`는 같은 역할을 읽는다. 셋 다 리터럴의
      // 내용물이고, 색상 없이 셋을 더 가를 축이 남아 있지 않다.
      //
      // 값을 못 박지 않으면 셋 중 하나만 `outline`으로 옮기는 변형이 통과한다 —
      // 그러면 문자열 안의 escape가 구두점과 같은 밝기가 되어, 리터럴이 중간에서
      // 꺼진 것처럼 보인다.
      final palette = SyntaxPalette.fromColorScheme(colourful);
      for (final kind in [
        DartTokenKind.string,
        DartTokenKind.number,
        DartTokenKind.escape,
      ]) {
        expect(
          palette.styleFor(kind)!.color,
          colourful.onSurfaceVariant,
          reason: '$kind',
        );
      }
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

  group('styleFor의 배선', () {
    // **kind마다 다른 표식을 꽂아 배선 자체를 검사한다.** 이것이 없으면
    // `escape => number`처럼 두 칸을 맞바꾼 switch가 전부 통과한다 — 파생
    // 기본값에서 그 둘이 같은 스타일이기 때문이다. 실제로 그 변형 넷이
    // 살아남았다.
    //
    // `fontSize`를 표식으로 쓰는 이유는 팔레트가 그것을 절대 쓰지 않기
    // 때문이다. 색이나 굵기를 쓰면 표식과 진짜 값이 섞인다.
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

    test('여덟 kind가 각자 자기 칸으로 간다', () {
      // 표식이 kind 수만큼 있어야 한다 — 하나라도 빠지면 그 배선은 검사되지 않는다.
      expect(expected.keys.toSet(), DartTokenKind.values.toSet());
      for (final entry in expected.entries) {
        expect(
          wired.styleFor(entry.key)?.fontSize,
          entry.value,
          reason: '${entry.key}의 배선이 어긋났다',
        );
      }
    });
  });

  group('값 동등성', () {
    // `SyntaxText`가 팔레트를 파라미터로 받으면 `didUpdateWidget`이 이것으로
    // 재계산 여부를 정한다. 없으면 같은 스킴에서 파생한 두 팔레트가 서로 다르게
    // 보여 리빌드마다 토큰을 다시 칠하게 된다.
    test('같은 값이면 같다', () {
      final a = SyntaxPalette.fromColorScheme(colourful);
      final b = SyntaxPalette.fromColorScheme(colourful);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('한 칸만 달라도 다르다', () {
      const a = SyntaxPalette(comment: TextStyle(fontSize: 1));
      const b = SyntaxPalette(comment: TextStyle(fontSize: 2));
      expect(a, isNot(b));
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
