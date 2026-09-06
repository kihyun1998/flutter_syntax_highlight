import 'dart:io';

import 'package:flutter_syntax_highlight/flutter_syntax_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

/// partition을 **진짜 코드 덩어리**에 건다.
///
/// 참조 구현은 호스트 앱의 번들에서 파일 열한 개를 읽어 이 성질을 돌렸다. 그
/// corpus는 여기 없으므로, 이 패키지가 소유한 두 가지로 대신한다:
///
///  * `test/fixtures/` — 참조 doc이 2026-09-02에 grep으로 열거한 어려운 구문들을
///    담아 직접 쓴 것. 왜 확장자가 `.dart`가 아닌지는 그 디렉터리의 README에 있다.
///  * `lib/` 아래 이 패키지 자신의 소스 — 공짜이고, 코드가 자라면 corpus도 같이
///    자라며, 항상 진짜 Dart다.
///
/// **줄바꿈 방식은 파일이 아니라 여기서 만든다.** `.gitattributes`가
/// `* text=auto`라 CRLF를 담은 파일은 체크아웃에서 정규화되고, 그러면 코드가
/// 아니라 그 머신을 시험하게 된다. 각 입력을 LF 그대로 한 번, `\r\n`으로 바꿔
/// 한 번 돌린다.
void main() {
  final fixtures = Directory('test/fixtures')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart.txt'))
      .toList();

  final ownSource = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  /// 모든 문자가, 순서대로, 정확히 한 번.
  void expectPartitions(String source, String label) {
    expect(
      tokenizeDart(source).map((t) => t.text).join(),
      source,
      reason: '$label이 토큰화를 거치며 달라졌다 — '
          '화면에 그려지는 것이 더 이상 소비자가 건넨 바이트가 아니다',
    );
  }

  group('partition — 붙여넣기 계약이 기대는 성질', () {
    // 부수 조건 둘. 어느 한쪽이 비면 아래 루프들은 공허하게 통과하고, 이
    // 파일은 실패할 수 없는 게이트가 된다.
    test('corpus가 비어 있지 않다', () {
      expect(
        fixtures,
        isNotEmpty,
        reason: '픽스처가 없다 — 이 파일의 검사들은 아무것도 돌리지 않는다',
      );
      expect(
        ownSource,
        isNotEmpty,
        reason: 'lib/ 아래 소스가 없다 — 자라는 쪽 corpus가 사라졌다',
      );
    });

    test('픽스처 corpus 전체에 대해 성립한다', () {
      for (final file in fixtures) {
        expectPartitions(file.readAsStringSync(), file.path);
      }
    });

    test('그리고 이 패키지 자신의 소스에 대해서도', () {
      for (final file in ownSource) {
        expectPartitions(file.readAsStringSync(), file.path);
      }
    });

    test('그리고 그 전부를 CRLF로 바꿔서 한 번 더', () {
      // 체크아웃이 무엇을 만들어냈든 무관하게 캐리지 리턴을 통과시킨다.
      // 개행으로 쪼개 다시 잇는 스캐너가 여기서 죽는다.
      for (final file in [...fixtures, ...ownSource]) {
        final crlf = file.readAsStringSync().replaceAll('\n', '\r\n');
        expect(
          crlf,
          contains('\r\n'),
          reason: '${file.path}에 개행이 없어 이 변환이 아무 일도 하지 않았다',
        );
        expectPartitions(crlf, 'CRLF로 바꾼 ${file.path}');
      }
    });
  });

  group('corpus가 담고 있다고 말하는 것을 실제로 담고 있다', () {
    // partition 검사만으로는 corpus가 무엇을 덮는지 알 수 없다. 빈 파일 넷도
    // partition을 만족한다. 픽스처가 편집되다 구문이 빠지면 위의 검사들은
    // 초록인 채로 아무것도 지키지 않게 되므로, 목록을 여기서 못 박는다.
    late final String all;

    setUpAll(() {
      all = fixtures.map((f) => f.readAsStringSync()).join('\n');
    });

    final constructs = <String, String>{
      "원시 문자열": r"r'",
      "삼중 따옴표 문자열": "'''",
      "escape된 따옴표": r"\'",
      "문자열 안의 //": '// not a comment',
      "중첩 블록 주석": '/* outer /* inner */',
      "아포스트로피 든 주석": "// somebody's",
      "중첩 보간": r"${term.value ? '",
      "보간 안 문자열의 중괄호": r"${map['{']}",
      "닫히지 않은 문자열": "final a = 'oops",
      "닫히지 않은 보간": r"'${oops",
    };

    constructs.forEach((name, needle) {
      test(name, () {
        expect(
          all,
          contains(needle),
          reason: '픽스처에서 사라졌다 — corpus가 이 구문을 더 이상 덮지 않는다',
        );
      });
    });
  });
}
