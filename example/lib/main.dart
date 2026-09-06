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

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  var _brightness = Brightness.light;
  var _palette = palettes.keys.first;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_syntax_highlight',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: _brightness,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('flutter_syntax_highlight'),
          actions: [
            // 밝기 토글. 파생 기본값이 양쪽에서 맞다는 주장을 눈으로 보이는
            // 장치이고, 실명 프리셋이 반대 밝기에서 보이지 않게 되는 것도 같이
            // 보인다.
            IconButton(
              tooltip: _brightness == Brightness.light ? '다크로' : '라이트로',
              icon: Icon(
                _brightness == Brightness.light
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
              ),
              onPressed: () => setState(
                () => _brightness = _brightness == Brightness.light
                    ? Brightness.dark
                    : Brightness.light,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
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
