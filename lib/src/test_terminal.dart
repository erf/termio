import 'dart:async';
import 'dart:io';

import 'input/input.dart';
import 'terminal.dart';

/// A mock terminal for testing purposes.
///
/// This terminal does not interact with the actual terminal. Instead,
/// it provides configurable dimensions and captures all output for
/// verification in tests.
class TestTerminal extends TerminalBase {
  /// Creates a test terminal with the specified dimensions.
  TestTerminal({this.width = 80, this.height = 24});

  @override
  final int width;

  @override
  final int height;

  bool _rawMode = false;
  bool _flowControl = true;

  @override
  bool get rawMode => _rawMode;

  @override
  set rawMode(bool value) => _rawMode = value;

  @override
  bool get flowControl => _flowControl;

  @override
  set flowControl(bool value) => _flowControl = value;

  final _inputController = StreamController<List<int>>.broadcast();
  final _resizeController = StreamController<ProcessSignal>.broadcast();
  final _interruptController = StreamController<ProcessSignal>.broadcast();

  @override
  Stream<List<int>> get input => _inputController.stream;

  final _parser = InputParser();

  @override
  late final Stream<InputEvent> inputEvents = input.expand(_parser.parse);

  @override
  Stream<ProcessSignal> get resize => _resizeController.stream;

  @override
  Stream<ProcessSignal> get interrupt => _interruptController.stream;

  /// Buffer containing all written output.
  final output = StringBuffer();

  @override
  void write(Object? object) {
    if (object != null) {
      output.write(object);
    }
  }

  /// Simulate keyboard input.
  ///
  /// The input can be a string (which will be converted to code units)
  /// or raw bytes.
  void sendInput(String input) {
    _inputController.add(input.codeUnits);
  }

  /// Simulate raw byte input.
  void sendBytes(List<int> bytes) {
    _inputController.add(bytes);
  }

  /// Simulate a terminal resize event.
  void sendResize() {
    _resizeController.add(ProcessSignal.sigwinch);
  }

  /// Simulate an interrupt (Ctrl+C) event.
  void sendInterrupt() {
    _interruptController.add(ProcessSignal.sigint);
  }

  /// Clear the output buffer.
  void clearOutput() {
    output.clear();
  }

  /// Get the output as a string and clear the buffer.
  String takeOutput() {
    final result = output.toString();
    output.clear();
    return result;
  }

  /// Close the input and resize stream controllers.
  Future<void> dispose() async {
    await _inputController.close();
    await _resizeController.close();
    await _interruptController.close();
  }
}
