import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokenizer/dart_tokenizer.dart';
import 'syntax_palette.dart';

/// Dart 소스를 구문 강조해 그린다. 선택할 수 있고, 복사할 수 있다.
///
/// **소스 문자열을 받는다. asset 키가 아니다.** 어디서 읽어 오는지는 앱의 관심사고
/// 이 위젯은 이미 손에 든 바이트를 그린다. 그래서 로딩 상태가 없고, 그에 딸린
/// 실패 화면도 없다.
///
/// ## 가로 스크롤은 파라미터가 아니다
///
/// 코드는 줄바꿈하지 않는다 — **줄바꿈된 줄은 다른 줄이다.** 그래서 가로 스크롤은
/// 협상 대상이 아니고 언제나 이 위젯이 소유한다. [scrollable]은 **세로만**
/// 지배한다: 끄면 세로로 shrink-wrap해 글 안의 코드 블록처럼 쓸 수 있고, 켜면
/// 자기 영역 안에서 스크롤한다.
///
/// [ScrollController]도 어느 쪽이든 이 위젯이 이름 붙여 소유한다. **이유는
/// [Scrollbar]가 추적할 대상을 분명히 갖게 하기 위해서다** — 이름 없는 컨트롤러로는
/// 어느 [Scrollable]을 그리는지가 모호해진다.
///
/// 참조 구현은 여기에 다른 이유도 적어 두었다: `primary`가 켜지면 두 스크롤 뷰가
/// 같은 [PrimaryScrollController]를 주장해 framework가 assert한다는 것. **재보니
/// 그렇지 않다.** [PrimaryScrollController] 아래에서 `primary: true`로 감싸도
/// 예외가 나지 않고 `positions.length`는 1이다 — [SelectableText]는 자기
/// [EditableText]에 컨트롤러를 넘기지 않고, 그 [Scrollable]은 primary를 애초에
/// 주장하지 않는다. 2026-09-06 측정.
///
/// ## 가로는 끌어서 넘길 수 없다. 선택 가능한 것의 대가다
///
/// 텍스트 위에서 가로로 드래그하면 스크롤되지 않는다. 세로는 된다. 측정
/// (2026-09-06, 300×300 뷰포트, 뷰포트 중심에서 120px 드래그):
///
/// ```
/// SelectableText        세로 100.0   가로 0.0
/// SelectionArea + Text  세로 100.0   가로 0.0
/// Text (선택 불가)       세로 100.0   가로 100.0
/// ```
///
/// **선택 제스처가 가로 드래그를 가져간다.** [SelectionArea]로 바꿔도 같으므로
/// [SelectableText]의 문제가 아니라 선택 그 자체의 대가다. 선택을 포기하지 않는 한
/// 고칠 수 없다.
///
/// 그래서 가로 [Scrollbar]는 장식이 아니라 **터치에서 유일한 가로 어포던스**다.
/// 데스크톱에서는 트랙패드와 휠도 쓸 수 있다. 이 위젯에서 스크롤바를 걷어내려는
/// 사람은 이 문단을 먼저 읽어야 한다.
///
/// ## 글꼴은 `TextStyle` 하나가 아니라 숫자 몇 개로 받는다
///
/// [TextStyle]을 통째로 받으면 `inherit: true` 함정을 소비자에게 그대로 건넨다 —
/// 앰비언트 [DefaultTextStyle]이 머지되어, family를 지목하지 않고 fallback만
/// 나열한 스타일은 **앱의 비례 글꼴로 그려진다.** 필요한 값만 이름 붙여 받으면
/// 그 총구가 소비자를 향하지 않는다.
///
/// [fontFamily]가 null이어도 **반드시 non-null family가 지목된다.** null을
/// "설정하지 않음"으로 해석하면 위의 상속이 되돌아온다.
///
/// 루트 스타일의 색은 `ColorScheme.onSurface`다. 팔레트가 [DartTokenKind.plain]에
/// 스타일을 주지 않으면 평범한 코드는 그 색으로 그려진다 — 파생 기본값이 실제로
/// 그렇고, 색이 있는 팔레트를 넘기면서 `plain`을 비워 두면 앱 테마의 색이 남는다.
///
/// ## 줄 번호는 없다
///
/// 이 위젯은 붙여넣을 수 있는 조각을 보이는 것이지 소스 뷰어가 아니다. 그리고 그
/// 기능의 자연스러운 구현이 곧 망가진 구현이다 — 인라인 gutter를 placeholder
/// 스팬으로 만들면 [SelectableText]가 `includePlaceholders`를 기본값으로 두므로
/// **복사되는 모든 줄에 `\u{FFFC}`가 들어간다.** 자식이 [TextSpan]이어야 한다는
/// 것은 문서에만 적혀 있고 assert되지 않는다. 그 가드가 테스트에 있다.
class SyntaxText extends StatefulWidget {
  const SyntaxText(
    this.source, {
    super.key,
    this.palette,
    this.copyable = true,
    this.scrollable = true,
    this.fontFamily,
    this.fontFamilyFallback,
    this.fontSize = 12.5,
    this.height = 1.45,
    this.padding = const EdgeInsets.all(16),
    this.copyTooltip = 'Copy',
    this.copiedTooltip = 'Copied',
  });

