import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 두 층 사이의 이음매를 봉인한다.
///
/// **pubspec은 더 이상 이것을 강제할 수 없다.** 이 패키지가 Flutter에 의존하게
/// 되었기 때문이다. 참조 구현에서는 토크나이저가 Flutter를 모르는 패키지에 살아서
/// 의존성 그래프 자체가 가드였지만, 여기서는 그 가드가 사라졌다.
///
/// 그것이 없으면 스캐너에서 `Color`를 집는 첫 번째 사람이 두 층을 조용히 용접하고,
/// 아무것도 그것을 보고하지 않는다. 그 다음부터 "어려운 부분은 위젯 없이 테스트할
/// 수 있는 순수 함수"라는 주장은 거짓이 되지만 초록은 그대로다.
void main() {
  // `import`만 보면 세 방향으로 샌다:
  //
  //  * `export 'package:flutter/...'`는 정확히 같은 구멍이다.
  //  * **`part`가 가장 현실적인 구멍이다.** 토크나이저를 Flutter를 import하는
  //    라이브러리의 `part`로 만들면, 이 파일에는 지시문 한 줄 없이 `Color`가
  //    들어온다. 지시문을 세는 검사가 통째로 우회된다.
  //  * `import'dart:math';`는 공백 없이도 유효한 Dart다. `\\s+`를 요구하면 놓친다.
  //
  // 그래서 따옴표를 요구하지 않고 지시문 키워드 자체를 본다. 거짓 양성이 나는
  // 방향이며(`part`로 시작하는 식별자 줄), 그쪽이 안전한 방향이다.
  final directive = RegExp(r'^\s*(import|export|part)\b');

  test('토크나이저 층은 아무것도 import하지 않는다', () {
    final dir = Directory('lib/src/tokenizer');
    expect(
      dir.existsSync(),
      isTrue,
      reason: '토크나이저 층이 없다면 이 테스트는 아무것도 지키지 않는다',
    );

    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    // 부수 조건 둘. 이 가드의 경계는 **디렉터리**라서, 지키려는 대상이 거기서
    // 빠져나가면 루프가 공허하게 통과한다.
    expect(
      files,
      isNotEmpty,
      reason: '읽을 파일이 없다 — 이 테스트는 실패할 수 없는 상태가 되었다',
    );
    expect(
      files.map((f) => f.uri.pathSegments.last),
      contains('dart_tokenizer.dart'),
      reason: '스캐너가 이 디렉터리에 없다. 다른 .dart 파일 하나만 남아 있어도 '
          '위의 isNotEmpty는 통과하므로, 가드가 조용히 빈 채로 초록이 된다',
    );

    final offenders = <String>[];
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var n = 0; n < lines.length; n++) {
        if (directive.hasMatch(lines[n])) {
          offenders.add('${file.path}:${n + 1}  ${lines[n].trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: '토크나이저 층이 무언가를 끌어왔다. 두 층이 용접되면 kind가 '
          '무엇인지와 kind가 어떻게 보이는지가 한 곳에 살게 되고, 그러면 앞의 '
          '것을 뒤의 것 없이 시험할 수 없다:\n${offenders.join('\n')}',
    );
  });
}
