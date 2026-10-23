import 'package:flutter/material.dart';

import '../tokenizer/dart_tokenizer.dart';

part 'syntax_presets.dart';

/// How a kind looks: the policy side of the seam.
///
/// **This is not a theme engine.** There is no registry to enrol presets in,
/// no lookup by name, and no logic that computes colours. It is eight
/// [TextStyle]s, and any left out stay null and inherit the root style
/// unchanged.
///
/// This type exists so that the tokenizer never knows about `Color`. The
/// tokenizer decides *what* a kind is, and this decides *how* a kind looks. If
/// that line collapses, lexical classification can no longer be tested
/// without rendering.
///
/// ## The default is derived from the consumer's `ColorScheme`
///
/// [SyntaxPalette.fromColorScheme] is the default, and it is **hue-neutral
/// towards the consumer's scheme.** It reads only three roles:
/// [ColorScheme.onSurface], [ColorScheme.onSurfaceVariant] and
/// [ColorScheme.outline]. If the app is achromatic, the palette is achromatic;
/// if the app has colour, the palette blends into it.
///
/// The reference described this as *"hue-free, and that is a constraint
/// rather than a taste"*, but its grounds were that the app's scheme was
/// `DynamicSchemeVariant.monochrome`, so **there was no hue to take in the
/// first place**. Moving into a library removed that premise, so the sentence
/// was rewritten, and the rewritten one is more general: a property, not a
/// condition.
///
/// Because it is derived, it fits both light and dark with no configuration.
/// A hard-coded palette breaks silently at the opposite brightness.
///
/// **There is a cost, and it is not hidden.** Without introducing hue, only
/// three axes are available, lightness, weight and slant, and how far apart
/// the `ColorScheme` roles sit is not ours to decide. Measured 2026-09-06:
/// with `ColorScheme.fromSeed(0xFF6750A4)`, the contrast of `onSurface`
/// against `onSurfaceVariant` is **1.32** in dark and **1.83** in light; that
/// is how faint the difference between plain code and strings is. Named
/// presets with colour do not have this limit.
///
/// ## Comments are not dimmed
///
/// A typical highlighter dims comments and brightens keywords. That assumes
/// **skimming code you already know**, and the code this package draws is
/// usually placed there to be read.
///
/// There is a firmer argument. Anyone who knows Dart can read keywords and
/// punctuation back out of the code, but **comments are the only part that
/// cannot be recovered from the code.** Dimming precisely the part that cannot
/// be recovered is backwards. So italics set comments apart while leaving
/// their contrast intact, and what recedes instead is punctuation.
///
/// The reference attached a measurement here: as of 2026-09-02, 762 of the
/// 2603 lines in its corpus (29%) were comments. **That number cannot ground
/// this conclusion.** It comes from a corpus written to teach, and ordinary
/// application code runs far lower. It is kept as a measurement only.
///
/// ## No style specifies `fontFamily`
///
/// This is a hard rule. A leaf that names a family is drawn in a proportional
/// font, while the guard that reads the outer `EditableText.style` stays
/// green. The widget specifies the monospace face once, and every token
/// inherits it.
@immutable
class SyntaxPalette {
  /// Any kind left out stays null and inherits the root style.
  const SyntaxPalette({
    this.background,
    this.plain,
    this.comment,
    this.keyword,
    this.string,
    this.number,
    this.punctuation,
    this.escape,
    this.function,
  });

  /// How far the derived default pulls towards the app's accent.
  ///
  /// **The anchor is always a neutral role**, and this value is how far to
  /// move away from it. 1.0 uses the app's `primary`/`tertiary` as they are,
  /// and then the code block wears the app's accent wholesale and a palette
  /// meant to be quiet turns loud.
  ///
  /// **0.70 was chosen by measurement** (2026-09-07, sweeping `fromSeed` over
  /// 12 directions of the colour wheel × light and dark). Two marks on the
  /// scale already existed in this repository: in the same sweep,
  /// `onSurfaceVariant` and `onSurface` differ by **ΔE 9.9**, which was barely
  /// visible in screenshots; `outline` and `onSurface` differ by **29.9**,
  /// which is clearly visible. Every distinction that 0.70 newly creates falls
  /// between the two: string↔plain 15.4, string↔number 11.4, function↔plain
  /// 17.4, function↔string 15.9.
  ///
  /// **Contrast ratio was not a constraint.** Even at `t = 1.0` the worst case
  /// against surface is 6.1, and the `outline` this palette already carries is
  /// 4.23: M3's `fromSeed` maps `primary`/`tertiary` to fixed tones, which
  /// makes them legible in the first place. The first expectation was that
  /// contrast would set the upper bound, and that was wrong.
  static const _accentMix = 0.7;

