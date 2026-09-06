import 'package:flutter/material.dart';

import '../tokenizer/dart_tokenizer.dart';

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
