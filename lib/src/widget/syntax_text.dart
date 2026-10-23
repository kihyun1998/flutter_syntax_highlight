import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smooth_wheel_scroll/flutter_smooth_wheel_scroll.dart'
    show SmoothScrollController, WheelMotion;

import '../tokenizer/dart_tokenizer.dart';
import 'syntax_palette.dart';

/// Draws Dart source with syntax highlighting. Selectable and copyable.
///
/// **It takes a source string, not an asset key.** Where the source is read
/// from is the app's concern; this widget draws the bytes already in hand. So
/// there is no loading state, and no failure screen to go with one.
///
/// ## Horizontal scrolling is not a parameter
///
/// Code does not wrap: **a wrapped line is a different line.** So horizontal
/// scrolling is not negotiable, and this widget always owns it. [scrollable]
/// governs **vertical only**: turn it off and the widget shrink-wraps
/// vertically, so it can be used like a code block inside prose; turn it on
/// and it scrolls within its own area.
///
/// Either way, this widget also owns the [ScrollController]s, by name. **The
/// reason is to give [Scrollbar] a definite thing to track**: with an unnamed
/// controller, which [Scrollable] it draws for becomes ambiguous.
///
/// The reference also recorded another reason here: that with `primary` on,
/// two scroll views claim the same [PrimaryScrollController] and the framework
/// asserts. **Measured, that is not so.** Wrapping it with `primary: true`
/// under a [PrimaryScrollController] throws no exception, and
/// `positions.length` is 1: [SelectableText] does not pass its controller to
/// its [EditableText], and that [Scrollable] never claims primary in the first
/// place. Measured 2026-09-06.
///
/// ## Horizontal cannot be dragged. That is the price of being selectable
///
/// Dragging horizontally over the text does not scroll. Vertically it does.
/// Measured (2026-09-06, 300×300 viewport, 120px drag from the viewport
/// centre):
///
/// ```
/// SelectableText         vertical 100.0   horizontal 0.0
/// SelectionArea + Text   vertical 100.0   horizontal 0.0
/// Text (not selectable)  vertical 100.0   horizontal 100.0
/// ```
///
/// **The selection gesture takes the horizontal drag.** Switching to
/// [SelectionArea] gives the same result, so it is not a problem with
/// [SelectableText] but the price of selection itself. It cannot be fixed
/// without giving up selection.
///
/// So the horizontal [Scrollbar] is not decoration but **the only horizontal
/// affordance on touch**. On desktop, the trackpad and wheel also work. Anyone
/// who wants to strip the scrollbars from this widget must read this paragraph
/// first.
///
/// **On Android, the widget turns that bar on.** Material [Scrollbar] defaults
/// `interactive` to false on Android only, and the thumb appears only while
/// scrolling and takes no hits while transparent. Since that thumb is the only
/// way to scroll horizontally, with the defaults there was no way to make it
/// appear in the first place (#29). So on Android, if the app's
/// [ScrollbarThemeData] does not set `thumbVisibility` or `interactive`, they
/// are filled with `true` for the horizontal bar only. The vertical bar is left
/// alone, because dragging scrolls it. With `interactive` on, **tapping** where
/// the bar sits also moves one page: Material [Scrollbar] cannot turn off drag
/// and track tap separately, so that was accepted as the price.
///
/// **The app's values win.** If the app theme gives `thumbVisibility: false`
/// or `interactive: false`, the widget does not change them, and then Android
/// touch users have no way to scroll horizontally. A palette that gives a
/// background also overrides only the thumb **colour** and leaves the rest of
/// the app's scrollbar theme alone (ADR-0004).
///
/// The horizontal bar sits outside the vertical scroll view, so it is drawn at
/// the bottom of the widget area regardless of `scrollable`. Both bars ignore
/// the screen inset (`MediaQuery`'s padding) and sit at the edge of the widget
/// area (#31). This widget cannot know that it sits at the very bottom of the
/// screen with its bottom edge in the system gesture area, so avoiding that is
/// the app's job ([SafeArea] and the like).
///
/// On desktop, the bar Material attaches automatically to a vertical scroll
/// view is turned off for the vertical view, because it draws the same thing
/// as the vertical bar above a second time (#32). The rest of the app's
/// [ScrollBehavior] still applies.
///
/// ## The mouse wheel glides
///
/// Both controllers are `flutter_smooth_wheel_scroll`'s
/// `SmoothScrollController`. A wheel notch does not teleport: it travels to
/// its target with [wheelMotion], and does not go past the start or end of the
/// code. Horizontal moves the same way with Shift+wheel. Because the
/// scrollbars use the same controllers as their views, the wheel rolled over a
/// scrollbar behaves the same.
///
/// Drag, scrollbar drag, keyboard and trackpad behave as with a
/// [ScrollController]. How far one notch goes is decided by the app, not this
/// widget: it is the job of `SmoothWheelBinding`, which applies app-wide.
///
/// ## The font is taken as a few numbers, not one `TextStyle`
///
/// Taking a whole [TextStyle] hands the `inherit: true` trap straight to the
/// consumer: the ambient [DefaultTextStyle] is merged in, and a style that
/// lists only fallbacks without naming a family **is drawn in the app's
/// proportional font.** Taking only the values needed, by name, keeps that gun
/// from pointing at the consumer.
///
/// Even when [fontFamily] is null, **a non-null family is always named.**
/// Reading null as "not set" would bring back the inheritance above.
///
/// The root style's colour is `ColorScheme.onSurface`. If the palette gives no
/// style for [DartTokenKind.plain], plain code is drawn in that colour: the
/// derived default actually does this, and passing a coloured palette while
/// leaving `plain` empty leaves the app theme's colour.
///
/// **A palette that gives [SyntaxPalette.background] must give `plain` too.**
/// The app theme's colour left over in that case was chosen against the app's
/// surface, and what is behind it now is not that surface. All ten shipped
/// presets give both.
///
/// ## There are no line numbers
///
/// This widget shows a snippet to paste, not a source viewer. And the natural
/// implementation of that feature is a broken one: build an inline gutter from
/// placeholder spans and, because [SelectableText] leaves
/// `includePlaceholders` at its default, **every copied line gets a
/// `\u{FFFC}`.** That the children must be [TextSpan]s is only written in the
/// docs, not asserted. The guard for it is in the tests.
class SyntaxText extends StatefulWidget {
  const SyntaxText(
    this.source, {
    super.key,
    this.palette,
    this.copyable = true,
    this.scrollable = true,
    this.fontFamily,
    this.fontFamilyFallback,
    this.fontSize = 12.5,
    this.height = 1.45,
    this.padding = const EdgeInsets.all(16),
    this.copyTooltip = 'Copy',
    this.copiedTooltip = 'Copied',
    this.wheelMotion = const WheelMotion.spring(),
  });

