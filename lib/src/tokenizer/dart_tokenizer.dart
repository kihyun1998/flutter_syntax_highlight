/// Dart를 위한 토크나이저 — kind만 정하고, 색은 절대 정하지 않는다.
///
/// **이 파일은 아무것도 import하지 않는다.** Flutter도, `dart:*`도. 그것이
/// 이음매다: 위젯이 kind가 *어떻게 보이는지*를 정하고, 여기서는 kind가
/// *무엇인지*를 정한다. 그래서 어려운 부분이 위젯도 pump도 없이 테스트할 수 있는
/// 순수 함수가 된다. `ColorScheme`을 아는 토크나이저는 렌더링해야만 테스트할 수
/// 있는 토크나이저다.
///
/// ## 색보다 중요한 성질
///
/// [tokenizeDart]는 **partition**을 돌려준다: 모든 토큰의 텍스트를 이어 붙이면
/// 입력이 바이트 단위로 재현된다. 하이라이터는 소비자의 바이트와 화면 사이에
/// 서는 물건이고, 화면에 보이는 것이 붙여넣을 수 있는 그 파일이라는 것이 이
/// 패키지의 주장이다.
///
/// partition은 **주장이 아니라 구조로** 성립한다. 스캐너는 소스에 대한 끝
/// 오프셋을 기록하고 토큰은 그 오프셋에서 잘라 내므로, 문자가 떨어지거나
/// 겹치거나 고쳐 쓰이는 경로 자체가 없다. 토큰의 텍스트는 언제나
/// `source.substring(previousEnd, thisEnd)`다.
///
/// 손으로 쓴 스캐너가 자연스럽게 도달하지만 이 모양이 구조적으로 배제하는, 붙여
/// 넣기를 망가뜨리는 두 가지: `\n`으로 쪼개 다시 잇기(CRLF를 조용히 정규화한다),
/// 그리고 키워드 매칭을 위해 소문자화한 형태를 내보내기.
///
/// **라이브러리는 특히 그렇다.** 줄바꿈 방식은 저장소가 아니라 체크아웃의
/// 성질이고, 임의의 소비자 소스를 받는 라이브러리는 그것을 정규화할 자격이 없다.
///
/// ## 주석은 통째로 소비되며, 그것이 정확성 논증이다
///
/// 2026-09-02 측정: 참조 corpus 열한 파일에서 홑따옴표 하나만 든 주석 줄이
/// **54개**였다(`somebody's`, `API's`). 주석이 편집되면 낡는 숫자라 날짜를 박아
/// 현재 사실이 아니라 측정치로 읽히게 둔다. 문자를 하나씩 검사하는 스캐너는 그
/// 54곳마다 문자열을 열어 줄 끝까지 달리고, 문자열 상태를 줄 너머로 들고 가면
/// 몇 문단 아래 다음 아포스트로피까지 달린다. 보간 처리가 존재하는 이유인 3곳에
/// 대해 54곳이고, 한눈에 망가져 보이게 만드는 쪽은 이쪽이다.
///
/// 그것을 막는 것은 [_lineCommentEnd]와 [_blockCommentEnd]가 주석 **전체**를 한
/// 단계에 소비해서, 주석 안의 어떤 문자도 분기에 걸리지 않는다는 사실이다.
/// **분기의 순서가 아니다.** 이 주석의 앞선 판본은 순서라고 주장했다: 한 문자는
/// `/`이거나 `'`이지 둘 다일 수 없으므로 두 갈래는 상호 배타적이고 순서를 바꾸는
/// 것은 아무 일도 하지 않는다. 그것은 측정으로 확인됐고 — 순서를 뒤집어도
/// 아무것도 변하지 않았다 — 그 대신 [_lineCommentEnd]를 불구로 만들어야 지키는
/// 테스트가 빨개졌다.
///
/// ## 참조 corpus가 실제로 담고 있던 것
///
/// 2026-09-02에 가정이 아니라 grep으로 확인: 원시 문자열 **없음**, 삼중 따옴표
/// 문자열 **없음**, 블록 주석 **없음**, escape된 따옴표 **없음**, 문자열 안의
/// `//` **없음**. 다섯 다 그럼에도 처리한다 — 각각 몇 줄이면 되고, 소비자의
/// 코드는 얌전할 의무가 없다. 그래서 이 다섯 중 무엇도 가드가 아니다.
///
/// 그 corpus가 그 날짜에 실제로 담고 있던 것은 서로 다른 세 파일에 있던 세 개의
/// 보간-안-중첩-문자열이다:
///
/// ```dart
/// final text = '${newValue ?? ''}'.trim();
/// : 'selectedRows: ${selected.join(', ')}',
/// '${term.value ? '✓' : '✗'} ${term.key}',
/// ```
///
/// 따옴표를 단순히 짝지으면 세 번째가 문자열 / `✓`는 코드 / ` : `는 문자열 /
/// `✗`는 코드로 그려진다 — 뒤집힌 채로, 그것도 그 조각이 보여주려는 바로 그
/// 두 글자에서. 그래서 [_stringEnd]와 [_interpolationEnd]는 **상호 재귀**다:
/// 보간은 중첩 문자열을 이해하는 중괄호 카운터로 스캔된다. 리터럴 하나가 보간을
/// 포함해 토큰 하나다.
library;

