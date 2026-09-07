import 'package:flutter/material.dart';
import 'package:flutter_syntax_highlight/flutter_syntax_highlight.dart';

void main() => runApp(const ExampleApp());

/// 보여줄 조각.
///
/// **중첩 보간이 들어 있는 것이 요점이다.** `'${term.value ? '✓' : '✗'}'`에서
/// 안쪽 `'✓'`가 **문자열로** 그려지는 것이 화면에 보인다 — 따옴표를 단순히
/// 짝짓는 스캐너는 정확히 그 반대로 칠한다. 이 패키지가 존재하는 이유이고,
/// 스크린샷이 가리켜야 하는 글자다.
///
/// 나머지는 여덟 kind가 전부 나오도록 골랐다: 주석, 키워드, 문자열, 숫자,
/// 구두점, escape, 호출 이름, 그리고 평범한 식별자.
const sample = r'''
// A ledger line, rendered by the package that draws this page.
class Term {
  const Term(this.key, {this.value = false});

  final String key;
  final bool value;

  /// The three interpolation sites this package exists for.
  String describe(List<String> selected, String? newValue) {
    final tidy = '${newValue ?? ''}'.trim();
    final rows = 'selectedRows: ${selected.join(', ')}';
    return '${value ? '✓' : '✗'} $key\t$tidy\n$rows';
  }

  static const limit = 0xFF;
  static const ratio = 1.5e3;
}
''';

/// 고를 수 있는 팔레트들.
///
/// **패키지는 이름 룩업을 두지 않는다** — 프리셋을 고르게 하려는 소비자가 자기
/// 목록을 쓴다. 이것이 그 목록이고, 이 파일이 그 결정의 유일한 소비자다.
///
/// 첫 항목만 null이다: 팔레트를 넘기지 않으면 `SyntaxPalette.fromColorScheme`이
/// 쓰이고, 그것만이 라이트와 다크 양쪽에서 설정 없이 맞는다.
const palettes = <String, SyntaxPalette?>{
  'ColorScheme에서 파생 (기본값)': null,
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

/// 고를 수 있는 시드.
///
/// **파생 기본값이 앱의 스킴에서 나온다는 주장을 실연하는 장치다.** 문장으로만
/// 하던 주장을 시드를 바꿔 눈으로 보인다 — 문자열과 호출 이름의 색이 스킴을
/// 따라 같이 움직인다.
///
/// 마지막 항목이 요점이다: 무채색 스킴에서는 **팔레트도 무채색이 된다.** 이
/// 패키지는 앱의 색상을 빌릴 뿐 자기 색상을 도입하지 않으므로, 빌릴 것이 없으면
/// 아무 색도 나오지 않는다.
class Seed {
  const Seed(this.label, this.colour,
      {this.variant = DynamicSchemeVariant.tonalSpot});

  final String label;
  final Color colour;
  final DynamicSchemeVariant variant;
}

const seeds = <Seed>[
  Seed('보라', Color(0xFF6750A4)),
  Seed('청록', Color(0xFF006B5F)),
  Seed('주황', Color(0xFFB3541E)),
  Seed('파랑', Color(0xFF0B57D0)),
  Seed('무채색', Color(0xFF5A5A5A), variant: DynamicSchemeVariant.monochrome),
];

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  var _brightness = Brightness.light;
  var _seed = seeds.first;
  var _palette = palettes.keys.first;

  @override
  Widget build(BuildContext context) {
    final isLight = _brightness == Brightness.light;
    return MaterialApp(
      title: 'flutter_syntax_highlight',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed.colour,
          brightness: _brightness,
          dynamicSchemeVariant: _seed.variant,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('flutter_syntax_highlight'),
          actions: [
            // 시드 스와치. 파생 기본값이 앱의 스킴에서 나온다는 것을 눈으로
            // 보이는 장치이고, 마지막 칸(무채색)이 "자기 색상을 도입하지
            // 않는다"를 보인다 — 빌릴 색이 없으면 아무 색도 안 나온다.
            for (final seed in seeds)
              IconButton(
                tooltip: seed.label,
                onPressed: () => setState(() => _seed = seed),
                icon: Icon(
                  seed == _seed ? Icons.circle : Icons.circle_outlined,
                  color: seed.colour,
                  size: 18,
                ),
              ),
            const SizedBox(width: 8),
            // 밝기 토글. 파생 기본값이 양쪽에서 맞다는 주장을 눈으로 보이는
            // 장치이고, 실명 프리셋이 반대 밝기에서 보이지 않게 되는 것도 같이
            // 보인다.
            IconButton(
              tooltip: isLight ? '다크로' : '라이트로',
              icon: Icon(
                isLight ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              ),
              onPressed: () => setState(
                () =>
                    _brightness = isLight ? Brightness.dark : Brightness.light,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          // 기본값 `center`는 `Expanded`가 늘리는 세로만 두고 가로로는 코드
          // 블록을 자기 텍스트 폭으로 쪼그라뜨려 가운데 세운다. 코드 뷰어는
          // pane을 채워야 하고, 채우지 않으면 가로 스크롤이 화면에 나타나지도
          // 않는다 — 스크린샷을 찍다가 잡았다.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  const Text('팔레트'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _palette,
                      items: [
                        for (final name in palettes.keys)
                          DropdownMenuItem(value: name, child: Text(name)),
                      ],
                      onChanged: (name) =>
                          setState(() => _palette = name ?? _palette),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SyntaxText(
                sample,
                palette: palettes[_palette],
                copyTooltip: '복사',
                copiedTooltip: '복사됨',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