  /// The style of the colour [_accentMix] of the way from [anchor] towards
  /// [accent].
  static TextStyle _towards(Color anchor, Color accent) =>
      TextStyle(color: Color.lerp(anchor, accent, _accentMix));

  /// The default palette, derived from the consumer's [ColorScheme].
  ///
  /// The two paragraphs of the doc above, that it is hue-neutral and that it
  /// does not dim comments, are implemented here.
  factory SyntaxPalette.fromColorScheme(ColorScheme scheme) => SyntaxPalette(
    // **[background] is not given.** The surface the app has already painted
    // is the right background for this palette. Painting `scheme.surface`
    // again here lays one more coat of the same colour, and takes away the
    // app's freedom to set just the code block on a different surface.
    // `plain` is not given. The root style is already the colour plain code
    // should have, and it saves one object per token.
    comment: const TextStyle(fontStyle: FontStyle.italic),
    keyword: const TextStyle(fontWeight: FontWeight.w600),
    // Starts from the dim role and pulls [_accentMix] of the way towards the
    // app's `tertiary`. The dimness stays and a hue is added: the property
    // that literals sit back from the body is unchanged, and a distinction is
    // laid on top.
    string: _towards(scheme.onSurfaceVariant, scheme.tertiary),
    // **`number` is not pulled.** That way, as `string` moves, a distinction
    // between strings and numbers appears that was not there before
    // (measured: ΔE 11.4). Move all three literals together and they stay
    // put relative to each other.
    number: TextStyle(color: scheme.onSurfaceVariant),
    // escape is drawn **together with** its literal: it is part of it, and in
    // the preset survey (#9) four of ten coloured escape the same as number.
    // So it uses the same value as [string].
    escape: _towards(scheme.onSurfaceVariant, scheme.tertiary),
    // Starts from the body and pulls towards the app's `primary`. **9/9** of
    // the surveyed themes colour call names differently, and this palette
    // alone was leaving it empty.
    function: _towards(scheme.onSurface, scheme.primary),
    punctuation: TextStyle(color: scheme.outline),
  );

  // ───────────────────────────────────────────────────────────────────────
  // Named presets
  //
  // **An excerpt, not a reproduction.** The upstream themes assign colours to
  // tens to hundreds of TextMate scopes, and this package has eight kinds.
  // Each preset pulls out the colours the upstream gave to the scopes that
  // match those eight, so it does not look identical to the original editor.
  //
  // Values and sources are in `syntax_presets.dart` and `NOTICES`.
  //
  // Each preset carries its own [background], and the colours were chosen
  // **on that background**. Measured (2026-09-07, contrast ratio of body text
  // against its own background): 4.13 (solarizedLight) to 13.94 (monokai);
  // all ten are 4.1 or above.
  //
  // An earlier version of this paragraph claimed the opposite: *"at the
  // opposite brightness it does not just break, it is invisible"*, noting that
  // `cobalt2`'s body text `#FFFFFF` has a contrast ratio of **1.00**. **That
  // figure is still correct; what it measured was wrong.** 1.00 was white body
  // text measured against *the app's* light surface. The palette carried no
  // background, so there was nothing else to measure against, and that
  // absence read like a property of the preset. Measured against its own
  // background, `#193549`, it is **12.75**.
  //
  // So the reason for shipping pairs changes too. It is not legibility but
  // **brightness preference**: put `oneDark` on a light app and it reads
  // fine, but the code block alone is dark. There has to be a choice.
  //
  // The default is still **not** one of these. Only
  // [SyntaxPalette.fromColorScheme] keeps the app's surface as the
  // background, so the code block does not look foreign in the app.
  //
  // There is no lookup by name. A consumer who wants to let users pick a
  // preset writes their own list; that is the decision not to build a
  // registry.
  // ───────────────────────────────────────────────────────────────────────

  /// Colours **excerpted** from Solarized Dark. Not a reproduction.
  static const solarizedDark = _solarizedDark;

  /// Colours **excerpted** from Solarized Light. Not a reproduction.
  static const solarizedLight = _solarizedLight;

  /// Colours **excerpted** from One Dark. Not a reproduction.
  ///
  /// It is not named `atomOneDark` because `ATOM` is a GitHub trademark. The
  /// values come from `atom/one-dark-syntax`, and that file is MIT-licensed:
  /// **licence and trademark are separate axes, and MIT does not grant
  /// trademark rights.**
  ///
  /// That trademark finding was cross-checked on 2026-09-07: US Reg.
  /// 4,819,136, GitHub, Inc., Class 009, whose listed goods are *"downloadable
  /// software for developing and editing software"*, which directly covers a
  /// code editor. **The sources, though, were two public mirrors, not the
  /// original register.** `NOTICES` carries that caveat.
  static const oneDark = _oneDark;

