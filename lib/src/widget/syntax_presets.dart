part of 'syntax_palette.dart';

// Only the **data** of the named presets lives here. The declarations are
// inside [SyntaxPalette] and point at the constants here; call sites read
// `SyntaxPalette.solarizedDark`.
//
// The files are split because their axes of change differ. [SyntaxPalette]
// itself is this package's seam and changes when the kinds grow. The values
// below are data from third-party themes and move together with `NOTICES`.
// Kept in one file, that file would change for two reasons.

const _italic = FontStyle.italic;
// ───────────────────────────────────────────────────────────────────────
// Named presets
//
// **An excerpt, not a reproduction.** The upstream themes assign colours to
// tens to hundreds of TextMate scopes, and this package has eight kinds. Each
// preset pulls out the colours the upstream gave to the scopes that match
// those eight, so it does not look identical to the original editor.
//
// The source of each value is recorded in `NOTICES`, down to the file and the
// commit. The same theme is licensed differently from version to version, so
// without that record the finding could not be made again later.
//
// The default is **not** one of these. Only [SyntaxPalette.fromColorScheme]
// fits both light and dark with no configuration. A named preset is by
// definition a hard-coded palette and breaks at the opposite brightness, so
// where the original has a pair, it ships as a pair.
// ───────────────────────────────────────────────────────────────────────

/// Colours **excerpted** from Solarized Dark. Not a reproduction.
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

/// Colours **excerpted** from Solarized Light. Not a reproduction.
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

/// Colours **excerpted** from One Dark. Not a reproduction.
///
/// It is not named `atomOneDark` because `ATOM` is a GitHub trademark. The
/// values come from `atom/one-dark-syntax`, and that file is MIT-licensed.
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

/// Colours **excerpted** from One Light. Not a reproduction.
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

/// Colours **excerpted** from Monokai. Not a reproduction.
///
/// The only preset whose comments are not italic, because the original's are
/// not. `escape` sharing `number`'s colour is also as in the original: this
/// theme has no dedicated rule for `constant.character.escape`, so it is
/// absorbed into the parent `constant` rule.
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

/// Colours **excerpted** from Gruvbox Dark. Not a reproduction.
///
/// The values come from an MIT port, not the canonical Vim version:
/// `morhetz/gruvbox` has no LICENSE file and no copyright-holder statement, so
/// there is no original text to copy into `NOTICES`. The price was fidelity in
/// two slots: the port absorbs `escape` into the `constant` rule and colours
/// functions yellow, whereas the canonical version gives escapes their own
/// orange and makes functions green and bold. **The two sets of values were
/// not mixed**: mixing them would make a palette that exists nowhere.
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

/// Colours **excerpted** from Gruvbox Light. Not a reproduction. See
/// [gruvboxDark].
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

/// Colours **excerpted** from Tokyo Night. Not a reproduction.
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

/// Colours **excerpted** from Tokyo Night Light. Not a reproduction.
///
/// This preset's `escape` (`#363C4D`) is barely distinguishable by eye from the
/// body text (`#343B59`). **The original defines it that way, and there are no
/// grounds to fix it by guess, so it ships as is.**
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

/// Colours **excerpted** from Cobalt2. Not a reproduction.
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
