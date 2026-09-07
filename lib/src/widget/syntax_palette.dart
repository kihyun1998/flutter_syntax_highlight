import 'package:flutter/material.dart';

import '../tokenizer/dart_tokenizer.dart';

part 'syntax_presets.dart';

/// kind가 어떻게 보이는지 — 이음매의 정책 쪽.
///
/// **테마 엔진이 아니다.** 프리셋을 등록하는 레지스트리도, 이름으로 찾는 룩업도,
/// 색을 계산하는 로직도 없다. 여덟 개의 [TextStyle]이고, 주지 않은 것은 null로
/// 남아 루트 스타일을 그대로 물려받는다.
///
/// 이 타입이 존재하는 이유는 토크나이저가 `Color`를 알지 못하게 하기 위해서다.
/// 토크나이저는 kind가 *무엇인지*를 정하고, 여기서는 kind가 *어떻게 보이는지*를
/// 정한다. 그 선이 무너지면 어휘 분류를 렌더링 없이는 시험할 수 없게 된다.
///
/// ## 기본값은 소비자의 `ColorScheme`에서 파생된다
///
/// [SyntaxPalette.fromColorScheme]이 기본값이고, **소비자의 스킴에 색상을 더하지
/// 않는다.** [ColorScheme.onSurface], [ColorScheme.onSurfaceVariant],
/// [ColorScheme.outline] 세 역할만 읽는다. 앱이 무채색이면 무채색이 되고, 색이
/// 있으면 그 색에 섞인다.
///
/// 참조 구현은 이것을 *"hue-free, and that is a constraint rather than a taste"*
/// 라고 적었지만, 그 근거는 그 앱의 스킴이 `DynamicSchemeVariant.monochrome`이라
/// **가져올 색상이 애초에 없었다**는 것이었다. 라이브러리로 오면서 그 전제가
/// 사라졌으므로 문장을 다시 썼고, 다시 쓴 쪽이 더 보편적이다 — 조건이 아니라
/// 성질이다.
///
/// 파생이기 때문에 라이트와 다크 양쪽이 설정 없이 맞는다. 하드코딩된 팔레트는
/// 반대 밝기에서 조용히 깨진다.
///
/// **대가가 있고, 숨기지 않는다.** 색상을 도입하지 않으면 쓸 수 있는 축이
/// 밝기·굵기·기울임 셋뿐이고, `ColorScheme`의 역할들이 서로 얼마나 떨어져 있는지는
/// 우리가 정하지 않는다. 2026-09-06 측정: `ColorScheme.fromSeed(0xFF6750A4)`에서
/// `onSurface` 대 `onSurfaceVariant`의 대비는 다크 **1.32**, 라이트 **1.83**이다 —
/// 평범한 코드와 문자열의 차이가 그만큼 옅다. 색이 있는 실명 프리셋에는 이 한계가
/// 없다.
///
/// ## 주석만 흐려지지 않는다
///
/// 보통의 하이라이터는 주석을 흐리고 키워드를 밝힌다. 그것은 **이미 아는 코드를
/// 훑는** 상황을 가정한 것이고, 이 패키지가 그리는 코드는 대개 읽히려고 놓인
/// 것이다.
///
/// 더 단단한 근거가 있다. 키워드도 구두점도 Dart를 아는 사람이면 코드에서 다시
/// 읽어낼 수 있지만, **주석은 코드에서 복원되지 않는 유일한 부분**이다. 복원되지
/// 않는 것만 골라 흐리는 것은 거꾸로다. 그래서 기울임이 주석을 분리하되 대비는
/// 그대로 두고, 대신 물러나는 것은 punctuation이다.
///
/// 참조 구현은 여기에 측정치를 붙였다 — 2026-09-02 기준 그 corpus 2603줄 중
/// 762줄(29%)이 주석이었다. **그 숫자는 이 결론의 근거가 될 수 없다.** 가르치려고
/// 쓴 corpus의 값이고, 보통의 애플리케이션 코드는 그보다 훨씬 낮다. 측정치로만
/// 남긴다.
///
/// ## 어떤 스타일도 `fontFamily`를 지정하지 않는다
///
/// 하드 룰이다. family를 지목하는 잎은 비례 글꼴로 그려지면서, 겉포장인
/// `EditableText.style`을 읽는 가드는 초록으로 남는다. 고정폭 face는 위젯이 한
/// 번만 지정하고 모든 토큰이 물려받는다.
@immutable
class SyntaxPalette {
  /// 주지 않은 kind는 null로 남아 루트 스타일을 물려받는다.
  const SyntaxPalette({
    this.background,
    this.plain,
    this.comment,
    this.keyword,
    this.string,
    this.number,
    this.punctuation,
    this.escape,
    this.function,
  });

