import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_syntax_highlight/flutter_syntax_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

/// 파생 기본값을 **하나의 스킴이 아니라 색상환 전체**에 대고 잰다.
///
/// 프리셋은 값이 고정이라 열 개를 재면 끝이지만, 파생은 소비자의 스킴이
/// 무한하다. 자기 시드에서 눈으로 고른 계수는 그 시드에서만 맞는다.
///
/// 눈금 둘은 이 팔레트 자신이 이미 들고 있다: `onSurfaceVariant`와 `onSurface`의
/// 차이가 ΔE 9.9이고 **그것은 스크린샷에서 거의 보이지 않았다**. `outline`과
/// `onSurface`는 29.9이고 그것은 확실히 보인다. 새 구분들은 그 사이에 있어야
/// 하고, 아래 바닥은 전부 아래쪽 눈금보다 위다.
const _hueStep = 30;
const _tooSubtle = 9.9; // onSurfaceVariant vs onSurface, 같은 스윕에서 잰 값

double _lin(double v) =>
    v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b);

double _contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

/// CIE Lab (D65). 명도비는 **휘도만** 보므로 색상 차이를 재지 못한다 — 빨강과
/// 초록이 같은 명도비를 가질 수 있다. 이 팔레트가 더하는 것이 색상이므로 여기서
/// 필요한 자는 이쪽이다.
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
  return sqrt(
    pow(p[0] - q[0], 2) + pow(p[1] - q[1], 2) + pow(p[2] - q[2], 2),
  );
}

/// 색상환 × 밝기 전체. 각 스킴마다 [probe]를 부른다.
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
  group('파생 기본값 — 색상환 전체에서', () {
    test('새로 생긴 구분 넷이 전부 "거의 안 보이던" 눈금 위에 있다', () {
      // 이 넷이 이 팔레트가 앱의 accent를 빌려서 사는 것 전부다. 하나라도
      // 눈금 아래로 내려가면 그 kind는 있으나 마나다.
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
          reason: '${e.key}이 ΔE ${e.value.toStringAsFixed(1)}로 '
              '"거의 안 보이던" 눈금($_tooSubtle) 아래다',
        );
      }
    });

    test('당긴 색들이 surface 위에서 이 팔레트의 기존 바닥보다 안전하다', () {
      // 바닥을 새로 정하지 않는다. **이미 싣고 있는 것**을 바닥으로 쓴다 —
      // `outline`(punctuation)이 이 팔레트가 이미 읽을 수 있다고 주장하는
      // 최악값이고, 새 색이 그보다 나쁘면 그건 회귀다.
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
            reason: '${e.key}이 punctuation보다 읽기 어렵다',
          );
        }
      });
    });

    test('escape는 자기 리터럴과 같은 색이다', () {
      _sweep((scheme, p) => expect(p.escape, p.string));
    });

    test('그래도 자기 색상을 도입하지는 않는다', () {
      // 앵커는 언제나 중성 역할이고 목적지는 **앱의** 역할이다. 그러므로
      // 회색 스킴에서는 파생 팔레트도 회색이어야 한다 — 색을 들여왔다면
      // 여기서 드러난다.
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
