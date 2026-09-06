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
  // `import`만이 아니라 `export`도 본다. `export 'package:flutter/...'`는 정확히
  // 같은 구멍이고, 정규식 하나 차이다.
  final directive = RegExp('''^\\s*(import|export)\\s+['"]''');

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

    // 부수 조건. 파일이 하나도 없으면 아래 루프는 공허하게 통과한다 — 층이
    // 옮겨지거나 이름이 바뀌었을 때 이 테스트가 조용히 무의미해지는 경로다.
    expect(
      files,
      isNotEmpty,
      reason: '읽을 파일이 없다 — 이 테스트는 실패할 수 없는 상태가 되었다',
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