  /// 소비자의 [ColorScheme]에서 파생된 기본 팔레트.
  ///
  /// 위 doc의 두 문단 — 색상을 더하지 않는다는 것과 주석을 흐리지 않는다는 것 —
  /// 이 여기 구현되어 있다.
  factory SyntaxPalette.fromColorScheme(ColorScheme scheme) => SyntaxPalette(
        // **[background]를 주지 않는다.** 앱이 이미 칠해 둔 surface가 이
        // 팔레트에게 올바른 배경이다 — `scheme.surface`를 여기서 다시 칠하면
        // 같은 색을 한 겹 더 얹으면서, 앱이 코드 블록만 다른 surface 위에
        // 올려 두는 자유를 뺏는다.
        // `plain`은 주지 않는다. 루트 스타일이 이미 평범한 코드가 가져야 할
        // 색이고, 토큰마다 객체 하나를 덜 만든다.
        comment: const TextStyle(fontStyle: FontStyle.italic),
        keyword: const TextStyle(fontWeight: FontWeight.w600),
        string: TextStyle(color: scheme.onSurfaceVariant),
        number: TextStyle(color: scheme.onSurfaceVariant),
        // 문자열과 **같게** 그린다. 조사한 테마 9종은 전부 escape에 다른 색을
        // 주지만, 그것들에는 색상이 있다. 여기 남은 축은 밝기·굵기·기울임 셋뿐이고
        // 이미 다 쓰였으므로, 줄 수 있는 것이 없다.
        //
        // 그래서 escape는 자기 리터럴과 함께 그려진다 — 그것의 일부이기도 하다.
        // 프리셋 조사(#9)에서 열 중 넷이 escape를 number와 같은 색으로 칠하는
        // 것을 보면, 항상 구분하는 것이 보편적인 선택도 아니다. 다만 그것은
        // 근거가 아니라 곁증거다. 근거는 이 팔레트에 남은 축이 없다는 것이다.
        escape: TextStyle(color: scheme.onSurfaceVariant),
        // **`function`은 주지 않는다.** 조사한 테마 9/9가 호출 이름을 다르게
        // 칠하지만 그것들에는 색상이 있다. 여기서 남은 축은 밝기·굵기·기울임
        // 셋뿐이고 이미 다 쓰였다 — 굵기는 keyword, 기울임은 comment, 흐림은
        // 문자열과 punctuation. 세 번째 굵기를 얹으면 조용하려고 만든 팔레트가
        // 시끄러워지고, `onSurface`를 주면 루트와 같은 색이라 아무 구분도 되지
        // 않는다.
        //
        // 그래서 파생 기본값은 호출을 구분하지 않는다. kind는 남아 있고, 색이
        // 있는 실명 프리셋이 그것을 쓴다.
        punctuation: TextStyle(color: scheme.outline),
      );

