import 'dart:io';

import 'input/input.dart';

/// Abstract base class for terminal implementations.
///
/// This allows for different terminal implementations, such as a real
/// terminal or a test terminal for unit testing.
abstract class TerminalBase {
  /// Get the current raw mode state.
  bool get rawMode;

  /// Set raw mode for terminal input.
  ///
  /// When enabled, input is unbuffered and echo is disabled.
  set rawMode(bool value);

  /// Whether software flow control (XON/XOFF) is enabled.
  ///
  /// On most Unix-like systems, this is enabled by default, which means
  /// Ctrl-S (XOFF) and Ctrl-Q (XON) may be intercepted by the terminal
  /// driver and never reach your application.
  ///
  /// The base implementation returns `true` and the setter is a no-op so
  /// custom terminal implementations are not required to implement this.
  bool get flowControl => true;

  /// Enable or disable software flow control (XON/XOFF).
  ///
  /// When enabled (default), Ctrl-S and Ctrl-Q are intercepted by the
  /// terminal for flow control and won't be received by the application.
  ///
  /// When disabled, Ctrl-S (0x13) and Ctrl-Q (0x11) will be received
  /// as normal input events, allowing you to detect them in your app.
  ///
  /// Flow control is a legacy feature from serial terminals and is
  /// rarely needed on modern systems. Disabling it is safe.
  set flowControl(bool value) {}

  /// Get width of terminal in columns.
  int get width;

  /// Get height of terminal in rows.
  int get height;

  /// Broadcast stream of raw terminal input bytes.
  Stream<List<int>> get input;

  /// Stream of parsed input events.
  ///
  /// This is a convenience stream that parses raw input bytes into
  /// structured [InputEvent] objects (keyboard and mouse events).
  Stream<InputEvent> get inputEvents;

  /// Stream of terminal resize events.
  Stream<ProcessSignal> get resize;

  /// Stream of interrupt (Ctrl+C) events.
  Stream<ProcessSignal> get interrupt;

  /// Write to the terminal output.
  void write(Object? object);
}

/// A terminal interface for reading input and writing output.
///
/// Provides access to raw mode, terminal dimensions, input streams,
/// and resize events.
class Terminal extends TerminalBase {
  bool _rawMode = false;
  bool _flowControl = true;
  final _parser = InputParser();

  @override
  bool get rawMode => _rawMode;

  @override
  set rawMode(bool value) {
    _rawMode = value;
    stdin.echoMode = !value;
    stdin.lineMode = !value;
  }

  @override
  bool get flowControl => _flowControl;

  @override
  set flowControl(bool value) {
    if (_flowControl == value) return;
    _flowControl = value;

    // Best-effort: apply terminal settings where supported.
    // - Windows: no stty/termios
    // - Non-interactive stdin (no TTY): nothing to configure
    if (Platform.isWindows || !stdin.hasTerminal) return;

    // stty toggles IXON/IXOFF (software flow control).
    final args = <String>[value ? 'ixon' : '-ixon', value ? 'ixoff' : '-ixoff'];

    try {
      Process.runSync('stty', args);
    } catch (_) {
      // Ignore: stty might be unavailable or stdin might not be configurable.
    }
  }

  @override
  int get width => stdout.terminalColumns;

  @override
  int get height => stdout.terminalLines;

  @override
  late final Stream<List<int>> input = stdin.asBroadcastStream();

  @override
  late final Stream<InputEvent> inputEvents = input.expand(_parser.parse);

  @override
  Stream<ProcessSignal> get resize => ProcessSignal.sigwinch.watch();

  @override
  Stream<ProcessSignal> get interrupt => ProcessSignal.sigint.watch();

  @override
  void write(Object? str) => stdout.write(str);
}
