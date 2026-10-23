# A token kind holds only lexically decidable distinctions

`DartTokenKind` has 8 values: `plain` `comment` `keyword` `string` `number` `punctuation` `escape` `function`. Whether a distinction is promoted to a kind was decided by **whether a scanner can decide it for certain from the characters alone** — whether 9 well-known themes actually paint it differently was looked at too, but that is a necessary condition, not a sufficient one. A distinction the lexicon does not decide is not added, however widely it is painted. A half-right answer is worse than no answer, because the reader believes it.

## Considered Options

**Add `type` vs `variable`** — **all 9/9** of the surveyed themes paint these two in different colours. It is the most visible distinction, and leaving it out gives the impression of being "flatter than other highlighters". But the rule the official Dart TextMate grammar (`dart-lang/dart-syntax-highlight`) decides it with is `[_$]*[A-Z][a-zA-Z0-9_$]*` — a convention-based guess that **if it starts with a capital, it is a type**. It is wrong on `const PI`, enum values and generic parameters. The only lexically certain part is the fixed list `int double bool num dynamic void`, and all 9 themes paint those in the same colour as user-defined types, so that fragment alone gives no visual gain. **Rejected.**

**Add `annotation` (`@override`)** — an identifier after `@`, so lexically perfect. But the survey found **0/9** themes that paint it differently in Dart. The themes' decorator rules are Java/Python only and do not reach Dart's `storage.type.annotation.dart`. It passes the lexical condition but nobody uses it. **Rejected.**

**Split `operator` out of `punctuation`** — lexically obvious. But there is no consensus: only 1/9 gives it its own colour, 6/9 the same colour as keyword, and 2/9 explicitly set it back to plain. Splitting it would not settle what a palette should do. **Rejected.**

**Add `interpolation` as a kind** — at first the strongest candidate. 8/9 themes paint the interpolation span differently from the string, and the scanner's `_stringEnd` and `_interpolationEnd` were already computing that boundary and throwing it away. **But once the inside of an interpolation was to be tokenized recursively, the need went away** — see below.

## Consequences

**The inside of an interpolation is tokenized recursively.** `'${term.value ? '✓' : '✗'}'` becomes not one token but a sequence of `string` / `punctuation` / `plain` / `string` / …. What the themes do is *"turn the string colour off inside an interpolation and fall back to the default foreground"*, and once the contents simply become ordinary tokens, that is achieved by itself. So there is no `interpolation` kind — **it is absent not because it cannot be done, but because there is nothing for it to do.** Without this file, it is the exact point where the next person will ask "why is there no interpolation kind".

**Instead, that sequence proves this package's claim on screen.** The nested `'✓'` is drawn as a string. A quote-pair regex scanner paints exactly the opposite — the code inside the interpolation as string, and the string as code.

**One sentence of the doc comment became false.** The reference wrote *"A whole literal is one token, interpolations included"*. It no longer is. The argument that sentence held up (the mutual recursion of `_stringEnd` and `_interpolationEnd` finds the boundary correctly) has not changed, and has if anything become visible as tokens. Only the sentence is rewritten.

**The partition property stands.** Cutting tokens finer still cuts them all at recorded offsets, so concatenating them still equals the input byte for byte.

**This list is effectively permanent.** Adding a value to a Dart enum breaks a consumer's exhaustive `switch`, so after publishing to pub it is a breaking change. "Add it later if needed" does not hold, so it was nailed down at the point the survey gave grounds for it. For the record, it is not an overreach — the surveyed themes have 11–18 foreground colours, but **7–10 actually appear inside a Dart file**, and 8 sits in the middle of that.

**Only `function` extends what the scanner does.** The other seven only need the scanner to emit what it already knows, but `function` adds a new lookahead branch that looks ahead for `(`. It is the one place in this decision with regression risk, so it is where mutation testing is most needed.

---

*The measurement it rests on: [What do well-known syntax themes actually paint differently](https://github.com/kihyun1998/flutter_syntax_highlight/issues/3) (2026-09-05). Decision: [The final list of DartTokenKind](https://github.com/kihyun1998/flutter_syntax_highlight/issues/5).*

---

## Later record

**The function was renamed.** What is called `_stringEnd` above is now
`_scanStringLiteral`. Once the inside of an interpolation was tokenized
recursively, one function took on both computing the boundary and emitting the
tokens, and the name followed. The decision itself did not change.

**"The partition property stands" was false once.** When recursive tokenizing
went in, the scanner that decides the boundary and the scanner that re-sweeps the
inside were judged able to disagree, and a defence that clamped the end offset
was added. That defence pushed a clamped end behind an earlier end, `substring`
threw — **on valid Dart** — and it became a failure worse than a wrong colour.

Two things came out on the spot. First, the cause of the disagreement was that
the interpolation scanner did not know about comments, and that was not a
problem to defend against but a bug to fix (`'${a /* } */ + 1}'` is valid and
runs). Second, a comment that said "this input is not valid Dart" was not true —
that one sentence was justifying the defence.

Now there is no disagreement at all, and the last barrier is a single line in
`tokenizeDart`'s `emit` that guarantees the end increases monotonically. As of
2026-09-06, fuzzing 300,000 inputs with an alphabet that includes comment atoms
gives 0 partition violations, 0 exceptions, and 0 hits on that guard.