/// 한 구간의 문자들이 무엇인지 — 다르게 그리기 위한 목적에 한해서.
///
/// **의도적으로 거칠다.** 더 미세한 것 — 타입과 변수, 메서드 호출과 필드를
/// 가르는 것 — 은 넣지 않는다. 어휘만으로 확정되지 않고 관습에 기댄 **추측**이기
/// 때문이며, 이름이 *무엇을 뜻하는지*에 대한 반쯤 맞는 답은 답이 없는 것보다
/// 나쁘다. 읽는 사람이 그것을 믿어 버리기 때문이다.
///
/// 무엇을 넣고 무엇을 거부했는지와 그 근거는
/// `docs/adr/0001-token-kinds-are-lexical-only.md`에 있다.
enum DartTokenKind {
  /// 식별자, 공백, 그리고 분류되지 않은 모든 것.
  plain,

  /// `//`부터 줄 끝까지, 그리고 중첩 쌍을 포함한 `/* */`.
  comment,

  /// 예약어, 내장 식별자, 또는 문맥 키워드.
  keyword,

  /// 문자열 리터럴 전체. 보간을 포함한다.
  ///
  /// **현재 판본의 동작이며, 바뀔 예정이다.** 보간 안을 재귀적으로 토큰화하기로
  /// 결정되어 있고, 그러면 `'\${a}'`는 토큰 하나가 아니라 여러 토큰이 된다.
  /// `docs/adr/0001-token-kinds-are-lexical-only.md`의 Consequences가 이 문장을
  /// 이름으로 짚어 두었다.
  string,

  /// 정수, 실수, 또는 16진 리터럴.
  number,

  /// 괄호, 연산자, 구분자.
  punctuation,
}

/// 소스 텍스트의 한 구간과, 그것이 무엇인지.
class DartToken {
  const DartToken(this.text, this.kind);

  /// 소스에서 잘라 낸 정확한 문자들. 다시 쓰이는 일은 없다.
  final String text;

  final DartTokenKind kind;

  @override
  String toString() => 'DartToken(${kind.name}, ${text.length} chars)';
}

