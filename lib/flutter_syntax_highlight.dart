/// Dart 소스를 구문 강조해 그리는, 두 층으로 나뉜 패키지의 공개 진입점.
///
/// 층을 가르는 것은 하나의 **이음매**다: **토크나이저**는 kind가 *무엇인지*를
/// 정하고, **위젯**은 kind가 *어떻게 보이는지*를 정한다. 토크나이저가 `Color`를
/// 아는 순간 두 층은 용접되고, 그러면 렌더링 없이는 아무것도 검증할 수 없게 된다.
///
/// 토크나이저가 돌려주는 것은 **partition**이다 — 토큰들의 텍스트를 이어 붙이면
/// 입력과 바이트 단위로 같다. 용어는 `CONTEXT.md`에, kind 목록의 근거는
/// `docs/adr/0001-token-kinds-are-lexical-only.md`에 있다.
///
/// 아래층만 필요하다면 [tokenizeDart]만 가져다 쓰면 된다. 위젯 층은 아직 없다.
library;

export 'src/tokenizer/dart_tokenizer.dart';