  /// 그릴 Dart 소스.
  final String source;

  /// null이면 `SyntaxPalette.fromColorScheme(Theme.of(context).colorScheme)`.
  final SyntaxPalette? palette;

  /// 코드 영역 우상단의 복사 오버레이.
  ///
  /// **이 버튼의 정당화 두 개가 참조 구현에서 이미 철회됐다.** "발견 가능성"과
  /// "터치 플랫폼 보완"이었는데, 같은 측정이 둘 다 틀렸음을 보였다 —
  /// `AdaptiveTextSelectionToolbar`가 Android에서 이미 복사를 제공한다. 되돌아오지
  /// 않게 여기 적어 둔다.
  ///
  /// 그럼에도 남긴 이유는 편의다. 검증 장치가 아니다 — 붙여넣기 보장을 지키는 것은
  /// 렌더된 트리가 원본 바이트로 평탄화되는지를 보는 검사이지 클립보드가 아니다.
  final bool copyable;

  /// 복사 버튼의 툴팁. 기본값이 영문이므로 앱의 언어에 맞춰 넘긴다.
  final String copyTooltip;

  /// 복사 직후의 툴팁.
  final String copiedTooltip;

  /// **세로 스크롤만** 지배한다. 가로는 언제나 이 위젯이 소유한다.
  final bool scrollable;

  /// null이면 실행 플랫폼의 고정폭 글꼴을 지목한다.
  final String? fontFamily;

  /// null이면 [monoCandidates]에서 선택된 family를 뺀 것.
  final List<String>? fontFamilyFallback;

  final double fontSize;
  final double height;
  final EdgeInsetsGeometry padding;

  /// 플랫폼별 고정폭 글꼴.
  ///
  /// 하나를 골라 **반드시 지목한다.** family를 지목하는 행위 자체가 앰비언트
  /// 스타일의 상속을 밀어내기 때문이다.
  static String get defaultMonoFamily {
    if (kIsWeb) return 'monospace';
    return switch (defaultTargetPlatform) {
      TargetPlatform.macOS || TargetPlatform.iOS => 'Menlo',
      TargetPlatform.windows => 'Consolas',
      TargetPlatform.android => 'monospace',
      TargetPlatform.linux || TargetPlatform.fuchsia => 'DejaVu Sans Mono',
    };
  }

  /// 존재할 법한 순서의 고정폭 글꼴 후보들.
  ///
  /// [defaultMonoFamily]가 이 목록에서 하나를 고르므로, 그대로 쓰면 **family가
  /// 첫 fallback이기도 한** 상태가 된다. 그 모양이 실제로 한 버그를 오래 숨겼다 —
  /// `fallback.first`가 family처럼 보여서, family가 아예 설정되지 않았다는 사실을
  /// 아무도 눈치채지 못했다. 그래서 실제로 넘기는 것은 [fallbackWithout]이 고른
  /// family를 빼고 남긴 목록이다.
  static const monoCandidates = [
    'SF Mono',
    'Menlo',
    'Consolas',
    'DejaVu Sans Mono',
    'Liberation Mono',
    'monospace',
  ];

  /// [family]를 뺀 [monoCandidates].
  static List<String> fallbackWithout(String family) =>
      monoCandidates.where((f) => f != family).toList(growable: false);

  @override
  State<SyntaxText> createState() => _SyntaxTextState();
}

