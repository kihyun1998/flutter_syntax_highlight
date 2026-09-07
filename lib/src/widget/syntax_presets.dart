part of 'syntax_palette.dart';

// 이름 붙은 프리셋의 **데이터**만 여기 산다. 선언은 [SyntaxPalette] 안에 있고
// 여기 상수를 가리킨다 — 호출부는 `SyntaxPalette.solarizedDark`다.
//
// 파일을 나눈 이유는 변경 축이 다르기 때문이다. [SyntaxPalette] 자신은 이 패키지의
// 이음매이고 kind가 늘 때 바뀐다. 아래 값들은 제3자 테마에서 온 데이터이고
// `NOTICES`와 함께 움직인다. 한 파일에 두면 두 가지 이유로 같은 파일이 바뀐다.

const _italic = FontStyle.italic;
// ───────────────────────────────────────────────────────────────────────
// 이름 붙은 프리셋
//
// **재현이 아니라 발췌다.** 원본 테마들은 TextMate scope 수십~수백 개에 색을
// 매기고 이 패키지의 kind는 여덟이다. 각 프리셋은 원본이 그 여덟에 해당하는
// scope에 준 색을 뽑아 온 것이라, 원본 에디터와 똑같이 보이지 않는다.
//
// 값의 출처는 파일과 커밋까지 `NOTICES`에 적혀 있다. 같은 테마도 판본마다
// 라이선스가 다르므로, 그 기록이 없으면 나중에 그 판정을 다시 할 수 없다.
//
// 기본값은 이것들이 **아니다.** [SyntaxPalette.fromColorScheme]만이 라이트와
// 다크 양쪽에서 설정 없이 맞는다. 실명 프리셋은 정의상 하드코딩된 팔레트라
// 반대 밝기에서 깨지고, 그래서 원본에 짝이 있으면 짝으로 싣는다.
// ───────────────────────────────────────────────────────────────────────

/// Solarized Dark에서 **발췌**한 색. 재현이 아니다.
const _solarizedDark = SyntaxPalette(
  background: Color(0xFF002B36),
  plain: TextStyle(color: Color(0xFF839496)),
  punctuation: TextStyle(color: Color(0xFF839496)),
  comment: TextStyle(color: Color(0xFF586E75), fontStyle: _italic),
  keyword: TextStyle(color: Color(0xFF859900)),
  string: TextStyle(color: Color(0xFF2AA198)),
  number: TextStyle(color: Color(0xFFD33682)),
  escape: TextStyle(color: Color(0xFFCB4B16)),
  function: TextStyle(color: Color(0xFF268BD2)),
);

/// Solarized Light에서 **발췌**한 색. 재현이 아니다.
const _solarizedLight = SyntaxPalette(
  background: Color(0xFFFDF6E3),
  plain: TextStyle(color: Color(0xFF657B83)),
  punctuation: TextStyle(color: Color(0xFF657B83)),
  comment: TextStyle(color: Color(0xFF93A1A1), fontStyle: _italic),
  keyword: TextStyle(color: Color(0xFF859900)),
  string: TextStyle(color: Color(0xFF2AA198)),
  number: TextStyle(color: Color(0xFFD33682)),
  escape: TextStyle(color: Color(0xFFCB4B16)),
  function: TextStyle(color: Color(0xFF268BD2)),
);

/// One Dark에서 **발췌**한 색. 재현이 아니다.
///
/// 이름이 `atomOneDark`가 아닌 것은 `ATOM`이 GitHub의 상표이기 때문이다. 값은
/// `atom/one-dark-syntax`에서 왔고 그 파일의 라이선스는 MIT다.
const _oneDark = SyntaxPalette(
  background: Color(0xFF282C34),
  plain: TextStyle(color: Color(0xFFABB2BF)),
  punctuation: TextStyle(color: Color(0xFFABB2BF)),
  comment: TextStyle(color: Color(0xFF5C6370), fontStyle: _italic),
  keyword: TextStyle(color: Color(0xFFC678DD)),
  string: TextStyle(color: Color(0xFF98C379)),
  number: TextStyle(color: Color(0xFFD19A66)),
  escape: TextStyle(color: Color(0xFF56B6C2)),
  function: TextStyle(color: Color(0xFF61AFEF)),
);

/// One Light에서 **발췌**한 색. 재현이 아니다.
const _oneLight = SyntaxPalette(
  background: Color(0xFFFAFAFA),
  plain: TextStyle(color: Color(0xFF383A42)),
  punctuation: TextStyle(color: Color(0xFF383A42)),
  comment: TextStyle(color: Color(0xFFA0A1A7), fontStyle: _italic),
  keyword: TextStyle(color: Color(0xFFA626A4)),
  string: TextStyle(color: Color(0xFF50A14F)),
  number: TextStyle(color: Color(0xFF986801)),
  escape: TextStyle(color: Color(0xFF0184BC)),
  function: TextStyle(color: Color(0xFF4078F2)),
);