  /// The Dart source to draw.
  final String source;

  /// If null, `SyntaxPalette.fromColorScheme(Theme.of(context).colorScheme)`.
  final SyntaxPalette? palette;

  /// The copy overlay at the top right of the code area.
  ///
  /// **Two justifications for this button were already withdrawn in the
  /// reference.** They were "discoverability" and "making up for touch
  /// platforms", and the same measurement showed both to be wrong:
  /// `AdaptiveTextSelectionToolbar` already offers copy on Android. Written
  /// down here so they do not come back.
  ///
  /// It stays anyway, for convenience. It is not a verification device: what
  /// keeps the paste guarantee is the check that the rendered tree flattens to
  /// the original bytes, not the clipboard.
  final bool copyable;

  /// The copy button's tooltip. The default is English, so pass one in the
  /// app's language.
  final String copyTooltip;

  /// The tooltip right after copying.
  final String copiedTooltip;

  /// Governs **vertical scrolling only**. This widget always owns horizontal.
  final bool scrollable;

  /// If null, names the running platform's monospace font.
  final String? fontFamily;

  /// If null, [monoCandidates] minus the selected family.
  final List<String>? fontFamilyFallback;

  final double fontSize;
  final double height;
  final EdgeInsetsGeometry padding;

  /// How the code moves under the mouse wheel. Applies to both vertical and
  /// horizontal.
  ///
  /// The default is `WheelMotion.spring()`: it animates to where the notch
  /// points, and notches that arrive while it moves add to that target. With
  /// `null`, each notch goes immediately.
  ///
  /// ```dart
  /// wheelMotion: const WheelMotion.spring(
  ///   duration: Duration(milliseconds: 250),
  /// ),
  /// wheelMotion: null, // no animation
  /// ```
  ///
  /// Changing it keeps the scroll position and takes effect from the next
  /// notch. Only the wheel animates: drag, scrollbar drag, keyboard and
  /// trackpad move immediately and stop any motion in progress.
  ///
  /// How far one notch goes is not decided here. It applies app-wide and is
  /// set with `flutter_smooth_wheel_scroll`'s `SmoothWheelBinding`.
  final WheelMotion? wheelMotion;