class _SyntaxTextState extends State<SyntaxText> {
  /// 토큰은 비싸고 안정된 쪽, 스타일은 싸고 테마를 따라가는 쪽이다.
  ///
  /// **재스캔을 없앨 뿐 그 이상은 아니다.** [SelectableText]는 `textSpan`이
  /// 이전 것과 같지 않다고 비교될 때마다 컨트롤러를 다시 만들고, [TextSpan]의
  /// 동등성은 `identical`에서만 짧게 끝난다 — [build]가 토큰마다 새 스팬을
  /// 만드는 한 그 깊은 비교는 캐시 여부와 무관하게 일어난다.
  ///
  /// **그리고 그것을 지키는 테스트는 없다.** 캐시를 없애고 [build]에서 매번
  /// 토크나이즈해도 그려지는 것이 똑같기 때문이다 — 관측 가능한 차이가 없으므로
  /// 실패할 수 있는 검사를 쓸 수 없다. 스캔 횟수를 세려면 토크나이저를 주입
  /// 가능하게 만들어야 하는데, 그 이음매의 비용이 이 캐시가 아끼는 것보다 크다.
  /// 2026-09-06 측정으로 이 저장소에서 가장 큰 파일이 3101 토큰이다.
  late List<DartToken> _tokens;

  final _vertical = ScrollController();
  final _horizontal = ScrollController();

  Timer? _confirmation;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _tokens = tokenizeDart(widget.source);
  }

  @override
  void didUpdateWidget(SyntaxText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source == widget.source) return;
    // 소스만 본다. 밝기가 바뀌면 같은 토큰을 다시 칠할 뿐이다.
    _tokens = tokenizeDart(widget.source);
    // **확인 표시는 그것이 보여진 소스의 것이다.** 리셋하지 않으면 A를 복사하고
    // 잠깐 뒤 B로 바꿨을 때, 복사된 적 없는 것 옆에 초록 체크가 남는다.
    _confirmation?.cancel();
    _copied = false;
  }

  @override
  void dispose() {
    // 트리보다 오래 사는 타이머는 그것을 pump한 테스트를 실패시키며, 그것이
    // 옳은 동작이라 선택 사항이 아니다.
    _confirmation?.cancel();
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.source));
    setState(() => _copied = true);
    _confirmation?.cancel();
    // 유한한 것이 의도다. 불확정 인디케이터에서는 `pumpAndSettle`이 영원히
    // 정착하지 않는다.
    _confirmation = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = widget.palette ?? SyntaxPalette.fromColorScheme(scheme);

    final family = widget.fontFamily ?? SyntaxText.defaultMonoFamily;

    Widget code = SelectableText.rich(
      // 루트 스팬은 자기 스타일을 갖지 않는다. `SelectableText`가 받은 것을
      // `TextSpan(style: style, children: [주어진 것])`으로 감싸므로, 아래의
      // face가 모든 토큰이 물려받는 것이자 `EditableText.style`이 보고하는 것이다.
      TextSpan(
        children: [
          for (final token in _tokens)
            TextSpan(text: token.text, style: palette.styleFor(token.kind)),
        ],
      ),
      style: TextStyle(
        fontSize: widget.fontSize,
        height: widget.height,
        fontFamily: family,
        fontFamilyFallback:
            widget.fontFamilyFallback ?? SyntaxText.fallbackWithout(family),
        color: scheme.onSurface,
      ),
    );

    code = Padding(padding: widget.padding, child: code);

    // 가로는 언제나. 줄바꿈된 줄은 다른 줄이다.
    code = Scrollbar(
      controller: _horizontal,
      child: SingleChildScrollView(
        controller: _horizontal,
        scrollDirection: Axis.horizontal,
        child: code,
      ),
    );

    if (widget.scrollable) {
      code = Scrollbar(
        controller: _vertical,
        child: SingleChildScrollView(controller: _vertical, child: code),
      );
    }

    if (!widget.copyable) return code;

    return Stack(
      children: [
        code,
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            tooltip: _copied ? widget.copiedTooltip : widget.copyTooltip,
            iconSize: 17,
            visualDensity: VisualDensity.compact,
            onPressed: _copy,
            icon: Icon(
              _copied ? Icons.check : Icons.copy_all_outlined,
              color: _copied ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
