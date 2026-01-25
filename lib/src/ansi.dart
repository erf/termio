import 'dart:convert';

/// ANSI escape codes for terminal control.
///
/// ANSI refers to ECMA-48/ISO 6429 escape sequences, commonly called
/// "ANSI codes". This class provides methods for cursor control, colors,
/// text styles, and terminal modes.
///
/// All methods return escape code strings that can be written to the terminal.
class Ansi {
  Ansi._();

  /// Escape character.
  static const e = '\x1b';

  /// Bell character.
  static const bell = '\x07';

  // ─────────────────────────────────────────────────────────────────────────
  // Cursor
  // ─────────────────────────────────────────────────────────────────────────

  /// Move cursor to position (x, y).
  ///
  /// Coordinates are 1-based (top-left is 1,1).
  static String cursor({required int x, required int y}) => '$e[$y;${x}H';

  /// Show or hide the cursor.
  static String cursorVisible(bool visible) => visible ? '$e[?25h' : '$e[?25l';

  /// Clear screen and move cursor home.
  static String clearScreen() => '$e[H$e[J';

  /// Save cursor position.
  static String cursorSave() => '$e[s';

  /// Restore cursor position.
  static String cursorRestore() => '$e[u';

  /// Move cursor up by [n] lines.
  static String cursorUp([int n = 1]) => '$e[${n}A';

  /// Move cursor down by [n] lines.
  static String cursorDown([int n = 1]) => '$e[${n}B';

  /// Move cursor right by [n] columns.
  static String cursorRight([int n = 1]) => '$e[${n}C';

  /// Move cursor left by [n] columns.
  static String cursorLeft([int n = 1]) => '$e[${n}D';

  /// Set cursor style.
  static String cursorStyle(CursorStyle style) => '$e[${style.code} q';

  /// Reset cursor style to terminal default.
  static String cursorReset() => '$e[ q';

  // ─────────────────────────────────────────────────────────────────────────
  // Colors - Standard 16 colors
  // ─────────────────────────────────────────────────────────────────────────

  /// Set foreground to a standard [Color].
  static String fg(Color color) => '$e[${color.fgCode}m';

  /// Set background to a standard [Color].
  static String bg(Color color) => '$e[${color.bgCode}m';

  // ─────────────────────────────────────────────────────────────────────────
  // Colors - 256-color palette
  // ─────────────────────────────────────────────────────────────────────────

  /// Set foreground color using 256-color palette index.
  ///
  /// Color ranges:
  /// - 0-7: Standard colors
  /// - 8-15: High-intensity (bright) colors
  /// - 16-231: 6×6×6 color cube
  /// - 232-255: Grayscale ramp
  static String fgIndex(int color) => '$e[38;5;${color}m';

  /// Set background color using 256-color palette index.
  ///
  /// See [fgIndex] for color ranges.
  static String bgIndex(int color) => '$e[48;5;${color}m';

  // ─────────────────────────────────────────────────────────────────────────
  // Colors - 24-bit truecolor
  // ─────────────────────────────────────────────────────────────────────────

  /// Set foreground color using 24-bit RGB.
  ///
  /// Supported by most modern terminals (iTerm2, Windows Terminal, kitty,
  /// Alacritty, VS Code terminal, etc.).
  static String fgRgb(int r, int g, int b) => '$e[38;2;$r;$g;${b}m';

  /// Set background color using 24-bit RGB.
  ///
  /// See [fgRgb] for terminal support.
  static String bgRgb(int r, int g, int b) => '$e[48;2;$r;$g;${b}m';

  // ─────────────────────────────────────────────────────────────────────────
  // Text styles
  // ─────────────────────────────────────────────────────────────────────────

  /// Enable bold text.
  static String bold() => '$e[1m';

  /// Enable dim/faint text.
  static String dim() => '$e[2m';

  /// Enable italic text.
  static String italic() => '$e[3m';

  /// Enable underlined text.
  static String underline() => '$e[4m';