/// [source]를 kind가 붙은 구간들의 **partition**으로 쪼갠다.
///
/// 같은 kind의 인접한 구간은 하나로 합쳐지며, 이는 미관 문제가 아니다: 위젯 층은
/// 토큰 하나를 `TextSpan` 하나로 만들고, `SelectableText`는 스팬 트리가 같지
/// 않다고 비교될 때마다 컨트롤러를 다시 만들며, `TextSpan`의 동등성은 깊은
/// 순회다. 괄호마다 스팬을 내보내면 눈에 보이는 이득 없이 리빌드마다 수천 번의
/// `TextStyle` 비교를 얹게 된다.
List<DartToken> tokenizeDart(String source) {
  // 진행하면서 토큰 목록을 만드는 대신 두 개의 평행 리스트를 쓴다: 스캐너는
  // 끝 오프셋을 덧붙이기만 하므로, "토큰이 소스를 빈틈없이 덮는다"가 분기마다
  // 기억해야 할 것이 아니라 루프의 성질이 된다.
  final kinds = <DartTokenKind>[];
  final ends = <int>[];

  var i = 0;
  while (i < source.length) {
    final c = source.codeUnitAt(i);
    final DartTokenKind kind;

    if (c == _slash && i + 1 < source.length) {
      final next = source.codeUnitAt(i + 1);
      if (next == _slash) {
        kind = DartTokenKind.comment;
        i = _lineCommentEnd(source, i);
      } else if (next == _star) {
        kind = DartTokenKind.comment;
        i = _blockCommentEnd(source, i);
      } else {
        kind = DartTokenKind.punctuation;
        i++;
      }
    } else if (c == _singleQuote || c == _doubleQuote) {
      kind = DartTokenKind.string;
      i = _stringEnd(source, i, raw: false);
    } else if (_isIdentifierStart(c)) {
      final end = _identifierEnd(source, i);
      // `r'...'` — `r`가 접두사인 것은 식별자가 이어질 수 없었던 자리뿐이고,
      // 그것은 정확히 식별자 스캔이 따옴표에서 멈춘 경우다.
      if (end == i + 1 &&
          c == _lowerR &&
          end < source.length &&
          (source.codeUnitAt(end) == _singleQuote ||
              source.codeUnitAt(end) == _doubleQuote)) {
        kind = DartTokenKind.string;
        i = _stringEnd(source, end, raw: true);
      } else {
        kind = _keywords.contains(source.substring(i, end))
            ? DartTokenKind.keyword
            : DartTokenKind.plain;
        i = end;
      }
    } else if (_isDigit(c)) {
      kind = DartTokenKind.number;
      i = _numberEnd(source, i);
    } else if (_isPunctuation(c)) {
      kind = DartTokenKind.punctuation;
      i++;
    } else {
      // 공백, 그리고 위 분류 밖의 모든 것 — 대리 쌍의 두 반쪽도 포함한다.
      // 그것들은 `plain` 구간 두 개로 들어와 아래에서 토큰 하나로 다시 합쳐진다.
      kind = DartTokenKind.plain;
      i++;
    }

    kinds.add(kind);
    ends.add(i);
  }

  final tokens = <DartToken>[];
  var runStart = 0;
  for (var n = 0; n < ends.length; n++) {
    if (n == ends.length - 1 || kinds[n + 1] != kinds[n]) {
      tokens.add(DartToken(source.substring(runStart, ends[n]), kinds[n]));
      runStart = ends[n];
    }
  }
  return tokens;
}

/// `//` 주석의 끝. 개행 자체는 주석에 **포함되지 않는다**.
///
/// 체크아웃이 CRLF를 만든 곳에서는 뒤따르는 `\r`가 주석에 포함된다. 의도적이다 —
/// 줄이 어디서 끝나는지에 대한 규칙을 새로 만드는 대신 캐리지 리턴을 토큰 안에
/// 두는 것이고, 어느 쪽이든 partition이 붙여넣기를 지킨다.
///
/// **줄바꿈 방식은 저장소가 아니라 체크아웃의 성질이다.** `.gitattributes`가
/// `* text=auto`이면 Windows 클론은 CRLF를, Linux 클론은 LF를 만든다. 그래서
/// 파일 픽스처로 CRLF를 시험하는 테스트는 코드가 아니라 그 머신을 시험하게 된다 —
/// escape 리터럴로 만든 CRLF만이 체크아웃에 면역이다.
int _lineCommentEnd(String source, int i) {
  var j = i;
  while (j < source.length && source.codeUnitAt(j) != _newline) {
    j++;
  }
  return j;
}

