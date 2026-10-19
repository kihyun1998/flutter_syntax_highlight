# 위젯은 아무도 정하지 않은 스크롤바 필드만 채우고, 색은 팔레트가 정한다

`SyntaxText`가 자기 스크롤바에 끼우는 `ScrollbarTheme`은 바깥의 `ScrollbarTheme.of(context)`를 **갈아 끼우지 않고 그 위에 얹는다.** 필드마다 주인이 다르다:

- **`thumbColor`는 팔레트가 정한다** (배경이 있을 때). [ADR-0002](0002-a-palette-carries-its-own-background.md)의 규칙 그대로 — 색을 고른 사람이 그 색이 놓일 자리도 정한다. 앱이 준 색은 앱의 surface에 대고 고른 것이라 프리셋의 배경 위에서는 아무것도 보장하지 않는다.
- **동작과 모양(`interactive`, `thumbVisibility`, `thickness`, `radius`…)은 소비자가 정한다.** 배경과 무관한 값이다.
- **아무도 정하지 않은 값은 위젯이 채운다.** `TargetPlatform.android`에서 앱 테마의 `interactive`와 `thumbVisibility`가 비어 있으면, **가로** `Scrollbar`의 위젯 파라미터로 `true`를 넘긴다. 테마로 채우지 않는 것은, 테마가 그 아래의 세로 바에도 걸려 세로 바까지 늘 보이게 되기 때문이다.

규칙은 하나다: **그 값을 무엇을 보고 골랐는지가 그 값의 주인을 정한다.**