  /// Colours **excerpted** from One Light. Not a reproduction.
  static const oneLight = _oneLight;

  /// Colours **excerpted** from Monokai. Not a reproduction.
  ///
  /// The only preset whose comments are not italic, because the original's
  /// are not. `escape` sharing `number`'s colour is also as in the original:
  /// this theme has no dedicated rule for `constant.character.escape`, so it
  /// is absorbed into the parent `constant` rule.
  static const monokai = _monokai;

  /// Colours **excerpted** from Gruvbox Dark. Not a reproduction.
  ///
  /// The values come from an MIT port, not the canonical Vim version:
  /// `morhetz/gruvbox` has no LICENSE file and no copyright-holder statement,
  /// so there is no original text to copy into `NOTICES`. The price was
  /// fidelity in two slots: the port absorbs `escape` into the `constant` rule
  /// and colours functions yellow, whereas the canonical version gives escapes
  /// their own orange and makes functions green and bold. **The two sets of
  /// values were not mixed**: mixing them would make a palette that exists
  /// nowhere.
  static const gruvboxDark = _gruvboxDark;

  /// Colours **excerpted** from Gruvbox Light. Not a reproduction. See
  /// [gruvboxDark].
  static const gruvboxLight = _gruvboxLight;

  /// Colours **excerpted** from Tokyo Night. Not a reproduction.
  static const tokyoNight = _tokyoNight;

  /// Colours **excerpted** from Tokyo Night Light. Not a reproduction.
  ///
  /// This preset's `escape` (`#363C4D`) is barely distinguishable by eye from
  /// the body text (`#343B59`). **The original defines it that way, and there
  /// are no grounds to fix it by guess, so it ships as is.**
  static const tokyoNightLight = _tokyoNightLight;

  /// Colours **excerpted** from Cobalt2. Not a reproduction.
  static const cobalt2 = _cobalt2;

  /// The colour painted behind the code area. If null, nothing is painted.
  ///
  /// **It is not a kind.** The other eight decide how to draw the characters
  /// of a span; this decides the place those characters sit on. So it is not
  /// part of the exhaustive `switch` in [styleFor], and adding this field was
  /// not a breaking change, unlike adding a value to [DartTokenKind].
  ///
  /// **The derived default does not give it.** For
  /// [SyntaxPalette.fromColorScheme], the right background is the surface the
  /// app has already painted, and not laying its own colour on top is exactly
  /// what "hue-neutral" means. Named presets are the opposite: their colours
  /// were chosen on a particular background, so carrying them over without it
  /// loses the contrast the original set.
  final Color? background;

  /// Identifiers, whitespace, and everything not otherwise classified.
  final TextStyle? plain;

  /// From `//` to the end of the line, and `/* */` including nested pairs.
  final TextStyle? comment;

  /// Reserved words, built-in identifiers and contextual keywords.
  final TextStyle? keyword;

  /// The parts of a string literal not cut out by [escape] or interpolation.
  final TextStyle? string;

  /// Integer, floating-point and hexadecimal literals.
  final TextStyle? number;

  /// Brackets, operators and separators.
  final TextStyle? punctuation;

  /// Escape sequences inside strings.
  final TextStyle? escape;

  /// The identifier immediately before an opening parenthesis.
  final TextStyle? function;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyntaxPalette &&
          background == other.background &&
          plain == other.plain &&
          comment == other.comment &&
          keyword == other.keyword &&
          string == other.string &&
          number == other.number &&
          punctuation == other.punctuation &&
          escape == other.escape &&
          function == other.function;

  @override
  int get hashCode => Object.hash(
    background,
    plain,
    comment,
    keyword,
    string,
    number,
    punctuation,
    escape,
    function,
  );

  /// How to draw [kind]. If null, the root style is used as is.
  ///
  /// Being an exhaustive `switch` is intentional. If a value is added to
  /// [DartTokenKind], **this function stops compiling.**
  ///
  /// ADR-0001 called that list *"effectively permanent"*: once published,
  /// changing it is a breaking change because consumers' exhaustive `switch`es
  /// break, so it was fixed at the point the survey gave grounds. The compile
  /// error here is not permission to reopen that door, but a device that makes
  /// a noise when someone tries to.
  TextStyle? styleFor(DartTokenKind kind) => switch (kind) {
    DartTokenKind.plain => plain,
    DartTokenKind.comment => comment,
    DartTokenKind.keyword => keyword,
    DartTokenKind.string => string,
    DartTokenKind.number => number,
    DartTokenKind.punctuation => punctuation,
    DartTokenKind.escape => escape,
    DartTokenKind.function => function,
  };
}