  // ───────────────────────────────────────────────────────────────────────
  // 이름 붙은 프리셋
  //
  // **재현이 아니라 발췌다.** 원본 테마들은 TextMate scope 수십~수백 개에 색을
  // 매기고 이 패키지의 kind는 여덟이다. 각 프리셋은 원본이 그 여덟에 해당하는
  // scope에 준 색을 뽑아 온 것이라, 원본 에디터와 똑같이 보이지 않는다.
  //
  // 값과 출처는 `syntax_presets.dart`와 `NOTICES`에 있다.
  //
  // 각 프리셋은 [background]를 함께 들고 있고, 색들은 **그 배경 위에서** 고른
  // 것이다. 측정(2026-09-07, 자기 배경 대비 본문 명도비): 4.13(solarizedLight)
  // ~ 13.94(monokai), 열 개 전부 4.1 이상이다.
  //
  // 이 문단의 앞선 판본은 반대를 주장했다 — *"반대 밝기에서는 깨지는 정도가
  // 아니라 보이지 않는다"*며 `cobalt2`의 본문 `#FFFFFF`가 명도비 **1.00**이라고
  // 적었다. **그 수치는 지금도 맞고, 재는 대상이 틀렸다.** 1.00은 흰 본문을
  // *앱의* 라이트 surface에 대고 잰 값이었다. 팔레트가 배경을 들고 있지 않아서
  // 그것 말고는 잴 것이 없었고, 그 부재가 프리셋의 성질처럼 읽혔다. 자기 배경인
  // `#193549`에 대고 재면 **12.75**다.
  //
  // 그래서 짝으로 싣는 이유도 바뀐다. 가독성이 아니라 **밝기 취향**이다 —
  // 라이트 앱에 `oneDark`를 얹으면 읽기는 잘 읽히지만 코드 블록만 어둡다. 고를
  // 것이 있어야 한다.
  //
  // 기본값은 여전히 이것들이 **아니다.** [SyntaxPalette.fromColorScheme]만이
  // 앱의 surface를 그대로 배경으로 두어, 코드 블록이 앱에서 이물감이 없다.
  //
  // 이름으로 찾는 룩업은 두지 않는다. 프리셋을 고르게 하려는 소비자는 자기 목록을
  // 쓴다 — 그것이 레지스트리를 만들지 않기로 한 결정이다.
  // ───────────────────────────────────────────────────────────────────────

  /// Solarized Dark에서 **발췌**한 색. 재현이 아니다.
  static const solarizedDark = _solarizedDark;

  /// Solarized Light에서 **발췌**한 색. 재현이 아니다.
  static const solarizedLight = _solarizedLight;

  /// One Dark에서 **발췌**한 색. 재현이 아니다.
  ///
  /// 이름이 `atomOneDark`가 아닌 것은 `ATOM`이 GitHub의 상표이기 때문이다. 값은
  /// `atom/one-dark-syntax`에서 왔고 그 파일의 라이선스는 MIT다 — **라이선스와
  /// 상표는 다른 축이고, MIT는 상표권을 넘기지 않는다.**
  ///
  /// 그 상표 판정은 2026-09-07에 교차 확인했다: US Reg. 4,819,136, GitHub, Inc.,
  /// Class 009의 지정상품이 *"소프트웨어를 개발하고 편집하는 다운로드 가능
  /// 소프트웨어"*다 — 코드 에디터를 곧바로 덮는다. 다만 **원본 대장이 아니라
  /// 공개 미러 둘이다.** `NOTICES`가 그 단서를 들고 있다.
  static const oneDark = _oneDark;

  /// One Light에서 **발췌**한 색. 재현이 아니다.
  static const oneLight = _oneLight;

  /// Monokai에서 **발췌**한 색. 재현이 아니다.
  ///
  /// 주석이 기울지 않는 유일한 프리셋이다 — 원본이 그렇다. `escape`가 `number`와
  /// 같은 색인 것도 원본 그대로다: 이 테마에는 `constant.character.escape` 전용
  /// 규칙이 없어 상위 `constant` 규칙에 흡수된다.
  static const monokai = _monokai;

  /// Gruvbox Dark에서 **발췌**한 색. 재현이 아니다.
  ///
  /// 값이 Vim 정본이 아니라 MIT 이식본에서 왔다 — `morhetz/gruvbox`에는 LICENSE
  /// 파일이 없고 저작권자 문장이 존재하지 않아 `NOTICES`에 옮겨 적을 원문이
  /// 없다. 대가로 두 슬롯의 충실도를 내줬다: 이식본은 `escape`를 `constant`
  /// 규칙에 흡수하고 함수를 노랑으로 칠하는데, 정본은 escape에 고유한 주황을
  /// 주고 함수를 초록+굵게 한다. **두 값 집합을 섞지 않았다** — 섞으면 어디에도
  /// 존재하지 않는 팔레트가 된다.
  static const gruvboxDark = _gruvboxDark;