[#29](https://github.com/kihyun1998/flutter_syntax_highlight/issues/29)의 grilling에서 정했다 (2026-10-19).

## Context

클래스 doc은 가로 `Scrollbar`를 **"터치에서 유일한 가로 어포던스"**라고 적는다. 선택 제스처가 텍스트 위 가로 드래그를 가져가기 때문이다(2026-09-06 측정). 그런데 Android에서 그 바는 끌리지 않았다. 2026-10-19 측정:

| | 끈 뒤 가로 위치 |
|---|---|
| widget test, android, `scrollable` true / false | **0.0** / 0.0 |
| widget test, windows (대조군) | 302.3 |
| 에뮬레이터(Medium Phone API 36.1), 기본 | **0.0** |
| 에뮬레이터, 앱 테마로 `interactive`·`thumbVisibility`를 켬 | 127.4 / 127 (끝까지) |

원인은 두 겹이다. Material `Scrollbar`는 Android에서만 `interactive`의 기본값이 false이고, thumb은 스크롤할 때만 나타나며 투명하면 hit test에도 걸리지 않는다. 가로를 스크롤할 길이 그 thumb뿐이므로, 처음 보이게 만들 방법이 없다.

**그리고 소비자가 직접 켜는 길도 막혀 있었다.** 위젯은 배경이 있을 때 thumb 색을 맞추려고 `ScrollbarTheme(data: ScrollbarThemeData(thumbColor: …))`를 끼웠다. 테마는 합쳐지지 않고 가장 가까운 것 하나만 읽힌다. 그래서 색 하나를 바꾸려던 테마가 그 위에서 앱이 정한 나머지 필드를 전부 지웠다:

| 앱 테마로 바를 켰을 때 (android, widget test) | |
|---|---|
| 파생 기본 (배경 없음 → 위젯이 테마를 끼우지 않음) | 302.3 |
| `SyntaxPalette.oneDark` (배경 있음) | **0.0** |

## 고려한 것

- **위젯이 강제한다.** Android에서 늘 켠다. 소비자는 끌 수 없다 — 바가 늘 보이는 것을 원치 않는 앱에서 패키지가 화면 모양을 일방적으로 정한다.
- **소비자에게 맡긴다.** 합치기만 고친다. 기본 상태의 Android 사용자는 여전히 가로로 넘길 수 없고, doc의 "유일한 어포던스"는 거짓으로 남는다.
- **빈 필드만 채운다 (채택).** 처음 쓰는 사람에게 바로 동작하고, 덮을 길도 남는다. Flutter 테마가 원래 해석되는 순서(위젯 파라미터 → 가까운 테마 → 플랫폼 기본값)에 끼어들 뿐 그것을 뒤집지 않는다.

## Consequences

**소비자가 `thumbVisibility: false`나 `interactive: false`를 명시하면 Android 터치 사용자는 가로로 넘길 수 없다.** 그 값이 이기는 것이 이 결정의 요점이므로 막지 않는다. 대신 클래스 doc이 그것을 경고한다.

**`interactive`를 켜면 track 탭도 켜진다.** Android에서 바 자리를 탭만 해도 한 페이지 넘어가고(400×300, 80줄에서 0 → 320), 그 띠의 터치는 텍스트에 닿지 않는다. Material `Scrollbar`는 드래그와 track 탭을 따로 끌 파라미터가 없다. grilling에서 `interactive: true`를 정할 때는 이 결과를 보지 못했고, 측정 후 메인테이너가 대가로 받아들였다(2026-10-19). 테스트가 이 동작을 고정한다.

**Android에서만 채운다.** 측정으로 확인한 곳이 Android뿐이고, Material `Scrollbar`가 자기 Android 분기(`interactive` 기본 false)를 타는 플랫폼도 그것 하나다. 그렇다고 문제가 Android에만 있다는 뜻은 아니다 — 두 번째 원인(투명한 thumb은 히트를 받지 않는다)은 thumb이 숨은 채 시작하고 가로 드래그를 선택이 가져가는 곳이면 어디든 해당할 수 있다. iOS는 widget test에서 같은 0.0이 나왔지만 Cupertino는 제스처 체계가 다르고 기기로 재지 않았으므로 [#30](https://github.com/kihyun1998/flutter_syntax_highlight/issues/30)으로 뺐다. 다른 플랫폼은 재지 않았다.

**`scrollable: true`에서 가로 바는 바깥에 둔다** (`notificationPredicate: depth == 1`). 세로 스크롤 뷰 안에 있으면 바가 내용 맨 끝(80줄이면 y≈1472)에 그려져, 끌 수 있어도 보이지 않는다.

**바는 위젯 바닥보다 `MediaQuery`의 bottom padding만큼 위에 그려진다.** grilling에서는 "기본 `padding` 16이 Android thumb 4px를 감싸니 마지막 줄을 가리지 않는다"고 보고 따로 묻지 않았는데, 그 계산은 틀렸다. `RawScrollbar`는 `padding`을 주지 않으면 `MediaQuery.paddingOf(context)`를 쓰고, 위젯이 화면 중간에 있어도 그 값이 내려온다. 에뮬레이터(bottom padding 24)에서 바가 마지막 줄 글자 위에 겹쳤다(2026-10-19). 수정 전에도 같은 계산이었지만 Android에서는 바가 투명해 보이지 않았다. 어떻게 할지는 아직 정하지 않았다 — [#31](https://github.com/kihyun1998/flutter_syntax_highlight/issues/31), 0.4.0 전에 정한다.

**시스템 제스처 영역은 앱 레이어의 일이다.** 위젯이 화면 맨 아래에 놓이면 thumb이 그 영역에 걸린다. 에뮬레이터에서는 그 자리의 드래그가 일부만 전달됐다(30.8, 77.1 / 127). 위젯은 자기가 화면 어디에 놓였는지 모르므로 `systemGestureInsets`를 읽어 피하지 않는다. doc에 적는다.

**ADR-0002의 "위젯 자신의 컨트롤도 팔레트를 따라간다"를 좁힌다.** 따라가는 것은 **색**이다. 그 문장을 테마를 통째로 갈아 끼우는 것으로 구현한 것이, 프리셋 아래에서 소비자의 opt-in이 0.0이 된 이유다.