/// `/* */` 주석의 끝. 중첩 쌍을 센다.
///
/// Dart는 C와 달리 블록 주석을 중첩하므로 `/* /* */ */`는 주석 하나이고, 첫
/// `*/`에서 멈추는 스캐너는 파일의 꼬리를 잘못 칠한 채로 남긴다. 2026-09-02에
/// 측정한 참조 corpus에는 하나도 없었다. 그래도 처리한다 — 네 줄이면 되고,
/// 소비자의 코드는 얌전할 의무가 없다.
int _blockCommentEnd(String source, int i) {
  var j = i + 2;
  var depth = 1;
  while (j + 1 < source.length) {
    if (source.codeUnitAt(j) == _slash && source.codeUnitAt(j + 1) == _star) {
      depth++;
      j += 2;
    } else if (source.codeUnitAt(j) == _star &&
        source.codeUnitAt(j + 1) == _slash) {
      depth--;
      j += 2;
      if (depth == 0) return j;
    } else {
      j++;
    }
  }
  return source.length;
}

/// [i]에서 시작하는 문자열 리터럴의 끝. 보간을 포함한다.
///
/// [raw]는 escape 처리를 끈다: `r'a\'`에서 백슬래시는 그냥 한 문자이므로,
/// 두 글자를 소비하면 닫는 따옴표를 지나쳐 버린다.
///
/// 닫히지 않은 홑따옴표 문자열은 파일 끝까지 달리지 않고 개행에서 멈춘다. 이
/// 스캐너가 이해하지 못하는 구문의 피해를 파일의 나머지가 아니라 그것이 있는
/// 줄에 가둔다.
int _stringEnd(String source, int i, {required bool raw}) {
  final quote = source.codeUnitAt(i);
  final triple = i + 2 < source.length &&
      source.codeUnitAt(i + 1) == quote &&
      source.codeUnitAt(i + 2) == quote;
  var j = i + (triple ? 3 : 1);

  while (j < source.length) {
    final c = source.codeUnitAt(j);

    if (!raw && c == _backslash) {
      j += 2;
      continue;
    }
    if (!raw &&
        c == _dollar &&
        j + 1 < source.length &&
        source.codeUnitAt(j + 1) == _openBrace) {
      // 개행 경계는 아래로 넘겨야 한다. 그러지 않으면 `${`가 그 경계에 뚫린
      // 구멍이 된다: 닫히지 않은 보간이 파일 끝까지 달려 나머지 전부를 문자열로
      // 칠하는데, 그것이 바로 아래의 경계가 막으려는 것이다. 삼중 따옴표
      // 리터럴만은 진짜로 여러 줄에 걸칠 수 있으므로 예외다.
      j = _interpolationEnd(source, j + 2, stopAtNewline: !triple);
      continue;
    }
    if (c == quote) {
      if (!triple) return j + 1;
      if (j + 2 < source.length &&
          source.codeUnitAt(j + 1) == quote &&
          source.codeUnitAt(j + 2) == quote) {
        return j + 3;
      }
    }
    if (!triple && c == _newline) return j;
    j++;
  }
  return source.length;
}

/// `${...}` 보간의 끝. [j]는 여는 중괄호 바로 다음이다.
///
/// [_stringEnd]와 상호 재귀이며, 그것이 요점이다: 중괄호 카운터만으로는
/// `'${selected.join(', ')}'`를 틀린다. 안쪽의 `'`가 바깥 리터럴을 끝내 버리기
/// 때문이다. 중첩된 따옴표를 문자열 스캐너에 되돌려 주는 것이, 2026-09-02에
/// 측정한 세 개의 실제 사례를 통째로 나오게 하는 장치다.
int _interpolationEnd(String source, int j, {required bool stopAtNewline}) {
  var depth = 1;
  while (j < source.length) {
    final c = source.codeUnitAt(j);
    if (c == _singleQuote || c == _doubleQuote) {
      j = _stringEnd(source, j, raw: false);
      continue;
    }
    // 감싸고 있는 리터럴에서 물려받는다. 이것이 없으면 `'${oops`가
    // `source.length`를 돌려주고 [_stringEnd]의 개행 경계에는 영영 닿지 않는다 —
    // 무언가를 가두는 것이 존재 이유인 분기를 통과하는, 가둬지지 않은 질주다.
    if (stopAtNewline && c == _newline) return j;
    if (c == _openBrace) {
      depth++;
    } else if (c == _closeBrace) {
      depth--;
      if (depth == 0) return j + 1;
    }
    j++;
  }
  return source.length;
}

