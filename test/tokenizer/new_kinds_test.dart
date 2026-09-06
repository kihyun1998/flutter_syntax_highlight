import 'package:flutter_syntax_highlight/flutter_syntax_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/partition.dart';

/// `escape`와 `function` — [ADR-0001](../../docs/adr/0001-token-kinds-are-lexical-only.md)이
/// 여덟 개로 확정한 목록에서 새로 더해진 둘.
///
/// 둘은 성격이 다르다. `escape`는 스캐너가 문자열 안을 이미 지나가므로 경계를
/// 내보내기만 하면 되지만, `function`은 **없던 분기를 추가한다.** 이 결정 전체에서
/// 스캐너의 동작을 늘리는 유일한 항목이므로 회귀 위험이 여기 몰려 있다.
List<String> textsOf(String source, DartTokenKind kind) => tokenizeDart(source)
    .where((t) => t.kind == kind)
    .map((t) => t.text)
    .toList();

void main() {
  group('escape — 어휘로 확정된다', () {
    test('문자열이 string / escape / string으로 갈라진다', () {
      const source = r"const a = 'a\nb';";
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.escape), [r'\n']);
      expect(textsOf(source, DartTokenKind.string), ["'a", "b'"]);
    });

    test('escape된 따옴표는 문자열을 끝내지 않는다', () {
      const source = r"const a = 'it\'s';";
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.escape), [r"\'"]);
      expect(textsOf(source, DartTokenKind.string), ["'it", "s'"]);
    });

    test('연달아 붙은 escape는 하나로 합쳐진다', () {
      // 새 kind에도 기존 규칙이 그대로 적용된다 — 같은 kind의 인접한 구간은
      // 하나로 합쳐진다. 스타일이 같은 것을 스팬 셋으로 나눌 이유가 없다.
      const source = r"const a = '\n\t\\';";
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.escape), [r'\n\t\\']);
    });

    test('사이에 글자가 끼면 escape가 따로 나온다', () {
      // 합쳐지는 것이 "구분하지 못한다"는 뜻이 아님을 보인다.
      const source = r"const a = '\na\tb';";
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.escape), [r'\n', r'\t']);
      expect(textsOf(source, DartTokenKind.string), ["'", 'a', "b'"]);
    });

    test('보간 안의 원시 문자열에서도 escape가 나오지 않는다', () {
      // 보간 스캐너는 따옴표만 보고 문자열 스캐너에 넘긴다. `r` 접두사를 같이
      // 보지 않으면 보간 안의 원시 문자열이 escape를 처리하는 문자열로 스캔되어
      // 경계가 어긋나고, escape kind까지 잘못 붙는다.
      const source = "var a = '\${r'x\\n'}';";
      expectPartitions(source, expectClassified: false);
      expect(textsOf(source, DartTokenKind.escape), isEmpty);
    });

    test('원시 문자열에서는 escape가 나오지 않는다', () {
      // 참조 테스트가 이미 "백슬래시가 escape로 처리되면 닫는 따옴표를
      // 건너뛴다"를 지키고 있었다. `escape` kind가 생기면서 그 주장은
      // "여기서는 escape 토큰이 하나도 나오지 않는다"라는 뜻이 되어 더 날카로워진다.
      const source = r"const p = r'a\n';";
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.escape), isEmpty);
      expect(textsOf(source, DartTokenKind.string), [r"r'a\n'"]);
    });

    test('문자열 밖의 백슬래시는 escape가 아니다', () {
      const source = r'const a = 1 \ 2;';
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.escape), isEmpty);
    });

    test('삼중 따옴표 문자열 안에서도 갈라진다', () {
      const source = "const a = '''x\\ny''';";
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.escape), [r'\n']);
    });
  });

  group('function — 여는 괄호 바로 앞의 이름', () {
    test('호출 이름이 function이다', () {
      const source = 'foo(1);';
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.function), ['foo']);
    });

    test('홀로 있는 식별자는 plain이다', () {
      const source = 'foo + bar;';
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.function), isEmpty);
      // 뒤따르는 공백까지 한 구간으로 합쳐지므로 `'foo '`다.
      expect(textsOf(source, DartTokenKind.plain), ['foo ', ' bar']);
    });

    test('키워드는 괄호가 붙어도 keyword다', () {
      // 키워드 분기가 먼저 잡는다. 이것이 깨지면 `if`, `for`, `while`, `switch`,
      // `catch`가 전부 함수 이름으로 칠해진다 — 가장 눈에 띄는 회귀다.
      const source = 'if(x) return;';
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.function), isEmpty);
      expect(textsOf(source, DartTokenKind.keyword), contains('if'));
    });

    test('메서드 이름도 function이다', () {
      const source = '1.toString()';
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.function), ['toString']);
      // 참조 테스트가 지키던 것 — 점은 숫자의 일부가 아니다 — 도 그대로다.
      expect(tokenizeDart(source).first.text, '1');
    });

    test('생성자 호출도 어휘적으로는 같은 것이다', () {
      // 대문자로 시작한다고 타입으로 부르지 않는다. ADR-0001이 `type` vs
      // `variable`을 거부한 근거가 그것이다 — 공식 Dart 문법이 그 구분을
      // `[_$]*[A-Z]...`라는 관습 기반 추측으로 정한다. 여기서 `Foo`가
      // `function`인 것은 대문자와 무관하게 여는 괄호가 바로 앞이기 때문이다.
      const source = 'Foo(1)';
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.function), ['Foo']);
    });

    test('공백이 끼면 호출로 보지 않는다', () {
      // **바로 앞**이라는 규칙을 좁게 잡는다. 어휘적으로 확정되는 가장 단순한
      // 형태이고, `dart format`이 그 공백을 없애므로 실제 코드에서 거의 나오지
      // 않는다. 규칙을 넓히려면 이 테스트가 먼저 바뀌어야 한다.
      const source = 'foo (1);';
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.function), isEmpty);
    });

    test('점 뒤의 이름이라도 괄호가 없으면 plain이다', () {
      const source = 'a.b + c;';
      expectPartitions(source);
      expect(textsOf(source, DartTokenKind.function), isEmpty);
    });
  });
}
