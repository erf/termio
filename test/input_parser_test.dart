import 'package:termio/termio.dart';
import 'package:test/test.dart';

void main() {
  group('InputParser', () {
    late InputParser parser;

    setUp(() {
      parser = InputParser();
    });

    group('basic characters', () {
      test('parses regular characters', () {
        final events = parser.parseString('abc');
        expect(events.length, 3);
        expect(events[0], isA<KeyInputEvent>());
        expect((events[0] as KeyInputEvent).key, 'a');
        expect((events[1] as KeyInputEvent).key, 'b');
        expect((events[2] as KeyInputEvent).key, 'c');
      });

      test('parses backspace', () {
        final events = parser.parseString('\x7f');
        expect(events.length, 1);
        expect((events[0] as KeyInputEvent).key, 'backspace');
      });

      test('parses enter (newline)', () {
        final events = parser.parseString('\n');
        expect(events.length, 1);
        expect((events[0] as KeyInputEvent).key, 'enter');
      });

      test('parses enter (carriage return)', () {
        final events = parser.parseString('\r');
        expect(events.length, 1);
        expect((events[0] as KeyInputEvent).key, 'enter');
      });

      test('parses tab', () {
        final events = parser.parseString('\t');
        expect(events.length, 1);
        expect((events[0] as KeyInputEvent).key, 'tab');
      });

      test('parses space', () {
        final events = parser.parseString(' ');
        expect(events.length, 1);
        expect((events[0] as KeyInputEvent).key, ' ');
      });
    });

    group('escape key', () {
      test('parses escape key alone', () {
        final events = parser.parseString('\x1b');
        expect(events.length, 1);
        expect((events[0] as KeyInputEvent).key, 'escape');
      });
    });

    group('arrow keys', () {
      test('parses arrow keys (CSI)', () {
        final events = parser.parseString('\x1b[A\x1b[B\x1b[C\x1b[D');
        expect(events.length, 4);
        expect((events[0] as KeyInputEvent).key, 'up');
        expect((events[1] as KeyInputEvent).key, 'down');
        expect((events[2] as KeyInputEvent).key, 'right');
        expect((events[3] as KeyInputEvent).key, 'left');
      });

      test('parses arrow keys (SS3)', () {
        final events = parser.parseString('\x1bOA\x1bOB\x1bOC\x1bOD');
        expect(events.length, 4);
        expect((events[0] as KeyInputEvent).key, 'up');
        expect((events[1] as KeyInputEvent).key, 'down');
        expect((events[2] as KeyInputEvent).key, 'right');
        expect((events[3] as KeyInputEvent).key, 'left');
      });
    });

    group('navigation keys', () {
      test('parses PageUp and PageDown', () {
        final events = parser.parseString('\x1b[5~\x1b[6~');
        expect(events.length, 2);
        expect((events[0] as KeyInputEvent).key, 'pageup');
        expect((events[1] as KeyInputEvent).key, 'pagedown');
      });

      test('parses Home and End (CSI H/F)', () {
        final events = parser.parseString('\x1b[H\x1b[F');
        expect(events.length, 2);
        expect((events[0] as KeyInputEvent).key, 'home');
        expect((events[1] as KeyInputEvent).key, 'end');
      });

      test('parses Home and End (CSI 1~/4~)', () {
        final events = parser.parseString('\x1b[1~\x1b[4~');
        expect(events.length, 2);
        expect((events[0] as KeyInputEvent).key, 'home');
        expect((events[1] as KeyInputEvent).key, 'end');
      });

      test('parses Home and End (CSI 7~/8~)', () {
        final events = parser.parseString('\x1b[7~\x1b[8~');
        expect(events.length, 2);
        expect((events[0] as KeyInputEvent).key, 'home');
        expect((events[1] as KeyInputEvent).key, 'end');
      });

      test('parses Insert and Delete', () {
        final events = parser.parseString('\x1b[2~\x1b[3~');
        expect(events.length, 2);
        expect((events[0] as KeyInputEvent).key, 'insert');
        expect((events[1] as KeyInputEvent).key, 'delete');
      });
    });

    group('function keys', () {
      test('parses F1-F4 (SS3)', () {
        final events = parser.parseString('\x1bOP\x1bOQ\x1bOR\x1bOS');
        expect(events.length, 4);
        expect((events[0] as KeyInputEvent).key, 'f1');
        expect((events[1] as KeyInputEvent).key, 'f2');
        expect((events[2] as KeyInputEvent).key, 'f3');
        expect((events[3] as KeyInputEvent).key, 'f4');
      });

      test('parses F5-F12 (CSI)', () {
        final events = parser.parseString(
          '\x1b[15~\x1b[17~\x1b[18~\x1b[19~\x1b[20~\x1b[21~\x1b[23~\x1b[24~',
        );
        expect(events.length, 8);
        expect((events[0] as KeyInputEvent).key, 'f5');
        expect((events[1] as KeyInputEvent).key, 'f6');
        expect((events[2] as KeyInputEvent).key, 'f7');
        expect((events[3] as KeyInputEvent).key, 'f8');
        expect((events[4] as KeyInputEvent).key, 'f9');
        expect((events[5] as KeyInputEvent).key, 'f10');
        expect((events[6] as KeyInputEvent).key, 'f11');
        expect((events[7] as KeyInputEvent).key, 'f12');
      });
    });

    group('control characters', () {
      test('parses Ctrl+A through Ctrl+Z', () {
        // Ctrl+A = 0x01, Ctrl+C = 0x03, etc.
        final events = parser.parseString(
          '\x01\x03\x1a',
        ); // Ctrl+A, Ctrl+C, Ctrl+Z
        expect(events.length, 3);
        expect((events[0] as KeyInputEvent).key, 'a');
        expect((events[0] as KeyInputEvent).ctrl, true);
        expect((events[1] as KeyInputEvent).key, 'c');
        expect((events[1] as KeyInputEvent).ctrl, true);
        expect((events[2] as KeyInputEvent).key, 'z');
        expect((events[2] as KeyInputEvent).ctrl, true);
      });

      test('parses Ctrl+Space', () {
        final events = parser.parseString('\x00');
        expect(events.length, 1);
        expect((events[0] as KeyInputEvent).key, 'space');
        expect((events[0] as KeyInputEvent).ctrl, true);
      });
    });

    group('modifier combinations', () {
      test('parses Shift+arrow', () {
        final events = parser.parseString('\x1b[1;2A'); // Shift+Up
        expect(events.length, 1);
        final key = events[0] as KeyInputEvent;
        expect(key.key, 'up');
        expect(key.shift, true);
        expect(key.ctrl, false);
        expect(key.alt, false);
      });

      test('parses Alt+arrow', () {
        final events = parser.parseString('\x1b[1;3A'); // Alt+Up
        expect(events.length, 1);
        final key = events[0] as KeyInputEvent;
        expect(key.key, 'up');
        expect(key.alt, true);
        expect(key.ctrl, false);
        expect(key.shift, false);
      });

      test('parses Alt+Shift+arrow', () {
        final events = parser.parseString('\x1b[1;4A'); // Alt+Shift+Up
        expect(events.length, 1);
        final key = events[0] as KeyInputEvent;
        expect(key.key, 'up');
        expect(key.alt, true);
        expect(key.shift, true);
        expect(key.ctrl, false);
      });

      test('parses Ctrl+arrow', () {
        final events = parser.parseString('\x1b[1;5A'); // Ctrl+Up
        expect(events.length, 1);
        final key = events[0] as KeyInputEvent;
        expect(key.key, 'up');
        expect(key.ctrl, true);
        expect(key.alt, false);
        expect(key.shift, false);
      });

      test('parses Ctrl+Shift+arrow', () {
        final events = parser.parseString('\x1b[1;6A'); // Ctrl+Shift+Up
        expect(events.length, 1);
        final key = events[0] as KeyInputEvent;
        expect(key.key, 'up');
        expect(key.ctrl, true);
        expect(key.shift, true);
        expect(key.alt, false);
      });

      test('parses Ctrl+Alt+arrow', () {
        final events = parser.parseString('\x1b[1;7A'); // Ctrl+Alt+Up
        expect(events.length, 1);
        final key = events[0] as KeyInputEvent;
        expect(key.key, 'up');
        expect(key.ctrl, true);
        expect(key.alt, true);
        expect(key.shift, false);
      });

      test('parses Ctrl+Alt+Shift+arrow', () {
        final events = parser.parseString('\x1b[1;8A'); // Ctrl+Alt+Shift+Up
        expect(events.length, 1);
        final key = events[0] as KeyInputEvent;
        expect(key.key, 'up');
        expect(key.ctrl, true);
        expect(key.alt, true);
        expect(key.shift, true);
      });

      test('parses Ctrl+PageUp', () {
        final events = parser.parseString('\x1b[5;5~'); // Ctrl+PageUp
        expect(events.length, 1);
        final key = events[0] as KeyInputEvent;
        expect(key.key, 'pageup');
        expect(key.ctrl, true);
      });

      test('parses Shift+Delete', () {
        final events = parser.parseString('\x1b[3;2~'); // Shift+Delete
        expect(events.length, 1);
        final key = events[0] as KeyInputEvent;
        expect(key.key, 'delete');
        expect(key.shift, true);
      });

      test('parses Ctrl+F5', () {
        final events = parser.parseString('\x1b[15;5~'); // Ctrl+F5
        expect(events.length, 1);
        final key = events[0] as KeyInputEvent;
        expect(key.key, 'f5');
        expect(key.ctrl, true);
      });

      test('parses Shift+F1 (CSI format)', () {
        final events = parser.parseString('\x1b[1;2P'); // Shift+F1
        expect(events.length, 1);
        final key = events[0] as KeyInputEvent;
        expect(key.key, 'f1');
        expect(key.shift, true);
      });

      test('parses Shift+Tab (backtab)', () {
        final events = parser.parseString('\x1b[Z'); // Shift+Tab
        expect(events.length, 1);
        final key = events[0] as KeyInputEvent;
        expect(key.key, 'tab');
        expect(key.shift, true);
        expect(key.ctrl, false);
        expect(key.alt, false);
      });
    });

    group('buffering', () {
      test('buffers incomplete CSI sequence', () {
        var events = parser.parseString('\x1b[');
        expect(events.isEmpty, true);
        expect(parser.hasBufferedInput, true);

        events = parser.parseString('A');
        expect(events.length, 1);
        expect((events[0] as KeyInputEvent).key, 'up');
        expect(parser.hasBufferedInput, false);
      });

      test('buffers incomplete SS3 sequence', () {
        var events = parser.parseString('\x1bO');
        expect(events.isEmpty, true);
        expect(parser.hasBufferedInput, true);

        events = parser.parseString('A');
        expect(events.length, 1);
        expect((events[0] as KeyInputEvent).key, 'up');
      });

      test('buffers incomplete CSI with params', () {
        var events = parser.parseString('\x1b[1;5');
        expect(events.isEmpty, true);
        expect(parser.hasBufferedInput, true);

        events = parser.parseString('A');
        expect(events.length, 1);
        final key = events[0] as KeyInputEvent;
        expect(key.key, 'up');
        expect(key.ctrl, true);
      });

      test('buffers incomplete mouse sequence', () {
        var events = parser.parseString('\x1b[<0;10');
        expect(events.isEmpty, true);
        expect(parser.hasBufferedInput, true);

        events = parser.parseString(';5M');
        expect(events.length, 1);
        expect(events[0], isA<MouseInputEvent>());
      });

      test('flush returns buffered as escape', () {
        parser.parseString('\x1b[');
        final events = parser.flush();
        expect(events.length, 2); // ESC and [
        expect(parser.hasBufferedInput, false);
      });
    });

    group('mixed input', () {
      test('parses mixed characters and sequences', () {
        final events = parser.parseString('a\x1b[Ab');
        expect(events.length, 3);
        expect((events[0] as KeyInputEvent).key, 'a');
        expect((events[1] as KeyInputEvent).key, 'up');
        expect((events[2] as KeyInputEvent).key, 'b');
      });

      test('parses multiple sequences in one input', () {
        final events = parser.parseString('\x1b[A\x1b[B\x1b[1;5C');
        expect(events.length, 3);
        expect((events[0] as KeyInputEvent).key, 'up');
        expect((events[1] as KeyInputEvent).key, 'down');
        final key = events[2] as KeyInputEvent;
        expect(key.key, 'right');
        expect(key.ctrl, true);
      });
    });

    group('mouse events', () {
      test('parses mouse click', () {
        final events = parser.parseString('\x1b[<0;10;5M');
        expect(events.length, 1);
        expect(events[0], isA<MouseInputEvent>());
        final mouse = (events[0] as MouseInputEvent).event;
        expect(mouse.x, 10);
        expect(mouse.y, 5);
      });

      test('parses mouse release', () {
        final events = parser.parseString('\x1b[<0;10;5m');
        expect(events.length, 1);
        expect(events[0], isA<MouseInputEvent>());
      });
    });

    group('raw sequence preservation', () {
      test('preserves raw sequence for binding matching', () {
        final events = parser.parseString('\x1b[A');
        expect(events.length, 1);
        expect((events[0] as KeyInputEvent).raw, '\x1b[A');
      });

      test('raw matches Keys constants', () {
        final events = parser.parseString(Keys.arrowUp);
        expect(events.length, 1);
        expect((events[0] as KeyInputEvent).raw, Keys.arrowUp);
      });

      test('Ctrl character raw is preserved', () {
        final events = parser.parseString('\x01'); // Ctrl+A
        expect(events.length, 1);
        expect((events[0] as KeyInputEvent).raw, '\x01');
      });
    });

    group('unicode characters', () {
      test('parses accented characters', () {
        final events = parser.parseString('café');
        expect(events.length, 4);
        expect((events[0] as KeyInputEvent).key, 'c');
        expect((events[1] as KeyInputEvent).key, 'a');
        expect((events[2] as KeyInputEvent).key, 'f');
        expect((events[3] as KeyInputEvent).key, 'é');
      });

      test('parses emoji (surrogate pair) as single event', () {
        // Emoji are surrogate pairs in UTF-16, but must arrive as ONE event
        final events = parser.parseString('👍');
        expect(events.length, 1);
        expect((events[0] as KeyInputEvent).key, '👍');
      });

      test('parses CJK characters', () {
        final events = parser.parseString('日本');
        expect(events.length, 2);
        expect((events[0] as KeyInputEvent).key, '日');
        expect((events[1] as KeyInputEvent).key, '本');
      });

      test('parses UTF-8 bytes for accented character', () {
        // 'é' in UTF-8 is [0xC3, 0xA9]
        final events = parser.parse([0xC3, 0xA9]);
        expect(events.length, 1);
        expect((events[0] as KeyInputEvent).key, 'é');
      });

      test('parses UTF-8 bytes for emoji as single event', () {
        // '👍' in UTF-8 is [0xF0, 0x9F, 0x91, 0x8D]
        final events = parser.parse([0xF0, 0x9F, 0x91, 0x8D]);
        expect(events.length, 1);
        expect((events[0] as KeyInputEvent).key, '👍');
      });

      test('parses combining character sequence as single event', () {
        // 'e' + combining acute accent (U+0301) = one grapheme cluster
        final events = parser.parseString('e\u0301');
        expect(events.length, 1);
        expect((events[0] as KeyInputEvent).key, 'e\u0301');
      });

      test('parses multi-codepoint emoji sequence as single event', () {
        // Family emoji: ZWJ sequence of multiple code points
        const family = '👨‍👩‍👧';
        final events = parser.parseString(family);
        expect(events.length, 1);
        expect((events[0] as KeyInputEvent).key, family);
      });

      test('flush emits lone buffered escape as escape key', () {
        // An incomplete CSI sequence is buffered; flushing returns its chars
        parser.parseString('\x1b[');
        final events = parser.flush();
        expect(events.length, 2);
        expect((events[0] as KeyInputEvent).key, 'escape');
        expect((events[1] as KeyInputEvent).key, '[');
      });

      test('lone ESC is emitted immediately, not buffered', () {
        final events = parser.parseString('\x1b');
        expect(events.length, 1);
        expect((events[0] as KeyInputEvent).key, 'escape');
        expect(parser.hasBufferedInput, isFalse);
      });

      test('parses mixed ASCII and unicode', () {
        final events = parser.parseString('hello 世界!');
        expect(events.length, 9);
        expect((events[5] as KeyInputEvent).key, ' ');
        expect((events[6] as KeyInputEvent).key, '世');
        expect((events[7] as KeyInputEvent).key, '界');
        expect((events[8] as KeyInputEvent).key, '!');
      });

      test('parses unicode mixed with escape sequences', () {
        final events = parser.parseString('é\x1b[Aü');
        expect(events.length, 3);
        expect((events[0] as KeyInputEvent).key, 'é');
        expect((events[1] as KeyInputEvent).key, 'up');
        expect((events[2] as KeyInputEvent).key, 'ü');
      });
    });
  });
}
