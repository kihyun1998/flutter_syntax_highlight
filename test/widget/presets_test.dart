import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_syntax_highlight/flutter_syntax_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

/// 이름 붙은 프리셋 전부.
///
/// **손으로 다시 적은 목록이고, 그것이 요점이다.** 패키지는 이름 룩업을 두지
/// 않기로 했으므로(레지스트리를 만들지 않는다는 결정) 여기서 돌 목록이 lib에
/// 없다. 프리셋을 추가하고 이 목록에 넣지 않으면 그 프리셋은 아래 검사들을
/// 하나도 통과하지 않은 채 배포된다 — 그 위험은 남아 있고, 숨기지 않는다.
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
  test('열 개다', () {
    expect(presets, hasLength(10));
  });

  group('모양', () {
    test('일곱 슬롯이 전부 색을 갖는다', () {
      // 조사가 슬롯 일곱을 채웠다. 빈 칸이 있으면 그 kind가 루트 색으로
      // 떨어지는데, 색이 있는 팔레트에서 그것은 사고지 결정이 아니다.
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
          expect(palette.styleFor(kind)?.color, isNotNull,
              reason: '$name의 $kind');
        }
      });
    });

    test('punctuation은 plain과 같다', () {
      // 조사한 테마 9종 중 punctuation에 고유한 색을 주는 것이 없었다.
      // 파생 기본값만 punctuation을 흐리게 하고, 그것은 색 없이 구분해야 하기
      // 때문이다 — 색이 있는 프리셋에는 그 필요가 없다.
      presets.forEach((name, palette) {
        expect(
          palette.styleFor(DartTokenKind.punctuation)?.color,
          palette.styleFor(DartTokenKind.plain)?.color,
          reason: name,
        );
      });
    });

    test('어떤 프리셋도 fontFamily를 지목하지 않는다', () {
      // 하드 룰이다. family를 지목하는 잎은 비례 글꼴로 그려지면서, 겉포장을
      // 읽는 가드는 초록으로 남는다.
      presets.forEach((name, palette) {
        for (final kind in DartTokenKind.values) {
          final style = palette.styleFor(kind);
          expect(style?.fontFamily, isNull, reason: '$name의 $kind');
          expect(style?.fontFamilyFallback, isNull, reason: '$name의 $kind');
        }
      });
    });

    test('서로 다르다', () {
      // 복사해 붙이다 값을 안 바꾼 프리셋을 잡는다.
      final seen = <SyntaxPalette, String>{};
      presets.forEach((name, palette) {
        expect(seen, isNot(contains(palette)),
            reason: '$name이 ${seen[palette]}와 똑같다');
        seen[palette] = name;
      });
    });
  });

  group('배경', () {
    test('열 개가 전부 자기 배경을 든다', () {
      for (final e in presets.entries) {
        expect(
          e.value.background,
          isNotNull,
          reason: '${e.key}에 배경이 없다 — 색들은 특정 배경 위에서 고른 것이라, '
              '배경 없이 실으면 원본이 정한 대비가 사라진다',
        );
      }
    });

    test('파생 기본값은 배경을 주지 않는다', () {
      // 앱이 이미 칠해 둔 surface가 이 팔레트에게 올바른 배경이다. 여기서
      // 무엇이든 칠하면 코드 블록만 앱에서 떨어져 나온다.
      final derived = SyntaxPalette.fromColorScheme(
        ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
      );
      expect(derived.background, isNull);
    });

    test('본문이 자기 배경 위에서 4.1:1 이상이다', () {
      // **이 검사가 문서의 주장을 대체한다.** 앞선 판본은 프리셋이 "반대
      // 밝기에서 보이지 않는다"고 적으면서 `cobalt2`의 명도비를 1.00이라고
      // 했는데, 그것은 흰 본문을 *앱의* surface에 대고 잰 값이었다 — 팔레트가
      // 배경을 들고 있지 않아 그것 말고는 잴 것이 없었기 때문이다.
      //
      // 바닥을 4.1로 둔 것은 WCAG AA(4.5)가 아니라 **실측된 최솟값 바로
      // 아래**다: solarizedLight가 4.13이고, 그 값은 상류가 정한 것이라 우리가
      // 올릴 수 없다. AA를 요구하면 통과시킬 수 없는 것을 요구하게 되고, 더
      // 낮추면 상류가 값을 바꿔도 조용해진다.
      for (final e in presets.entries) {
        final ratio = _contrast(e.value.background!, e.value.plain!.color!);
        expect(
          ratio,
          greaterThan(4.1),
          reason: '${e.key}: 본문이 자기 배경 위에서 '
              '${ratio.toStringAsFixed(2)}:1이다',
        );
      }
    });

    test('cobalt2는 앱 surface가 아니라 자기 배경 위에서 읽힌다', () {
      // 위 검사가 열 개를 한꺼번에 도는 동안, 이 하나는 **바뀐 것이 무엇인지**를
      // 이름 대고 남긴다. 같은 흰 본문, 두 개의 배경.
      const white = Color(0xFFFFFFFF);
      expect(SyntaxPalette.cobalt2.plain!.color, white);
      expect(_contrast(const Color(0xFFFDF7FF), white), lessThan(1.1));
      expect(_contrast(SyntaxPalette.cobalt2.background!, white),
          greaterThan(12.0));
    });
  });

  group('조사가 기록한 값과 어긋나지 않는다', () {
    test('escape가 number와 같은 것은 정확히 넷이다', () {
      // 조사(#9)가 센 것: `constant.character.escape`에 전용 규칙이 있는 테마는
      // one 계열과 tokyoNight 계열뿐이고, 나머지 넷은 상위 `constant` 규칙에
      // 흡수된다. **원본이 실제로 그렇다** — 우리가 잘못 뽑은 것이 아니다.
      //
      // 이 검사가 값을 옮겨 적다 생긴 오차를 잡는다.
      final same = presets.entries
          .where((e) =>
              e.value.styleFor(DartTokenKind.escape)?.color ==
              e.value.styleFor(DartTokenKind.number)?.color)
          .map((e) => e.key)
          .toSet();
      expect(same, {'monokai', 'gruvboxDark', 'gruvboxLight', 'cobalt2'});
    });

    test('주석이 기울지 않는 것은 monokai뿐이다', () {
      final upright = presets.entries
          .where((e) =>
              e.value.styleFor(DartTokenKind.comment)?.fontStyle !=
              FontStyle.italic)
          .map((e) => e.key)
          .toSet();
      expect(upright, {'monokai'});
    });

    test('밝기 짝이 넷이고 각각 다르다', () {
      // 실명 프리셋은 하드코딩된 팔레트라 반대 밝기에서 깨진다. 원본에 짝이
      // 있으면 짝으로 싣기로 한 이유가 그것이다 — 밝기를 바꿀 때 고를 것이 있어야
      // 한다.
      const pairs = {
        'solarizedDark': 'solarizedLight',
        'oneDark': 'oneLight',
        'gruvboxDark': 'gruvboxLight',
        'tokyoNight': 'tokyoNightLight',
      };
      pairs.forEach((dark, light) {
        expect(presets[dark]!.styleFor(DartTokenKind.plain)?.color,
            isNot(presets[light]!.styleFor(DartTokenKind.plain)?.color),
            reason: '$dark와 $light의 본문 색이 같다');
      });
    });
  });

  group('NOTICES', () {
    late final String notices;
    setUpAll(() => notices = File('NOTICES').readAsStringSync());

    test('파일이 있고 비어 있지 않다', () {
      expect(notices.trim(), isNotEmpty);
    });

    test('모든 상류의 저작권 줄이 들어 있다', () {
      // MIT 일곱이 공통으로 요구하는 것은 **고지 유지 하나뿐**이다. 이 파일이
      // 그것을 하고, 그래서 "hex 값에 저작권이 있는가" 논쟁이 무의미해진다.
      for (final holder in [
        'Ethan Schoonover',
        'Microsoft Corporation',
        'GitHub Inc.',
        'Colorsublime.com',
        'Enkia',
        'Wes Bos',
        'JD', // gruvbox 이식본의 저작권자
      ]) {
        expect(notices, contains(holder), reason: holder);
      }
      // gruvbox 정본은 저작권 줄이 존재하지 않아 옮겨 적을 것이 없다. 원저자는
      // 저작권 표기가 아니라 **출처 표기**로 들어간다.
      expect(notices, contains('Pavel Pertsev'));
    });

    test('값을 뜬 파일을 커밋까지 지목한다', () {
      // 같은 테마도 판본마다 라이선스가 다르다. 어느 파일에서 떴는지가 없으면
      // 나중에 그 판정을 다시 할 수 없다.
      // 정확한 수를 못 박는다. `>= 5`로 두면 둘이 사라져도 초록이다.
      expect(RegExp(r'[0-9a-f]{40}').allMatches(notices).length, 7,
          reason: '커밋으로 고정된 출처가 줄었다');
    });

    test('배경값도 출처와 함께 적혀 있다', () {
      // 배경은 나중에 붙었고, 그래서 고지에서 빠지기 가장 쉬운 값이다.
      for (final e in presets.entries) {
        final hex =
            e.value.background!.toARGB32().toRadixString(16).substring(2);
        expect(
          notices.toUpperCase(),
          contains('#${hex.toUpperCase()}'),
          reason: '${e.key}의 배경 #$hex가 NOTICES에 없다',
        );
      }
    });

    test('배포물에 실린다', () {
      // `.pubignore`가 `.gitignore`를 대체하므로, 여기 적히지 않은 것은 빠지는
      // 것이 아니라 **들어간다**. 반대로 실수로 뺄 수도 있다.
      final ignore = File('.pubignore').readAsStringSync();
      expect(ignore, isNot(contains('NOTICES')));
    });
  });
}

/// WCAG 상대 명도 대비.
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