  /// Enable blinking text.
  static String blink() => '$e[5m';

  /// Enable or disable inverse/reverse video (swap foreground and background).
  static String inverse(bool enabled) => enabled ? '$e[7m' : '$e[27m';

  /// Enable strikethrough text.
  static String strikethrough() => '$e[9m';

  /// Reset all text styles and colors.
  static String reset() => '$e[0m';

  // ─────────────────────────────────────────────────────────────────────────
  // Terminal modes
  // ─────────────────────────────────────────────────────────────────────────

  /// Enable or disable alternative screen buffer.
  ///
  /// The alternative buffer is a separate screen that doesn't affect the
  /// main scrollback. Use for full-screen applications.
  static String altBuffer(bool enabled) => enabled ? '$e[?1049h' : '$e[?1049l';

  /// Enable or disable alternate scroll mode (mode 1007).
  ///
  /// When enabled, the mouse scroll wheel sends arrow key escape sequences
  /// (`\x1b[A` for up, `\x1b[B` for down) instead of scrolling the terminal's
  /// scrollback buffer. Typically used with [altBuffer] in full-screen apps
  /// where scrollback is hidden.
  static String altScroll(bool enabled) => enabled ? '$e[?1007h' : '$e[?1007l';

  /// Enable or disable grapheme cluster mode (mode 2027).
  ///
  /// Improves handling of complex Unicode characters like emoji.
  static String graphemeCluster(bool enabled) =>
      enabled ? '$e[?2027h' : '$e[?2027l';

  /// Enable or disable bracketed paste mode.
  ///
  /// When enabled, the terminal wraps pasted text with escape sequences:
  /// - `\x1b[200~` at the start of pasted content
  /// - `\x1b[201~` at the end of pasted content
  ///
  /// This allows applications to distinguish pasted text from typed input.
  static String bracketedPasteMode(bool enabled) =>
      enabled ? '$e[?2004h' : '$e[?2004l';

  // ─────────────────────────────────────────────────────────────────────────
  // Mouse tracking
  // ─────────────────────────────────────────────────────────────────────────

  /// Enable or disable mouse tracking with SGR extended mode.
  ///
  /// When enabled, mouse button press and release events are reported as
  /// escape sequences that can be parsed with [MouseEvent.tryParse].
  ///
  /// Uses SGR extended encoding (mode 1006) which supports coordinates
  /// beyond column 223 and is supported by all modern terminals.
  ///
  /// **Note:** When mouse tracking is enabled, scroll wheel events will be
  /// reported as mouse events instead of scrolling the terminal buffer.
  ///
  /// Example:
  /// ```dart
  /// terminal.write(Ansi.mouseMode(true));  // Enable tracking
  /// // ... handle mouse events ...
  /// terminal.write(Ansi.mouseMode(false)); // Disable on exit
  /// ```
  static String mouseMode(bool enabled) =>
      enabled ? '$e[?1000h$e[?1006h' : '$e[?1006l$e[?1000l';

  /// Enable or disable drag tracking with SGR extended mode.
  ///
  /// Reports mouse movement while a button is held (drag events),
  /// in addition to press/release. Generates more events than [mouseMode].
  static String mouseDrag(bool enabled) =>
      enabled ? '$e[?1002h$e[?1006h' : '$e[?1006l$e[?1002l';

  /// Enable or disable all-motion tracking with SGR extended mode.
  ///
  /// Reports all mouse movement, even without buttons pressed.
  /// Use sparingly as this generates many events.
  static String mouseAll(bool enabled) =>
      enabled ? '$e[?1003h$e[?1006h' : '$e[?1006l$e[?1003l';

  // ─────────────────────────────────────────────────────────────────────────
  // Window title
  // ─────────────────────────────────────────────────────────────────────────

  /// Set the terminal window title.
  static String setTitle(String title) => '$e]2;$title$bell';

  /// Push current window title onto the stack.
  static String pushTitle() => '$e[22;2t';

  /// Pop and restore window title from the stack.
  static String popTitle() => '$e[23;2t';

