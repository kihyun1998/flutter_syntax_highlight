/// A tokenizer for Dart — it decides kinds only, never colours.
///
/// **This file imports nothing.** Not Flutter, not `dart:*`. That is the seam:
/// the widget decides what a kind *looks like*, and this decides what a kind
/// *is*. So the hard part becomes a pure function that can be tested with no
/// widget and no pump. A tokenizer that knew about `ColorScheme` would be a
/// tokenizer you could only test by rendering it.
///
/// ## The property that matters more than the colours
///
/// [tokenizeDart] returns a **partition**: concatenating every token's text
/// reproduces the input byte for byte. A highlighter is a thing that stands
/// between the consumer's bytes and the screen, and this package's claim is
/// that what is on screen is the file you can paste.
///
/// The partition holds **by structure rather than by assertion**. The scanner
/// records end offsets into the source and the tokens are cut at those
/// offsets, so there is no path at all on which a character is dropped,
/// duplicated or rewritten. A token's text is always
/// `source.substring(previousEnd, thisEnd)`.
///
/// Two ways of breaking the paste that a hand-written scanner reaches for
/// naturally, but that this shape rules out by construction: splitting on
/// `\n` and re-joining (which silently normalises CRLF), and emitting the
/// lower-cased form made to match a keyword.
///
/// **A library especially so.** Line endings are a property of the checkout,
/// not of the repository, and a library that accepts arbitrary consumer source
/// has no standing to normalise them.
///
/// ## A comment is consumed whole, and that is the correctness argument
///
/// Measured 2026-09-02: across the eleven files of the reference corpus,
/// **54** comment lines held a lone apostrophe (`somebody's`, `API's`). It is
/// a number that goes stale when a comment is edited, so it carries a date and
/// reads as a measurement rather than as a current fact. A scanner that
/// examined characters one at a time would open a string at each of those 54
/// sites and run to the end of the line, and, if it carried string state
/// across lines, to the next apostrophe several paragraphs down. That is 54
/// sites against the 3 that the interpolation handling exists for, and it is
/// the side that would make the output look broken at a glance.
///
/// What prevents it is the fact that [_lineCommentEnd] and [_blockCommentEnd]
/// consume the **entire** comment in one step, so no character inside a
/// comment is ever dispatched on. **It is not the order of the branches.** An
/// earlier version of this comment claimed it was: a character is either `/`
/// or `'` and never both, so the two arms are mutually exclusive and
/// reordering them does nothing. That was confirmed by measurement —
/// reversing the order changed nothing — and [_lineCommentEnd] had to be
/// crippled instead before the guarding test went red.
///
/// ## What the reference corpus actually contained
///
/// Checked with grep on 2026-09-02, not assumed: **no** raw strings, **no**
/// triple-quoted strings, **no** block comments, **no** escaped quotes, **no**
/// `//` inside a string. All five are handled anyway — each costs a few lines,
/// and the consumer's code is under no obligation to be tame. That is why none
/// of these five is a guard.
///
/// What that corpus actually contained, at that date, is three
/// nested-string-in-interpolation sites, in three different files:
///
/// ```dart
/// final text = '${newValue ?? ''}'.trim();
/// : 'selectedRows: ${selected.join(', ')}',
/// '${term.value ? '✓' : '✗'} ${term.key}',
/// ```
///
/// Naive quote-pairing draws the third as string / `✓` as code / ` : ` as
/// string / `✗` as code — inverted, and on exactly the two glyphs that snippet
/// exists to show. So [_scanStringLiteral] and [_interpolationEnd] are
/// **mutually recursive**: an interpolation is scanned with a brace counter
/// that understands nested strings.
///
/// **And the inside of an interpolation is scanned again by the same rules as
/// the outside.** So the `'✓'` in the third example above comes out as a
/// string, and the conditional around it comes out as code — the very spot a
/// naive quote-pairing scanner paints exactly backwards. One literal is no
/// longer one token.
library;

/// What a run of characters is — only for the purpose of drawing it
/// differently.
///
/// **Deliberately coarse.** Anything finer — telling a type from a variable, a
/// method call from a field — is left out, because it is not lexically
/// decidable but a **guess** that leans on convention, and a half-right answer
/// about what a name *means* is worse than no answer: a reader believes it.
///
/// What was taken in, what was rejected, and why, is in
/// `docs/adr/0001-token-kinds-are-lexical-only.md`.
enum DartTokenKind {
  /// Identifiers, whitespace, and anything unclassified.
  plain,

  /// `//` to end of line, and `/* */` including nested pairs.
  comment,

  /// A reserved word, a built-in identifier, or a contextual keyword.
  keyword,