  /// The monospace font for each platform.
  ///
  /// It picks one and **always names it**, because the act of naming a family
  /// is itself what pushes out inheritance from the ambient style.
  static String get defaultMonoFamily {
    if (kIsWeb) return 'monospace';
    return switch (defaultTargetPlatform) {
      TargetPlatform.macOS || TargetPlatform.iOS => 'Menlo',
      TargetPlatform.windows => 'Consolas',
      TargetPlatform.android => 'monospace',
      TargetPlatform.linux || TargetPlatform.fuchsia => 'DejaVu Sans Mono',
    };
  }

  /// Monospace font candidates, in order of how likely they are to exist.
  ///
  /// [defaultMonoFamily] picks one from this list, so using the list as is
  /// leaves the family **also being the first fallback**. That shape really
  /// did hide a bug for a long time: `fallback.first` looked like the family,
  /// so nobody noticed that no family was set at all. So what is actually
  /// passed is the list [fallbackWithout] leaves after removing the chosen
  /// family.
  static const monoCandidates = [
    'SF Mono',
    'Menlo',
    'Consolas',
    'DejaVu Sans Mono',
    'Liberation Mono',
    'monospace',
  ];

  /// [monoCandidates] without [family].
  static List<String> fallbackWithout(String family) =>
      monoCandidates.where((f) => f != family).toList(growable: false);

  @override
  State<SyntaxText> createState() => _SyntaxTextState();
}

class _SyntaxTextState extends State<SyntaxText> {
  /// Tokens are the expensive, stable side; styles are the cheap side that
  /// follows the theme.
  ///
  /// **It removes the rescan and nothing more.** [SelectableText] rebuilds its
  /// controller whenever `textSpan` compares unequal to the previous one, and
  /// [TextSpan] equality short-circuits only on `identical`: as long as
  /// [build] makes a new span per token, that deep comparison happens whether
  /// or not there is a cache.
  ///
  /// **And no test guards it.** Removing the cache and tokenizing in [build]
  /// every time draws exactly the same thing: with no observable difference,
  /// no check that can fail can be written. Counting scans would mean making
  /// the tokenizer injectable, and that seam costs more than this cache saves.
  /// Measured 2026-09-06, the largest file in this repository is 3101 tokens.
  late List<DartToken> _tokens;

  late final _vertical = SmoothScrollController(motion: _motion);
  late final _horizontal = SmoothScrollController(motion: _motion);

  /// A zero-length motion takes [ScrollController]'s own wheel path. That is
  /// why the controllers are not swapped out for `null`: swapping them loses
  /// the scroll position.
  static const _instant = WheelMotion.spring(duration: Duration.zero);

  WheelMotion get _motion => widget.wheelMotion ?? _instant;

