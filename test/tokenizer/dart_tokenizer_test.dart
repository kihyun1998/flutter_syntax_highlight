import 'package:flutter_syntax_highlight/flutter_syntax_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

// 이 스위트의 하중을 받는 주장은 "색이 맞는가"가 아니라 "무엇이든 바뀌었는가"다.
// 하이라이터는 소비자의 바이트와 화면 사이에 서는 물건이고, 화면에 보이는 것이
// 붙여넣을 수 있는 그 파일이라는 것이 이 패키지의 주장이기 때문이다.
//
// 아래의 보간 세 사례는 참조 corpus에서 그대로 옮겨 왔다. 2026-09-02 측정 기준
// 그 corpus 2603줄에서 어휘적으로 어려웠던 유일한 구문이며, 원본이 나중에
// 고쳐 쓰이더라도 스캐너가 그것들에 대해 고정되도록 여기 재현한다.

/// 모든 문자가, 순서대로, 정확히 한 번.
///
/// 붙여넣기 계약 그 자체다. 여러 곳에서 손으로 반복하면 한 곳이 어긋나므로
/// matcher로 한 번만 쓴다.
void expectPartitions(List<DartToken> tokens, String source, {String? reason}) {
  expect(tokens.map((t) => t.text).join(), source, reason: reason);
}