  /// The part of a string literal not cut out by [escape] and interpolation.
  ///
  /// **Not the whole literal.** `'a\n'` is three tokens, `'a` / `\n` / `'`,
  /// and `'\${x}'` is five, `'` / `\${` / `x` / `}` / `'` — the inside of an
  /// interpolation is scanned again by the same rules as the outside, so a
  /// string inside it comes out as this kind again. The Consequences section of
  /// `docs/adr/0001-token-kinds-are-lexical-only.md` names this sentence, and
  /// the change was carried into it over two passes.
  string,

  /// An integer, double, or hex literal.
  number,

  /// Brackets, operators, separators.
  punctuation,

  /// An escape sequence inside a string — `\n`, `\t`, `\'`, `\\`.
  ///
  /// A backslash and the one character after it. Lexically decidable. It does
  /// not appear in a raw string, where a backslash is just a character.
  escape,

  /// An identifier **immediately before** an opening parenthesis.
  ///
  /// A lexical position, not a semantic classification. Function calls,
  /// constructor calls and method declarations all land here — the scanner
  /// does not tell the three apart. With whitespace in between, it is not
  /// treated as a call.
  ///
  /// Keywords are caught first, so the `if` in `if(x)` is a [keyword].
  function,
}

/// A run of source text, and what it is.
class DartToken {
  const DartToken(this.text, this.kind);

  /// The exact characters, cut from the source. Never rewritten.
  final String text;

  final DartTokenKind kind;

  @override
  String toString() => 'DartToken(${kind.name}, ${text.length} chars)';
}

typedef _Emit = void Function(DartTokenKind kind, int end);

/// Splits [source] into a **partition** of runs tagged with a kind.
///
/// Adjacent runs of the same kind are coalesced, and that is not cosmetic: the
/// widget layer turns one token into one `TextSpan`, `SelectableText` rebuilds
/// its controller whenever the span tree compares unequal, and `TextSpan`
/// equality is a deep walk. Emitting a span per bracket would put thousands of
/// `TextStyle` comparisons on every rebuild to no visible end.
///
/// Measured 2026-09-06: the largest file this repository holds is **3101**
/// tokens (`dart_tokenizer.dart` itself). The reference measured 1436 on
/// 2026-09-02, and that is the number from when there were 6 kinds and strings
/// were not split — it doubled once `escape` arrived and the inside of an
/// interpolation was tokenized recursively. Coalescing bites that much harder.
List<DartToken> tokenizeDart(String source) {
  // Two parallel lists rather than a token list built as we go: the scanner
  // only ever appends an end offset, so "the tokens tile the source" is a
  // property of the loop rather than something to remember at each branch.
  //
  // The pair sits behind a closure. Scanning interpolations recursively raised
  // the number of places that emit to three, and handing two lists around that
  // many times would scatter the invariant across three places.
  final kinds = <DartTokenKind>[];
  final ends = <int>[];
  void emit(DartTokenKind kind, int end) {
    // **Ends increase monotonically.** This is the partition's last line of
    // defence — whatever any branch miscalculates, the tokens tile the source
    // without overlap and `substring` does not throw.
    //
    // As of 2026-09-06 this guard is **never reached.** Fuzzing 200,000 inputs
    // over an alphabet that includes comment atoms reached it 0 times. It
    // stays because reaching it means the scanner has a bug, and at that point
    // the only choices are "a slightly wrong colour" and "an exception in the
    // consumer's app". The `assert` makes it loud during development, and in a
    // release the one line below takes it quietly.
    assert(
      ends.isEmpty || end > ends.last,
      'a token end went backwards — some scanner miscalculated a boundary',
    );
    if (ends.isNotEmpty && end <= ends.last) return;
    kinds.add(kind);
    ends.add(end);
  }

  _scanRange(source, 0, source.length, emit);

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

/// Walks `[from, to)` and sends tokens out through [emit].
///
/// **It calls itself.** Code inside an interpolation has to be scanned by the
/// same rules as the outside, and that is the point of this package — in
/// `'\${a ? 'x' : 'y'}'` the inner `'x'` is drawn as a string. A scanner that
/// pairs quotes paints exactly the opposite.
///
/// [_interpolationEnd], which sets the boundary, and the sub-scan here use the
/// same sub-scanners — for strings and for comments alike. So the two do not
/// drift apart.
///
/// Once they did. [_interpolationEnd] did not know about comments and looked
/// for the closing brace of `'\${a /* } */ + 1}'` **inside** the comment, and
/// that was valid Dart. The response at the time was to clamp the end offset
/// here, but the clamped end went behind the previous end and `substring`
/// threw — a worse failure than a wrong colour. Instead of clamping, the drift
/// itself was removed, and the only line of defence left is the one `emit` in
/// `tokenizeDart`.
void _scanRange(String source, int from, int to, _Emit emit) {
  var i = from;
  while (i < to) {
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
      // A string does not end as one token. Escapes are cut out and
      // interpolations are scanned recursively inside it, so this branch
      // cannot use the single `emit` below and emits directly.
      i = _scanStringLiteral(source, i, i, raw: false, emit: emit);
      continue;
    } else if (_isIdentifierStart(c)) {
      final end = _identifierEnd(source, i);
      // `r'...'` — the `r` is a prefix only where an identifier could not have
      // continued, which is exactly when the identifier scan stops on a quote.
      if (end == i + 1 &&
          c == _lowerR &&
          end < source.length &&
          (source.codeUnitAt(end) == _singleQuote ||
              source.codeUnitAt(end) == _doubleQuote)) {
        // Raw strings take the same path. `raw` blocks both escape and
        // interpolation handling, so the result is the same single token, but
        // removing the special case is what makes the check "no escape appears
        // in a raw string" pass because of the `raw` decision rather than
        // because of the shape of the path.
        i = _scanStringLiteral(source, i, end, raw: true, emit: emit);
        continue;
      } else {
        // Keywords are checked **first.** If this order flipped, the `if` in
        // `if(x)` would be painted as a function name — and so would `for`,
        // `while`, `switch` and `catch`, which makes it the most visible
        // regression.
        if (_keywords.contains(source.substring(i, end))) {
          kind = DartTokenKind.keyword;
        } else if (end < source.length &&
            source.codeUnitAt(end) == _openParen) {
          // Only **immediately before.** Not skipping whitespace is the
          // simplest lexically decidable form, and since `dart format` removes
          // that whitespace, it misses almost nothing in real code.
          kind = DartTokenKind.function;
        } else {
          kind = DartTokenKind.plain;
        }
        i = end;
      }
    } else if (_isDigit(c)) {
      kind = DartTokenKind.number;
      i = _numberEnd(source, i);
    } else if (_isPunctuation(c)) {
      kind = DartTokenKind.punctuation;
      i++;
    } else {
      // Whitespace, and anything outside the classes above — including the
      // halves of a surrogate pair, which arrive as two `plain` runs and are
      // coalesced back into one token later.
      kind = DartTokenKind.plain;
      i++;
    }

    emit(kind, i);
  }
}