  Timer? _confirmation;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _tokens = tokenizeDart(widget.source);
  }

  @override
  void didUpdateWidget(SyntaxText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wheelMotion != widget.wheelMotion) {
      _vertical.motion = _motion;
      _horizontal.motion = _motion;
    }
    if (oldWidget.source == widget.source) return;
    // Only the source counts. A brightness change just repaints the same
    // tokens.
    _tokens = tokenizeDart(widget.source);
    // **The confirmation belongs to the source it was shown for.** Without a
    // reset, copying A and switching to B a moment later leaves a green check
    // beside something that was never copied.
    _confirmation?.cancel();
    _copied = false;
  }

  @override
  void dispose() {
    // A timer that outlives the tree fails the test that pumped it, and that is
    // the correct behaviour, so this is not optional.
    _confirmation?.cancel();
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.source));
    setState(() => _copied = true);
    _confirmation?.cancel();
    // Finite on purpose. With an indeterminate indicator, `pumpAndSettle`
    // never settles.
    _confirmation = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = widget.palette ?? SyntaxPalette.fromColorScheme(scheme);

    final family = widget.fontFamily ?? SyntaxText.defaultMonoFamily;

    Widget code = SelectableText.rich(
      // The root span has no style of its own. `SelectableText` wraps what it
      // is given as `TextSpan(style: style, children: [what was given])`, so
      // the face below is both what every token inherits and what
      // `EditableText.style` reports.
      TextSpan(
        children: [
          for (final token in _tokens)
            TextSpan(text: token.text, style: palette.styleFor(token.kind)),
        ],
      ),
      style: TextStyle(
        fontSize: widget.fontSize,
        height: widget.height,
        fontFamily: family,
        fontFamilyFallback:
            widget.fontFamilyFallback ?? SyntaxText.fallbackWithout(family),
        color: scheme.onSurface,
      ),
    );

    code = Padding(padding: widget.padding, child: code);

    // Horizontal, always. A wrapped line is a different line.
    code = SingleChildScrollView(
      controller: _horizontal,
      scrollDirection: Axis.horizontal,
      child: code,
    );

    // Material [Scrollbar] feeds `MediaQuery.paddingOf` straight into its
    // painter, with no parameter to turn it off. That value is the **screen**'s
    // inset, but the bar is drawn inside this widget's area, so even with the
    // widget mid-screen the bar was pushed in by that much and overlapped the
    // last line (#31). The inset is removed for the bar only and given back to
    // the code inside it: the selection toolbar and handles must see the
    // screen's inset. Avoiding the inset is the app's job (ADR-0004). It is
    // read inside a [Builder] because reading it here would rebuild this whole
    // widget on every frame of the keyboard rising or falling.
    Widget insetFree(Widget Function(Widget child) bar, Widget child) =>
        Builder(
          builder: (context) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.removePadding(
                removeLeft: true,
                removeTop: true,
                removeRight: true,
                removeBottom: true,
              ),
              child: bar(MediaQuery(data: media, child: child)),
            );
          },
        );

    if (widget.scrollable) {
      // On desktop, Material attaches one more bar to every vertical
      // [Scrollable]. It draws the same controller as the bar just above, so
      // the thumb is painted twice; it is turned off for this view only, and
      // the rest of the app's [ScrollBehavior] is inherited (#32).
      // [EditableText] turns its own bar back on itself, so it is not caught
      // by this.
      code = insetFree(
        (child) => Scrollbar(controller: _vertical, child: child),
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(controller: _vertical, child: code),
        ),
      );
    }

    // Fill only what the consumer has not set (ADR-0004). These are passed as
    // parameters of the horizontal bar rather than through the theme because
    // filling them through the theme would keep the vertical bar always
    // visible too.
    final bars = ScrollbarTheme.of(context);
    final android = theme.platform == TargetPlatform.android;

    // The horizontal bar is **outside** the vertical view. Inside it, the
    // horizontal view's height is the full content height, so the bar is drawn
    // at the very end of the content and only shows once you scroll all the
    // way down.
    code = insetFree(
      (child) => Scrollbar(
        controller: _horizontal,
        notificationPredicate: (n) => n.depth == (widget.scrollable ? 1 : 0),
        thumbVisibility: android && bars.thumbVisibility == null ? true : null,
        interactive: android && bars.interactive == null ? true : null,
        child: child,
      ),
      code,
    );

    final background = palette.background;

    // Once a background is painted, this widget's own controls must follow the
    // palette too. The app theme's `onSurfaceVariant` was chosen **against the
    // app's surface**, so on someone else's background it guarantees nothing:
    // put a dark preset on a light app and the copy button and scrollbars sink
    // into that background. A palette that gives a background also gives the
    // foreground colours, so take them from it.
    final chrome = background == null
        ? scheme.onSurfaceVariant
        : palette.comment?.color ??
              palette.plain?.color ??
              scheme.onSurfaceVariant;
    final chromeStrong = background == null
        ? scheme.onSurface
        : palette.plain?.color ?? chrome;

    if (widget.copyable) {
      code = Stack(
        children: [
          code,
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              tooltip: _copied ? widget.copiedTooltip : widget.copyTooltip,
              iconSize: 17,
              visualDensity: VisualDensity.compact,
              onPressed: _copy,
              icon: Icon(
                _copied ? Icons.check : Icons.copy_all_outlined,
                color: _copied ? chromeStrong : chrome,
              ),
            ),
          ),
        ],
      );
    }

    if (background == null) return code;

    // **Outside the [Stack].** [Stack]'s default `fit` is loose, so inside it
    // the background would shrink to the size of the code content and leave
    // unpainted space in a pane wider than the code. Here it takes the parent's
    // constraints as they are: with tight constraints it fills the pane, and
    // with `scrollable: false` shrink-wrapping vertically, the background
    // shrinks with it. (Each of those two cases has a test.)
    code = ColoredBox(color: background, child: code);

    // The scrollbar is the only horizontal affordance on touch. This widget's
    // doc says so, so changing the background cannot be allowed to bury it in
    // the background. Only the colour is overridden and the app's other fields
    // are kept: themes do not merge, and only the nearest one is read.
    return ScrollbarTheme(
      data: bars.copyWith(
        thumbColor: WidgetStatePropertyAll(chrome.withAlpha(115)),
      ),
      child: code,
    );
  }
}
