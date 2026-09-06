# 픽스처 corpus

토크나이저에 먹이는 **입력 데이터**다. 코드가 아니다.

## 왜 확장자가 `.dart`가 아닌가

게이트가 `test/**.dart`를 걷는다. 그리고 이 corpus의 요점은 **얌전하지 않은
입력**이다 — 닫히지 않은 문자열, 닫히지 않은 보간처럼 파싱되지 않는 것들이
들어 있어야 한다. 그것을 `.dart`로 두면:

네 파일을 `.dart`로 두고 재보면:

```
dart format --output=none --set-exit-if-changed lib test   → 65
flutter analyze                                            → 1  (18 issues, 16 errors)
``` 게이트를 통과시키려고 corpus를 얌전하게 만드는 것은 기준을
옮기는 일이므로, 확장자를 옮겼다.

여기에 줄바꿈 방식이 없는 이유는 `corpus_test.dart`의 doc에 있다.

## 무엇이 들어 있는가

참조 구현의 doc이 2026-09-02에 grep으로 확인해 열거한 일곱 가지다. 그 corpus에는
없었지만 소비자의 코드는 얌전할 의무가 없으므로 전부 다룬다.

`malformed.dart.txt`는 그 일곱에 없다. 확장자 결정의 근거가 바로 이 파일이고 —
파싱되지 않는 입력이 있어야 게이트가 실제로 죽는다 — partition은 얌전하지 않은
입력에서도 성립해야 하므로 남겼다.

| 파일 | 담고 있는 것 |
|---|---|
| `strings.dart.txt` | 원시 문자열, 삼중 따옴표, escape된 따옴표, 문자열 안의 `//` |
| `comments.dart.txt` | 아포스트로피 든 주석, 문서 주석 안의 따옴표, 중첩 블록 주석 |
| `interpolation.dart.txt` | 중첩 보간 세 사례와 보간 안 문자열의 중괄호 |
| `malformed.dart.txt` | 닫히지 않은 문자열, 닫히지 않은 보간 |

`corpus_test.dart`가 이 목록을 실제로 확인한다 — 파일이 비거나 구문이 빠지면
partition 검사는 통과하면서 아무것도 지키지 않게 되기 때문이다.
