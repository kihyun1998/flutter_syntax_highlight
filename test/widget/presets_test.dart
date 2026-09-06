import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_syntax_highlight/flutter_syntax_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

/// 이름 붙은 프리셋 전부. 새로 추가하면 여기 넣어야 아래 검사들이 그것도 본다.
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
    expect(SyntaxPalette.presets.keys, presets.keys);
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
        'Pavel Pertsev',
        'Enkia',
        'Wes Bos',
      ]) {
        expect(notices, contains(holder), reason: holder);
      }
    });

    test('값을 뜬 파일을 커밋까지 지목한다', () {
      // 같은 테마도 판본마다 라이선스가 다르다. 어느 파일에서 떴는지가 없으면
      // 나중에 그 판정을 다시 할 수 없다.
      expect(RegExp(r'[0-9a-f]{40}').allMatches(notices).length,
          greaterThanOrEqualTo(5),
          reason: '커밋으로 고정된 출처가 모자란다');
    });

    test('배포물에 실린다', () {
      // `.pubignore`가 `.gitignore`를 대체하므로, 여기 적히지 않은 것은 빠지는
      // 것이 아니라 **들어간다**. 반대로 실수로 뺄 수도 있다.
      final ignore = File('.pubignore').readAsStringSync();
      expect(ignore, isNot(contains('NOTICES')));
    });
  });
}
