import 'package:flutter_syntax_highlight/flutter_syntax_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

/// 모든 문자가, 순서대로, 정확히 한 번.
///
/// 붙여넣기 계약 그 자체다. 여러 곳에서 손으로 반복하면 한 곳이 어긋나므로 한
/// 번만 쓰고, 그래서 테스트 파일 밖에 산다.
///
/// **partition만 검사하면 실패할 수 없는 테스트가 된다.** 소스 전체를 `plain`
/// 토큰 하나로 뱉는 토크나이저도 partition을 완벽히 만족한다 — 추측이 아니라
/// 측정이다. 실제로 그렇게 바꿔 돌려 보니 corpus 검사 전체가 초록이었다.
///
/// 그래서 내용이 있는 입력에 대해서는 **스캐너가 실제로 분류했다**는 부수 조건을
/// 함께 건다. 이 한 줄이 없으면 이 파일의 모든 호출부가 아무것도 지키지 않는다.
///
/// [expectClassified]는 그 부수 조건을 끈다. 통째로 토큰 하나인 것이 **그
/// 테스트의 주장 자체**인 입력이 있다 — 보간을 포함한 문자열 리터럴 하나 같은
/// 것. 그 경우 kind가 하나인 것이 옳으므로, 끄되 이름을 붙여 왜 껐는지가
/// 호출부에 남게 한다.
void expectPartitions(
  String source, {
  String? label,
  bool expectClassified = true,
}) {
  final tokens = tokenizeDart(source);
  final where = label == null ? '' : ' ($label)';

  expect(
    tokens.map((t) => t.text).join(),
    source,
    reason: '입력이 토큰화를 거치며 달라졌다$where — '
        '화면에 그려지는 것이 더 이상 소비자가 건넨 바이트가 아니다',
  );

  // 공백뿐인 입력은 한 kind로 나오는 것이 옳다. 그 경우까지 다양성을 요구하면
  // 참인 것을 빨갛게 만든다.
  if (!expectClassified || source.trim().isEmpty) return;

  expect(
    tokens.map((t) => t.kind).toSet().length,
    greaterThan(1),
    reason: '토큰 하나가 전부를 덮어도 partition은 만족된다$where. '
        '스캐너가 분류를 그만두면 이 조건이 잡는다',
  );
}