/// End of a `//` comment. The newline itself is **not** part of it.
///
/// A trailing `\r` is, wherever the checkout produced CRLF. That is deliberate
/// — it keeps the carriage return inside a token rather than inventing a new
/// rule about where a line ends, and the partition protects the paste either
/// way.
///
/// **Line endings are a property of the checkout, not of the repository.**
/// With `.gitattributes` at `* text=auto`, a Windows clone produces CRLF and a
/// Linux clone produces LF. So a test that tries CRLF through a file fixture
/// tests that machine rather than the code — only CRLF built from an escape
/// literal is immune to the checkout.
int _lineCommentEnd(String source, int i) {
  var j = i;
  while (j < source.length && source.codeUnitAt(j) != _newline) {
    j++;
  }
  return j;
}

/// End of a `/* */` comment, counting nested pairs.
///
/// Dart nests block comments where C does not, so `/* /* */ */` is one
/// comment, and a scanner that stops at the first `*/` leaves the tail of the
/// file mis-coloured. The reference corpus measured on 2026-09-02 held none.
/// It is handled anyway — it costs four lines, and the consumer's code is
/// under no obligation to be tame.
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

/// Walks the string literal that starts at [quoteAt] and returns its end.
///
/// Given [emit], it emits tokens; otherwise it only computes the boundary. The
/// two modes being one function is the point — [_interpolationEnd] must only
/// **skip** nested strings, and two copies of the boundary code could drift
/// apart, and the partition would expose that drift as it is.
///
/// [runStart] is the start of the token run. For a raw string it differs from
/// [quoteAt], because the `r` prefix comes before the quote.
///
/// [raw] turns off escape handling: in `r'a\'` the backslash is just a
/// character, so consuming two would run past the closing quote. A raw string
/// has no interpolation either.
///
/// An unclosed string in single rather than triple quotes stops at the newline
/// instead of running to the end of the file. That confines the damage from
/// syntax this scanner does not understand to the line it is on, rather than
/// the rest of the file.
int _scanStringLiteral(
  String source,
  int runStart,
  int quoteAt, {
  required bool raw,
  _Emit? emit,
}) {
  final quote = source.codeUnitAt(quoteAt);
  final triple =
      quoteAt + 2 < source.length &&
      source.codeUnitAt(quoteAt + 1) == quote &&
      source.codeUnitAt(quoteAt + 2) == quote;
  var j = quoteAt + (triple ? 3 : 1);

  // The start of the `string` run not yet emitted. With a raw prefix it starts
  // before the quote.
  var segment = runStart;
  void flush(int upTo) {
    if (emit != null && upTo > segment) emit(DartTokenKind.string, upTo);
    segment = upTo;
  }

  while (j < source.length) {
    final c = source.codeUnitAt(j);

    if (!raw && c == _backslash) {
      flush(j);
      final stop = j + 2 > source.length ? source.length : j + 2;
      if (emit != null) emit(DartTokenKind.escape, stop);
      j = stop;
      segment = j;
      continue;
    }

    if (!raw &&
        c == _dollar &&
        j + 1 < source.length &&
        source.codeUnitAt(j + 1) == _openBrace) {
      // The newline boundary has to be passed down. Otherwise `${` becomes a
      // hole punched in that boundary: an unclosed interpolation runs to the
      // end of the file and paints everything after it as string, which is
      // exactly what the boundary below exists to stop. Only triple-quoted
      // literals are exempt, since they really can span lines.
      final (end, closed) = _interpolationEnd(
        source,
        j + 2,
        stopAtNewline: !triple,
      );
      if (emit != null) {
        flush(j);
        emit(DartTokenKind.punctuation, j + 2); // `${`
        _scanRange(source, j + 2, closed ? end - 1 : end, emit);
        if (closed) emit(DartTokenKind.punctuation, end); // `}`
        segment = end;
      }
      j = end;
      continue;
    }

    if (c == quote) {
      if (!triple) {
        j += 1;
        break;
      }
      if (j + 2 < source.length &&
          source.codeUnitAt(j + 1) == quote &&
          source.codeUnitAt(j + 2) == quote) {
        j += 3;
        break;
      }
    }
    if (!triple && c == _newline) break;
    j++;
  }

  flush(j);
  return j;
}