  /// Gruvbox Light에서 **발췌**한 색. 재현이 아니다. [gruvboxDark] 참조.
  static const gruvboxLight = _gruvboxLight;

  /// Tokyo Night에서 **발췌**한 색. 재현이 아니다.
  static const tokyoNight = _tokyoNight;

  /// Tokyo Night Light에서 **발췌**한 색. 재현이 아니다.
  ///
  /// 이 프리셋의 `escape`(`#363C4D`)는 본문(`#343B59`)과 육안으로 거의 구분되지
  /// 않는다. **원본이 그렇게 정의했고, 추측으로 고칠 근거가 없어 그대로 싣는다.**
  static const tokyoNightLight = _tokyoNightLight;

  /// Cobalt2에서 **발췌**한 색. 재현이 아니다.
  static const cobalt2 = _cobalt2;

  /// 코드 영역 뒤에 칠할 색. null이면 아무것도 칠하지 않는다.
  ///
  /// **kind가 아니다.** 나머지 여덟은 한 구간의 글자를 어떻게 그릴지를 정하고,
  /// 이것은 그 글자들이 놓이는 자리를 정한다. 그래서 [styleFor]의 전수 `switch`에
  /// 들어가지 않으며, 이 필드가 생긴 것은 [DartTokenKind]에 값을 더하는 것과
  /// 달리 breaking change가 아니다.
  ///
  /// **파생 기본값은 이것을 주지 않는다.** [SyntaxPalette.fromColorScheme]에게
  /// 올바른 배경은 앱이 이미 칠해 둔 surface이고, 그 위에 자기 색을 얹지 않는
  /// 것이 곧 "색상을 더하지 않는다"의 내용이다. 실명 프리셋은 반대다 — 그 색들은
  /// 특정한 배경 위에서 고른 것이라, 배경 없이 옮기면 원본이 정한 대비가 사라진다.
  final Color? background;

  /// 식별자, 공백, 그리고 분류되지 않은 모든 것.
  final TextStyle? plain;

  /// `//`부터 줄 끝까지, 그리고 중첩 쌍을 포함한 `/* */`.
  final TextStyle? comment;

  /// 예약어, 내장 식별자, 문맥 키워드.
  final TextStyle? keyword;

  /// 문자열 리터럴 중 [escape]와 보간으로 잘려 나가지 않은 부분.
  final TextStyle? string;

  /// 정수, 실수, 16진 리터럴.
  final TextStyle? number;

  /// 괄호, 연산자, 구분자.
  final TextStyle? punctuation;

  /// 문자열 안의 escape 시퀀스.
  final TextStyle? escape;

  /// 여는 괄호 바로 앞의 식별자.
  final TextStyle? function;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyntaxPalette &&
          background == other.background &&
          plain == other.plain &&
          comment == other.comment &&
          keyword == other.keyword &&
          string == other.string &&
          number == other.number &&
          punctuation == other.punctuation &&
          escape == other.escape &&
          function == other.function;

  @override
  int get hashCode => Object.hash(
        background,
        plain,
        comment,
        keyword,
        string,
        number,
        punctuation,
        escape,
        function,
      );

  /// [kind]를 어떻게 그릴지. null이면 루트 스타일을 그대로 쓴다.
  ///
  /// 전수 `switch`인 것이 의도다. [DartTokenKind]에 값이 더해지면 **이 함수가
  /// 컴파일되지 않는다.**
  ///
  /// ADR-0001은 그 목록이 *"사실상 영구적"*이라고 적었다 — 소비자의 전수
  /// `switch`가 깨지므로 공개 후에는 breaking change이고, 그래서 조사가 근거를
  /// 준 시점에 못 박았다. 여기의 컴파일 에러는 그 문을 다시 여는 허가가 아니라,
  /// 누가 열려 할 때 소리가 나게 하는 장치다.
  TextStyle? styleFor(DartTokenKind kind) => switch (kind) {
        DartTokenKind.plain => plain,
        DartTokenKind.comment => comment,
        DartTokenKind.keyword => keyword,
        DartTokenKind.string => string,
        DartTokenKind.number => number,
        DartTokenKind.punctuation => punctuation,
        DartTokenKind.escape => escape,
        DartTokenKind.function => function,
      };
}
