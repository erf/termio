import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:termio/termio.dart';

/// Parses raw terminal input into structured InputEvent objects.
///
/// Handles buffering of incomplete escape sequences and converts
/// raw bytes into KeyInputEvent and MouseInputEvent objects.
class InputParser {
  /// Buffer for incomplete escape sequences.
  final _buffer = StringBuffer();

  /// Parse raw input bytes and return list of complete events.
  ///
  /// Bytes are decoded as UTF-8. Incomplete escape sequences are
  /// buffered for the next call.
  List<InputEvent> parse(List<int> bytes) {
    _buffer.write(utf8.decode(bytes));
    return _extractEvents();
  }

  /// Parse input string and return list of complete events.
  ///
  /// Convenience method when input is already a string.
  /// Incomplete escape sequences are buffered for the next call.
  List<InputEvent> parseString(String input) {
    _buffer.write(input);
    return _extractEvents();
  }

  /// Check if there's buffered incomplete input.
  bool get hasBufferedInput => _buffer.isNotEmpty;

  /// Get the current buffer contents (for debugging).
  String get bufferedInput => _buffer.toString();

  /// Clear the buffer and return any pending input as events.
  ///
  /// Use this when a timeout expires to flush a lone ESC as escape key.
  List<InputEvent> flush() {
    if (_buffer.isEmpty) return [];

    final content = _buffer.toString();
    _buffer.clear();

    // If it's just ESC, return it as escape key
    if (content == Keys.escape) {
      return [KeyInputEvent(raw: content, key: 'escape')];
    }

    // Otherwise, process whatever we have grapheme by grapheme
    return content.characters.map(_graphemeToEvent).toList();
  }

  /// Extract all complete events from the buffer.
  List<InputEvent> _extractEvents() {
    final events = <InputEvent>[];
    var str = _buffer.toString();
    _buffer.clear();

    var pos = 0;
    while (pos < str.length) {
      // Check for escape sequence at current position
      if (str[pos] == '\x1b') {
        final remaining = str.substring(pos);

        // Check if this could be an incomplete sequence
        if (EscapeSequences.incompleteSequence.hasMatch(remaining)) {
          // Buffer the rest and stop processing
          _buffer.write(remaining);
          break;
        }

        // Try to match a complete sequence
        final match = EscapeSequences.completeSequence.matchAsPrefix(remaining);
        if (match != null) {
          final seq = match.group(0)!;
          events.add(_sequenceToEvent(seq));
          pos += seq.length;
          continue;
        }

        // Lone ESC not followed by sequence start - treat as escape key
        events.add(KeyInputEvent(raw: '\x1b', key: 'escape'));
        pos++;
        continue;
      }

      // Regular character: consume a full grapheme cluster (handles
      // surrogate pairs, combining marks, emoji sequences).
      final range = CharacterRange.at(str, pos);
      if (range.moveNext()) {
        events.add(_graphemeToEvent(range.current));
        pos += range.current.length;
      } else {
        pos++;
      }
    }

    return events;
  }

  /// Convert a complete escape sequence to an InputEvent.
  InputEvent _sequenceToEvent(String seq) {
    // Check for mouse sequence first
    if (EscapeSequences.mousePattern.hasMatch(seq)) {
      final mouse = MouseEvent.tryParse(seq);
      if (mouse != null) {
        return MouseInputEvent(raw: seq, event: mouse);
      }
    }

    // Check simple sequence lookup
    final simpleKey = EscapeSequences.sequenceToKey[seq];
    if (simpleKey != null) {
      return KeyInputEvent(raw: seq, key: simpleKey);
    }

    // Parse CSI sequence with potential modifiers
    if (seq.startsWith('\x1b[')) {
      return _parseCsiSequence(seq);
    }

    // Parse SS3 sequence
    if (seq.startsWith('\x1bO')) {
      return _parseSs3Sequence(seq);
    }

    // Unknown sequence - return as raw
    return KeyInputEvent(raw: seq, key: seq);
  }

  /// Parse a CSI sequence (ESC [ ...).
  KeyInputEvent _parseCsiSequence(String seq) {
    // Format: ESC [ (n ; m)? final
    // Examples: \x1b[A, \x1b[1;5A, \x1b[5~, \x1b[15;2~

    final content = seq.substring(2); // Remove ESC [
    final finalChar = content[content.length - 1];
    final params = content.substring(0, content.length - 1);

    var ctrl = false;
    var alt = false;
    var shift = false;
    String key;

    if (finalChar == '~') {
      // Tilde sequence: \x1b[5~ or \x1b[5;2~
      final parts = params.split(';');
      final keyCode = int.tryParse(parts[0]) ?? 0;
      key = EscapeSequences.csiTildeToKey[keyCode] ?? seq;

      if (parts.length > 1) {
        final mod = int.tryParse(parts[1]) ?? 1;
        final mods = EscapeSequences.modifierCodes[mod];
        if (mods != null) {
          ctrl = mods.ctrl;
          alt = mods.alt;
          shift = mods.shift;
        }
      }
    } else {
      // Letter final: \x1b[A or \x1b[1;5A
      key = EscapeSequences.csiFinalToKey[finalChar] ?? seq;

      // Special case: Z is backtab (Shift+Tab) with implicit shift
      if (finalChar == 'Z') {
        shift = true;
      }

      if (params.isNotEmpty) {
        final parts = params.split(';');
        if (parts.length > 1) {
          final mod = int.tryParse(parts[1]) ?? 1;
          final mods = EscapeSequences.modifierCodes[mod];
          if (mods != null) {
            ctrl = mods.ctrl;
            alt = mods.alt;
            shift = mods.shift;
          }
        }
      }
    }

    return KeyInputEvent(
      raw: seq,
      key: key,
      ctrl: ctrl,
      alt: alt,
      shift: shift,
    );
  }

  /// Parse an SS3 sequence (ESC O ...).
  KeyInputEvent _parseSs3Sequence(String seq) {
    final finalChar = seq[seq.length - 1];
    final key =
        EscapeSequences.csiFinalToKey[finalChar] ??
        EscapeSequences.sequenceToKey[seq] ??
        seq;
    return KeyInputEvent(raw: seq, key: key);
  }

  /// Convert a single grapheme cluster to a KeyInputEvent.
  ///
  /// Control characters are always single code units; multi-unit clusters
  /// (emoji, combining sequences) fall through to [KeyInputEvent.char].
  InputEvent _graphemeToEvent(String char) {
    // Check for control characters
    final code = char.codeUnitAt(0);

    if (code < 32) {
      // Control character
      switch (code) {
        case 0:
          return KeyInputEvent(
            raw: char,
            key: 'space',
            ctrl: true,
          ); // Ctrl+Space
        case 9:
          return KeyInputEvent(raw: char, key: 'tab');
        case 10:
        case 13:
          return KeyInputEvent(raw: char, key: 'enter');
        case 27:
          return KeyInputEvent(raw: char, key: 'escape');
        default:
          // Ctrl+letter: code 1-26 = Ctrl+A-Z
          final letter = String.fromCharCode(code + 96); // a=97, so 1+96=97
          return KeyInputEvent(raw: char, key: letter, ctrl: true);
      }
    }

    if (code == 127) {
      return KeyInputEvent(raw: char, key: 'backspace');
    }

    // Regular character
    return KeyInputEvent.char(char);
  }
}