/// End of a `${...}` interpolation, and whether the closing brace was actually
/// met.
///
/// Mutually recursive with [_scanStringLiteral], and that is the point: a
/// brace counter alone gets `'${selected.join(', ')}'` wrong, because the
/// inner `'` would end the outer literal. Handing nested quotes back to the
/// string scanner is the mechanism that brings out whole the three real sites
/// measured on 2026-09-02.
///
/// This only **skips**. The caller re-walks the tokens inside the
/// interpolation with [_scanRange] and emits them. Whether the closing brace
/// was met is returned alongside because that brace has to be emitted as
/// punctuation, and when the scan stopped at a newline there is no brace to
/// emit at all.
(int, bool) _interpolationEnd(
  String source,
  int j, {
  required bool stopAtNewline,
}) {
  var depth = 1;
  while (j < source.length) {
    final c = source.codeUnitAt(j);
    // Skip comments, for **the same reason** as strings — a brace inside a
    // comment is not a brace. Without this, the `}` inside the comment in
    // `'\${a /* } */ + 1}'` ends the interpolation and everything after it
    // drifts. It is valid Dart, and code that actually runs.
    if (c == _slash && j + 1 < source.length) {
      final next = source.codeUnitAt(j + 1);
      if (next == _slash) {
        j = _lineCommentEnd(source, j);
        continue;
      }
      if (next == _star) {
        j = _blockCommentEnd(source, j);
        continue;
      }
    }
    if (c == _singleQuote || c == _doubleQuote) {
      // The `r` prefix is checked here too, by the same rule as the outer loop
      // — only an `r` where an identifier could not have continued is a
      // prefix. Without this, a raw string inside an interpolation would be
      // scanned as a string that handles escapes, running past the closing
      // quote, throwing the boundary off, and even attaching the `escape` kind
      // wrongly.
      final raw =
          source.codeUnitAt(j - 1) == _lowerR &&
          (j - 2 < 0 || !_isIdentifierPart(source.codeUnitAt(j - 2)));
      j = _scanStringLiteral(source, j, j, raw: raw);
      continue;
    }
    // Inherited from the enclosing literal. Without this, `'${oops` returns
    // `source.length` and never reaches the newline boundary in
    // [_scanStringLiteral] — an unconfined run straight through the branch
    // whose whole reason to exist is to confine something.
    if (stopAtNewline && c == _newline) return (j, false);
    if (c == _openBrace) {
      depth++;
    } else if (c == _closeBrace) {
      depth--;
      if (depth == 0) return (j + 1, true);
    }
    j++;
  }
  return (source.length, false);
}

/// End of a numeric literal. Kept conservative: over-consuming only mis-paints
/// one character, and the partition is unaffected either way.
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
  // A `.` is part of a number only when a digit follows, so `1.toString()`
  // leaves the method name outside the literal.
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

/// ASCII punctuation, minus the characters an earlier stage of the scan has
/// already handled.
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
const _openParen = 0x28;
const _openBrace = 0x7B;
const _closeBrace = 0x7D;

/// Dart's reserved words, built-in identifiers, and the contextual keywords a
/// reader would expect to see marked.
///
/// A word here is styled wherever it appears — a variable named `show` or a
/// field named `base` too. That is the cost the scanner accepts: the
/// alternative is knowing what a name refers to, and that is a parser.
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