  // ─────────────────────────────────────────────────────────────────────────
  // Clipboard (OSC 52)
  // ─────────────────────────────────────────────────────────────────────────

  /// Copy text to system clipboard using OSC 52.
  ///
  /// **Security note:** OSC 52 clipboard access may be disabled or restricted
  /// in some terminals for security reasons. Not all terminals support this
  /// feature.
  ///
  /// Supported by: iTerm2, kitty, Alacritty, Windows Terminal, tmux (with
  /// configuration), and others.
  static String copyToClipboard(String text) =>
      '$e]52;c;${base64Encode(utf8.encode(text))}$bell';

  /// Query clipboard contents using OSC 52.
  ///
  /// **Security note:** Most terminals disable clipboard reading for security.
  /// The terminal will respond with the clipboard contents if permitted.
  static String queryClipboard() => '$e]52;c;?$bell';

  // ─────────────────────────────────────────────────────────────────────────
  // Cursor color (OSC 12)
  // ─────────────────────────────────────────────────────────────────────────

  /// Set the cursor color using OSC 12.
  ///
  /// The [color] parameter can be:
  /// - A color name: `"red"`, `"blue"`, `"green"`, etc.
  /// - A hex color: `"#RGB"`, `"#RRGGBB"`, `"#RRRRGGGGBBBB"`
  /// - An RGB spec: `"rgb:RR/GG/BB"` or `"rgb:RRRR/GGGG/BBBB"`
  ///
  /// Example:
  /// ```dart
  /// terminal.write(Ansi.setCursorColor('#ff0000'));  // Red cursor
  /// terminal.write(Ansi.setCursorColor('green'));    // Green cursor
  /// ```
  static String setCursorColor(String color) => '$e]12;$color$bell';

  /// Reset the cursor color to the terminal default using OSC 112.
  static String resetCursorColor() => '$e]112$bell';

  /// Query the current cursor color (OSC 12).
  ///
  /// The terminal will respond with the current cursor color.
  static String queryCursorColor() => '$e]12;?$e\\';

  // ─────────────────────────────────────────────────────────────────────────
  // Query
  // ─────────────────────────────────────────────────────────────────────────

  /// Query terminal background color (OSC 11).
  ///
  /// The terminal will respond with the current background color.
  static String queryBackgroundColor() => '$e]11;?$e\\';
}

/// Standard 16 terminal colors.
///
/// These are the basic ANSI colors supported by virtually all terminals.
/// Colors 0-7 are the standard colors, and 8-15 are bright/high-intensity
/// variants.
enum Color {
  black(0),
  red(1),
  green(2),
  yellow(3),
  blue(4),
  magenta(5),
  cyan(6),
  white(7),
  brightBlack(8),
  brightRed(9),
  brightGreen(10),
  brightYellow(11),
  brightBlue(12),
  brightMagenta(13),
  brightCyan(14),
  brightWhite(15);

  const Color(this.code);

  /// The 256-color palette index for this color.
  final int code;

  /// ANSI foreground code for this color.
  ///
  /// Uses traditional 30-37/90-97 codes for compatibility.
  int get fgCode => code < 8 ? 30 + code : 90 + (code - 8);

  /// ANSI background code for this color.
  ///
  /// Uses traditional 40-47/100-107 codes for compatibility.
  int get bgCode => code < 8 ? 40 + code : 100 + (code - 8);
}

/// Cursor styles supported by most modern terminals.
enum CursorStyle {
  /// Blinking block cursor (default).
  blinkingBlock(1),

  /// Steady (non-blinking) block cursor.
  steadyBlock(2),

  /// Blinking underline cursor.
  blinkingUnderline(3),

  /// Steady underline cursor.
  steadyUnderline(4),

  /// Blinking bar (line) cursor.
  blinkingBar(5),

  /// Steady bar (line) cursor.
  steadyBar(6);

  const CursorStyle(this.code);

  /// The escape code parameter for this cursor style.
  final int code;
}