/// Monokai에서 **발췌**한 색. 재현이 아니다.
///
/// 주석이 기울지 않는 유일한 프리셋이다 — 원본이 그렇다. `escape`가 `number`와
/// 같은 색인 것도 원본 그대로다: 이 테마에는 `constant.character.escape` 전용
/// 규칙이 없어 상위 `constant` 규칙에 흡수된다.
const _monokai = SyntaxPalette(
  background: Color(0xFF272822),
  plain: TextStyle(color: Color(0xFFF8F8F2)),
  punctuation: TextStyle(color: Color(0xFFF8F8F2)),
  comment: TextStyle(color: Color(0xFF88846F)),
  keyword: TextStyle(color: Color(0xFFF92672)),
  string: TextStyle(color: Color(0xFFE6DB74)),
  number: TextStyle(color: Color(0xFFAE81FF)),
  escape: TextStyle(color: Color(0xFFAE81FF)),
  function: TextStyle(color: Color(0xFFA6E22E)),
);

/// Gruvbox Dark에서 **발췌**한 색. 재현이 아니다.
///
/// 값이 Vim 정본이 아니라 MIT 이식본에서 왔다 — `morhetz/gruvbox`에는 LICENSE
/// 파일이 없고 저작권자 문장이 존재하지 않아 `NOTICES`에 옮겨 적을 원문이
/// 없다. 대가로 두 슬롯의 충실도를 내줬다: 이식본은 `escape`를 `constant`
/// 규칙에 흡수하고 함수를 노랑으로 칠하는데, 정본은 escape에 고유한 주황을
/// 주고 함수를 초록+굵게 한다. **두 값 집합을 섞지 않았다** — 섞으면 어디에도
/// 존재하지 않는 팔레트가 된다.
const _gruvboxDark = SyntaxPalette(
  background: Color(0xFF282828),
  plain: TextStyle(color: Color(0xFFEBDBB2)),
  punctuation: TextStyle(color: Color(0xFFEBDBB2)),
  comment: TextStyle(color: Color(0xFF928374), fontStyle: _italic),
  keyword: TextStyle(color: Color(0xFFFB4934)),
  string: TextStyle(color: Color(0xFFB8BB26)),
  number: TextStyle(color: Color(0xFFD3869B)),
  escape: TextStyle(color: Color(0xFFD3869B)),
  function: TextStyle(color: Color(0xFFFABD2F)),
);

/// Gruvbox Light에서 **발췌**한 색. 재현이 아니다. [gruvboxDark] 참조.
const _gruvboxLight = SyntaxPalette(
  background: Color(0xFFFBF1C7),
  plain: TextStyle(color: Color(0xFF3C3836)),
  punctuation: TextStyle(color: Color(0xFF3C3836)),
  comment: TextStyle(color: Color(0xFF928374), fontStyle: _italic),
  keyword: TextStyle(color: Color(0xFF9D0006)),
  string: TextStyle(color: Color(0xFF79740E)),
  number: TextStyle(color: Color(0xFF8F3F71)),
  escape: TextStyle(color: Color(0xFF8F3F71)),
  function: TextStyle(color: Color(0xFFB57614)),
);

/// Tokyo Night에서 **발췌**한 색. 재현이 아니다.
const _tokyoNight = SyntaxPalette(
  background: Color(0xFF1A1B26),
  plain: TextStyle(color: Color(0xFFA9B1D6)),
  punctuation: TextStyle(color: Color(0xFFA9B1D6)),
  comment: TextStyle(color: Color(0xFF51597D), fontStyle: _italic),
  keyword: TextStyle(color: Color(0xFFBB9AF7)),
  string: TextStyle(color: Color(0xFF9ECE6A)),
  number: TextStyle(color: Color(0xFFFF9E64)),
  escape: TextStyle(color: Color(0xFF89DDFF)),
  function: TextStyle(color: Color(0xFF7AA2F7)),
);

/// Tokyo Night Light에서 **발췌**한 색. 재현이 아니다.
///
/// 이 프리셋의 `escape`(`#363C4D`)는 본문(`#343B59`)과 육안으로 거의 구분되지
/// 않는다. **원본이 그렇게 정의했고, 추측으로 고칠 근거가 없어 그대로 싣는다.**
const _tokyoNightLight = SyntaxPalette(
  background: Color(0xFFE6E7ED),
  plain: TextStyle(color: Color(0xFF343B59)),
  punctuation: TextStyle(color: Color(0xFF343B59)),
  comment: TextStyle(color: Color(0xFF888B94), fontStyle: _italic),
  keyword: TextStyle(color: Color(0xFF65359D)),
  string: TextStyle(color: Color(0xFF385F0D)),
  number: TextStyle(color: Color(0xFF965027)),
  escape: TextStyle(color: Color(0xFF363C4D)),
  function: TextStyle(color: Color(0xFF2959AA)),
);

/// Cobalt2에서 **발췌**한 색. 재현이 아니다.
const _cobalt2 = SyntaxPalette(
  background: Color(0xFF193549),
  plain: TextStyle(color: Color(0xFFFFFFFF)),
  punctuation: TextStyle(color: Color(0xFFFFFFFF)),
  comment: TextStyle(color: Color(0xFF0088FF), fontStyle: _italic),
  keyword: TextStyle(color: Color(0xFFFF9D00)),
  string: TextStyle(color: Color(0xFFA5FF90)),
  number: TextStyle(color: Color(0xFFFF628C)),
  escape: TextStyle(color: Color(0xFFFF628C)),
  function: TextStyle(color: Color(0xFFFFC600)),
);