/// 숫자 리터럴의 끝. 보수적으로 잡는다: 과하게 소비해도 문자 하나를 잘못
/// 칠할 뿐이고, partition은 어느 쪽이든 영향받지 않는다.
int _numberEnd(String source, int i) {
  var j = i;
  if (source.codeUnitAt(j) == _zero && j + 1 < source.length) {
    final next = source.codeUnitAt(j + 1);
    if (next == _lowerX || next == _upperX) {
      j += 2;
      while (j < source.length && _isHexDigit(source.codeUnitAt(j))) {
        j++;
      }
      return j;
    }
  }
  while (j < source.length && _isDigit(source.codeUnitAt(j))) {
    j++;
  }
  // `.`이 숫자의 일부인 것은 뒤에 숫자가 올 때뿐이므로, `1.toString()`은
  // 메서드 이름을 리터럴 밖에 둔다.
  if (j + 1 < source.length &&
      source.codeUnitAt(j) == _dot &&
      _isDigit(source.codeUnitAt(j + 1))) {
    j++;
    while (j < source.length && _isDigit(source.codeUnitAt(j))) {
      j++;
    }
  }
  if (j < source.length &&
      (source.codeUnitAt(j) == _lowerE || source.codeUnitAt(j) == _upperE)) {
    var k = j + 1;
    if (k < source.length &&
        (source.codeUnitAt(k) == _plus || source.codeUnitAt(k) == _minus)) {
      k++;
    }
    if (k < source.length && _isDigit(source.codeUnitAt(k))) {
      j = k;
      while (j < source.length && _isDigit(source.codeUnitAt(j))) {
        j++;
      }
    }
  }
  return j;
}

int _identifierEnd(String source, int i) {
  var j = i;
  while (j < source.length && _isIdentifierPart(source.codeUnitAt(j))) {
    j++;
  }
  return j;
}

bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

bool _isHexDigit(int c) =>
    _isDigit(c) ||
    (c >= 0x41 && c <= 0x46) ||
    (c >= 0x61 && c <= 0x66) ||
    c == _underscore;

bool _isIdentifierStart(int c) =>
    (c >= 0x41 && c <= 0x5A) ||
    (c >= 0x61 && c <= 0x7A) ||
    c == _underscore ||
    c == _dollar;

bool _isIdentifierPart(int c) => _isIdentifierStart(c) || _isDigit(c);

/// ASCII 구두점에서, 스캔의 앞 단계가 이미 처리한 문자들을 뺀 것.
bool _isPunctuation(int c) =>
    (c >= 0x21 && c <= 0x2F) ||
    (c >= 0x3A && c <= 0x40) ||
    (c >= 0x5B && c <= 0x60) ||
    (c >= 0x7B && c <= 0x7E);

const _newline = 0x0A;
const _dollar = 0x24;
const _singleQuote = 0x27;
const _plus = 0x2B;
const _minus = 0x2D;
const _dot = 0x2E;
const _slash = 0x2F;
const _zero = 0x30;
const _star = 0x2A;
const _doubleQuote = 0x22;
const _upperE = 0x45;
const _upperX = 0x58;
const _backslash = 0x5C;
const _underscore = 0x5F;
const _lowerE = 0x65;
const _lowerR = 0x72;
const _lowerX = 0x78;
const _openBrace = 0x7B;
const _closeBrace = 0x7D;

/// Dart의 예약어, 내장 식별자, 그리고 표시되기를 기대할 만한 문맥 키워드.
///
/// 여기 있는 단어는 어디에 나타나든 스타일이 붙는다. `show`라는 변수나 `base`라는
/// 필드도 마찬가지다. 그것이 스캐너의 감수하는 비용이다: 대안은 이름이 무엇을
/// 가리키는지 아는 것이고, 그것은 파서다.
const _keywords = <String>{
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'base',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'Function',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'on',
  'operator',
  'part',
  'required',
  'rethrow',
  'return',
  'sealed',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'when',
  'while',
  'with',
  'yield',
};
