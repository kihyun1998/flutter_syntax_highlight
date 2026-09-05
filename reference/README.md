# 참조 구현 스냅샷

이 디렉터리는 **패키지의 일부가 아니다.** `flutter_table_plus`의 example 앱에서
그대로 떠 온 4개 파일이고, 손대지 않은 채로 둔다.

## 출처

| 항목 | 값 |
|---|---|
| repo | `flutter_table_plus` (kihyun1998) |
| 커밋 | `ac83b2719249a43c821d265ee5c3c4d46f5056dd` |
| 커밋 제목 | *fix(example): the CRLF guard was testing the checkout, and the machine moved* |
| 날짜 | 2026-09-04 |
| 라이선스 | MIT, © 2025 Ki Hyun Park (동일 저작자) |
| 뜬 날 | 2026-09-05 |

원본 경로 → 여기:

```
example/lib/shell/dart_highlighter.dart   (424줄) → dart_highlighter.dart
example/lib/shell/source_pane.dart        (463줄) → source_pane.dart
example/test/dart_highlighter_test.dart   (341줄) → dart_highlighter_test.dart
example/test/source_pane_test.dart        (646줄) → source_pane_test.dart
```

네 파일 모두 `ac83b27`의 내용과 **바이트 동일**하다 (shasum 대조 완료).

## 왜 작업 트리가 아니라 이 커밋인가

스냅샷을 뜬 시점에 `flutter_table_plus`의 작업 트리에는 커밋되지 않은 대규모
리팩토링이 걸려 있었다 — `example/lib/shell/` → `example/lib/gallery/src/shell/`.
그 트리를 기준으로 삼지 않은 이유:

1. **차이가 전부 우리가 어차피 지울 것들이었다.** 실제 diff는 import 경로 재작성,
   `dart format` 리플로우, 그리고 버리기로 한 테스트 안의 host API 변경뿐이다.
   토크나이저와 pane의 **동작은 한 줄도 다르지 않다.**
2. **커밋되지 않은 트리에는 이름이 없다.** 나중에 "우리가 정확히 무엇을 떴나"를
   물었을 때 가리킬 것이 없고, 그 리팩토링이 되돌려지거나 다시 만들어지면
   기준 자체가 증발한다.
3. `ac83b27`은 **CRLF 문제의 답을 이미 담고 있다.** 그 커밋이 곧 그 수정이다 —
   escape literal이 CRLF 증인이고, escape는 체크아웃에 면역이다.

## 왜 `lib/`가 아니라 여기인가

이 파일들은 `package:example/...`를 import하므로 여기서는 컴파일되지 않는다.
그리고 구현이 시작되면 자기 결과물을 이 원본과 대조해야 하는데, `lib/`에
떨어뜨려 놓고 그 자리에서 고치면 대조할 원본이 사라진다. 구현은 여기서
**복사해 가고**, 이 디렉터리는 손대지 않은 채 남는다.
