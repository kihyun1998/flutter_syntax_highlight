# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Agent skills

### Issue tracker

Issues live in GitHub Issues for `kihyun1998/flutter_syntax_highlight`, managed with the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles, each label string equal to its name (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## 게이트

넷이고, **각각 맨몸으로** 돌린다. 파이프에 태우지 않는다 — 파이프라인의 종료
상태는 마지막 명령의 것이라, 결과가 걸러지는 검사는 항상 성공한다.

```
flutter analyze
dart format --output=none --set-exit-if-changed lib test example/lib
flutter test
flutter pub publish --dry-run
```

`example/lib`이 format 범위에 있는 것은 #21이 정한 것이다. `flutter analyze`는
트리를 걷기 때문에 예제까지 이미 보고 있었고, 예제는 pub.dev의 example 탭에
그대로 실려 소비자가 읽는다 — format만 구멍이었고, 넓히는 비용이 0이었다.

`flutter test`는 `example/`을 **돌지 않는다**(실패하는 테스트를 심어 확인함).
그래서 예제에는 테스트를 두지 않는다. 되돌릴 일이 있으면 게이트를 먼저 고친다.

초록을 만들려고 기준을 옮기지 않는다. 바닥을 낮추면 딱 그만큼의 회귀가
허용되고, 진짜 회귀는 그 바로 아래에 자리 잡는다.