void main() {
  group('partition — 붙여넣기 계약이 기대는 성질', () {
    test('그리고 이 체크아웃이 오늘 만들어내지 않을 줄바꿈 방식에 대해서도', () {
      // 여러 줄 리터럴이 아니라 escape다: 이 파일도 체크아웃의 줄바꿈 정규화를
      // 똑같이 받으므로, 리터럴로 쓰면 의도한 것이 아니라 체크아웃이 만들어낸
      // 것을 주장하게 된다. escape만이 체크아웃에 면역이다.
      const awkward = 'class A {\r\n'
          '  // a comment with CRLF\r\n'
          '\r'
          '\tfinal x = 1;\n'
          '  // no trailing newline';

      final tokens = tokenizeDart(awkward);
      expectPartitions(tokens, awkward);

      // 부수 조건. partition만으로는 토큰 하나가 전부를 덮어도 만족되므로,
      // 스캐너가 실제로 분류했다는 것을 여기서 확인한다.
      expect(tokens.map((t) => t.kind).toSet().length, greaterThan(1));
    });

    test('그리고 빈 파일에 대해서도', () {
      expect(tokenizeDart(''), isEmpty);
    });
  });

  group('주석은 통째로 소비된다', () {
    // 2026-09-02 측정: 참조 corpus 열한 파일 중 열 파일에서 홑따옴표 하나만 든
    // 주석 줄이 54개였고, corpus에서 가장 흔한 위험이었다.
    //
    // 그것을 막는 것은 주석 전체가 한 단계에 소비되어 주석 안의 어떤 문자도
    // 분기에 걸리지 않는다는 사실이지, 분기의 순서가 **아니다**. 이 주석의 앞선
    // 판본은 순서라고 주장했다. 한 문자는 `/`이거나 `'`이지 둘 다일 수 없으므로
    // 두 갈래는 상호 배타적이고 순서를 바꾸는 것은 아무 일도 하지 않는다.
    // 측정으로 확인했고, 이 둘을 실제로 빨갛게 만드는 변형은 줄 주석 스캐너를
    // 불구로 만드는 것이었다.
    test('주석 안의 아포스트로피는 문자열을 열지 않는다', () {
      const source = "// somebody's name\nfinal x = 1;\n";
      final tokens = tokenizeDart(source);

      expectPartitions(tokens, source);
      expect(tokens.first.kind, DartTokenKind.comment);
      expect(tokens.first.text, "// somebody's name");
      expect(
        tokens.any((t) => t.kind == DartTokenKind.string),
        isFalse,
        reason: '아포스트로피가 따옴표로 취급됐다',
      );
      // 그리고 그 뒤의 코드는 여전히 코드다.
      expect(
        tokens.any(
          (t) => t.kind == DartTokenKind.keyword && t.text.contains('final'),
        ),
        isTrue,
      );
    });

    test('문서 주석 안의 따옴표는 다음 줄로 새지 않는다', () {
      const source = "/// the API's shape\nconst a = 'x';\n";
      final tokens = tokenizeDart(source);

      expectPartitions(tokens, source);
      final strings =
          tokens.where((t) => t.kind == DartTokenKind.string).toList();
      expect(strings, hasLength(1));
      expect(strings.single.text, "'x'");
    });
  });

  group('보간 — 참조 corpus의 어려운 세 사례', () {
    // 그대로 옮겼다. 따옴표를 단순히 짝지으면 세 번째가 문자열 / ✓는 코드 /
    // ' : '는 문자열 / ✗는 코드로 그려진다 — 뒤집힌 채로, 그것도 그 조각이
    // 보여주려는 바로 그 두 글자에서.
    //
    // 이 네 테스트와, 아래 group의 `닫히지 않은 보간` 하나까지 다섯은 지금
    // 스캐너가 하는 일을 기록한다. 보간 안을 재귀적으로
    // 토큰화하기로 한 결정이 반영되면 "리터럴 전체가 토큰 하나"라는 주장은
    // 거짓이 되고, 그때 전체 토큰 스트림 비교로 다시 쓰인다.
    test('보간 안의 중첩된 빈 문자열', () {
      const source = "final text = '\${newValue ?? ''}'.trim();";
      final tokens = tokenizeDart(source);

      expectPartitions(tokens, source);
      final strings =
          tokens.where((t) => t.kind == DartTokenKind.string).toList();
      expect(
        strings,
        hasLength(1),
        reason: '리터럴이 쪼개졌다 — 보간이 그것을 일찍 끝냈다',
      );
      expect(strings.single.text, "'\${newValue ?? ''}'");
    });

    test('join 안에서 쉼표를 든 중첩 문자열', () {
      const source = "': \${selected.join(', ')}',";
      final tokens = tokenizeDart(source);

      expectPartitions(tokens, source);
      final strings =
          tokens.where((t) => t.kind == DartTokenKind.string).toList();
      expect(strings, hasLength(1));
      expect(strings.single.text, "': \${selected.join(', ')}'");
    });

    test('보간 둘, 그중 하나는 문자열 둘의 삼항을 품는다', () {
      const source = "'\${term.value ? '✓' : '✗'} \${term.key}',";
      final tokens = tokenizeDart(source);

      expectPartitions(tokens, source);
      final strings =
          tokens.where((t) => t.kind == DartTokenKind.string).toList();
      expect(
        strings,
        hasLength(1),
        reason: '✓/✗ 삼항이 리터럴을 조각냈다',
      );
      expect(strings.single.text, "'\${term.value ? '✓' : '✗'} \${term.key}'");
    });

    test('그리고 보간된 문자열 안의 중괄호는 닫는 중괄호가 아니다', () {
      const source = "'\${map['{']}'";
      final tokens = tokenizeDart(source);

      expectPartitions(tokens, source);
      expect(tokens.single.kind, DartTokenKind.string);
    });
  });

  group('드물지만 망가지면 안 되는 구문', () {
    // 2026-09-02에 가정이 아니라 grep으로 확인한 결과, 아래 중 무엇도 참조
    // corpus에 없었다. 그래도 처리한다 — 각각 몇 줄이면 되고, 소비자의 코드는
    // 얌전할 의무가 없다.
    test('원시 문자열은 escape를 처리하지 않는다', () {
      const source = r"final p = r'a\' + 1;";
      final tokens = tokenizeDart(source);

      expectPartitions(tokens, source);
      final strings =
          tokens.where((t) => t.kind == DartTokenKind.string).toList();
      expect(
        strings.single.text,
        r"r'a\'",
        reason: '백슬래시가 escape로 처리되어 닫는 따옴표를 건너뛰었고, '
            '줄의 나머지가 문자열 색이 되었다',
      );
    });

    test('삼중 따옴표 문자열은 여러 줄에 걸친다', () {
      const source = "const a = '''\nline\n''';\n";
      final tokens = tokenizeDart(source);

      expectPartitions(tokens, source);
      final strings =
          tokens.where((t) => t.kind == DartTokenKind.string).toList();
      expect(strings.single.text, "'''\nline\n'''");
    });

    test('블록 주석은 Dart가 그러하고 C가 그러하지 않듯 중첩된다', () {
      const source = 'a /* outer /* inner */ still outer */ b';
      final tokens = tokenizeDart(source);

      expectPartitions(tokens, source);
      final comments =
          tokens.where((t) => t.kind == DartTokenKind.comment).toList();
      expect(
        comments.single.text,
        '/* outer /* inner */ still outer */',
        reason: '첫 */에서 멈춰서 꼬리가 잘못 칠해졌다',
      );
      // 부수 조건: `b`는 여전히 주석 밖이다.
      expect(tokens.last.text.trim(), 'b');
    });

    test('닫히지 않은 문자열은 파일 끝이 아니라 개행에서 멈춘다', () {
      // 이 스캐너가 이해하지 못하는 구문의 피해를 파일의 나머지가 아니라
      // 그것이 있는 줄에 가둔다.
      const source = "final a = 'oops\nfinal b = 2;\n";
      final tokens = tokenizeDart(source);

      expectPartitions(tokens, source);
      final strings =
          tokens.where((t) => t.kind == DartTokenKind.string).toList();
      expect(strings.single.text, "'oops");
      expect(
        tokens.any(
          (t) => t.kind == DartTokenKind.keyword && t.text.contains('final'),
        ),
        isTrue,
        reason: '둘째 줄이 닫히지 않은 문자열에 삼켜졌다',
      );
    });

    test('그리고 닫히지 않은 보간도 거기서 멈춘다', () {
      // 위의 경계는 조건 없이 진술되어 있었고 구멍이 있었다: `${`가 스캐닝을
      // 보간 스캐너에 넘겼는데 그쪽에는 자기 개행 경계가 없어 파일 끝을
      // 돌려주었다. 두 글자가 보장을 빠져나가기에 충분했고, 위의 테스트는
      // `'oops`에 `$`가 없어서 그것을 볼 수 없었다.
      const source = "final a = '\${oops\nfinal b = 2;\n";
      final tokens = tokenizeDart(source);

      expectPartitions(tokens, source);
      final strings =
          tokens.where((t) => t.kind == DartTokenKind.string).toList();
      expect(strings.single.text, "'\${oops");
      expect(
        tokens.where((t) => t.kind == DartTokenKind.keyword).length,
        2,
        reason: '파일의 나머지가 문자열 하나로 칠해졌다',
      );
    });
  });

  group('분류', () {
    test('키워드, 숫자, 구두점은 자기 자신으로 나온다', () {
      const source = 'const x = 0xFF + 1.5e3;';
      final tokens = tokenizeDart(source);

      expectPartitions(tokens, source);
      expect(
        tokens.firstWhere((t) => t.kind == DartTokenKind.keyword).text,
        'const',
      );
      final numbers = tokens
          .where((t) => t.kind == DartTokenKind.number)
          .map((t) => t.text)
          .toList();
      expect(numbers, ['0xFF', '1.5e3']);
    });

    test('정수 뒤의 점은 리터럴의 일부가 아니다', () {
      const source = '1.toString()';
      final tokens = tokenizeDart(source);

      expectPartitions(tokens, source);
      expect(tokens.first.kind, DartTokenKind.number);
      expect(
        tokens.first.text,
        '1',
        reason: '메서드 이름이 숫자 리터럴에 먹혔다',
      );
    });

    test('같은 kind의 인접한 run은 하나로 합쳐진다', () {
      // 미관 문제가 아니다. 위젯 층은 토큰 하나를 `TextSpan` 하나로 만들고,
      // `SelectableText`는 트리가 같지 않다고 비교될 때마다 컨트롤러를 다시
      // 만드는데 `TextSpan`의 동등성은 깊은 순회다. 괄호마다 스팬을 만들면
      // 눈에 보이는 이득 없이 리빌드마다 수천 번의 `TextStyle` 비교가 붙는다.
      final tokens = tokenizeDart('((( )))');

      expectPartitions(tokens, '((( )))');
      expect(
        tokens,
        hasLength(3),
        reason: '구두점 / 공백 / 구두점이지 일곱 개의 토큰이 아니다',
      );
    });

    test('ASCII가 아닌 글리프는 토큰 하나로 살아남는다', () {
      // 스캐너가 코드 단위 단위로 전진하므로, 이것은 대리 쌍이 두 스팬으로
      // 쪼개지지 않고 다시 붙는다는 주장이다.
      const source = "// an em dash — and a check ✓\n";
      final tokens = tokenizeDart(source);

      expectPartitions(tokens, source);
      expect(tokens.first.text, contains('—'));
      expect(tokens.first.text, contains('✓'));
    });
  });
}
