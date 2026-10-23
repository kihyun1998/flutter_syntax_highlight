/// The public entry point of a two-layer package that draws Dart source with
/// syntax highlighting.
///
/// The layers are divided by a single **seam**: the **tokenizer** decides
/// *what* a kind is, and the **widget** decides *how* a kind looks. The moment
/// the tokenizer knows about `Color`, the two layers are welded together, and
/// then nothing can be verified without rendering.
///
/// What the tokenizer returns is a **partition**: concatenating the tokens'
/// text gives back the input, byte for byte. The terms are in `GLOSSARY.md`,
/// and the grounds for the list of kinds are in
/// `docs/adr/0001-token-kinds-are-lexical-only.md`.
///
/// If you only need the lower layer, use [tokenizeDart] on its own.
library;

export 'src/tokenizer/dart_tokenizer.dart';
export 'src/widget/syntax_palette.dart';
export 'src/widget/syntax_text.dart';

// The type `SyntaxText.wheelMotion` takes. Exported so this one import is
// enough to use it.
export 'package:flutter_smooth_wheel_scroll/flutter_smooth_wheel_scroll.dart'
    show WheelMotion;
