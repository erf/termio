import 'package:termio/termio.dart';
import 'package:test/test.dart';

void main() {
  group('Ansi tests', () {
    test('escape constant', () {
      expect(Ansi.e, '\x1b');
    });

    test('cursor', () {
      expect(Ansi.cursor(y: 1, x: 2), '\x1b[1;2H');
    });

    test('cursorVisible', () {
      expect(Ansi.cursorVisible(false), '\x1b[?25l');
      expect(Ansi.cursorVisible(true), '\x1b[?25h');
    });

    test('clearScreen', () {
      expect(Ansi.clearScreen(), '\x1b[H\x1b[J');
    });

    test('fgIndex', () {
      expect(Ansi.fgIndex(1), '\x1b[38;5;1m');
    });

    test('bgIndex', () {
      expect(Ansi.bgIndex(6), '\x1b[48;5;6m');
    });

    test('fg with Color enum', () {
      expect(Ansi.fg(Color.red), '\x1b[31m');
      expect(Ansi.fg(Color.brightRed), '\x1b[91m');
    });

    test('bg with Color enum', () {
      expect(Ansi.bg(Color.blue), '\x1b[44m');
      expect(Ansi.bg(Color.brightBlue), '\x1b[104m');
    });

    test('fgRgb', () {
      expect(Ansi.fgRgb(255, 128, 0), '\x1b[38;2;255;128;0m');
    });

    test('bgRgb', () {
      expect(Ansi.bgRgb(0, 128, 255), '\x1b[48;2;0;128;255m');
    });

    test('bold', () {
      expect(Ansi.bold(), '\x1b[1m');
    });

    test('underline', () {
      expect(Ansi.underline(), '\x1b[4m');
    });

    test('reset', () {
      expect(Ansi.reset(), '\x1b[0m');
    });

    test('combine Ansi commands', () {
      expect(Ansi.fgIndex(1) + Ansi.bgIndex(6), '\x1b[38;5;1m\x1b[48;5;6m');
      expect(
        Ansi.bold() + Ansi.underline() + Ansi.fgIndex(2),
        '\x1b[1m\x1b[4m\x1b[38;5;2m',
      );
    });

    test('cursor movement', () {
      expect(Ansi.cursorUp(), '\x1b[1A');
      expect(Ansi.cursorUp(5), '\x1b[5A');
      expect(Ansi.cursorDown(), '\x1b[1B');
      expect(Ansi.cursorRight(), '\x1b[1C');
      expect(Ansi.cursorLeft(), '\x1b[1D');
    });

    test('cursor save/restore', () {
      expect(Ansi.cursorSave(), '\x1b[s');
      expect(Ansi.cursorRestore(), '\x1b[u');
    });

    test('alt buffer', () {
      expect(Ansi.altBuffer(true), '\x1b[?1049h');
      expect(Ansi.altBuffer(false), '\x1b[?1049l');
    });

    test('alt scroll', () {
      expect(Ansi.altScroll(true), '\x1b[?1007h');
      expect(Ansi.altScroll(false), '\x1b[?1007l');
    });

    test('bracketed paste mode', () {
      expect(Ansi.bracketedPasteMode(true), '\x1b[?2004h');
      expect(Ansi.bracketedPasteMode(false), '\x1b[?2004l');
    });

    test('window title', () {
      expect(Ansi.setTitle('test'), '\x1b]2;test\x07');
    });
  });

  group('Color enum tests', () {
    test('standard colors have correct codes', () {
      expect(Color.black.code, 0);
      expect(Color.red.code, 1);
      expect(Color.white.code, 7);
    });

    test('bright colors have correct codes', () {
      expect(Color.brightBlack.code, 8);
      expect(Color.brightWhite.code, 15);
    });

    test('fg codes for standard colors', () {
      expect(Color.red.fgCode, 31);
      expect(Color.green.fgCode, 32);
    });

    test('fg codes for bright colors', () {
      expect(Color.brightRed.fgCode, 91);
      expect(Color.brightGreen.fgCode, 92);
    });

    test('bg codes for standard colors', () {
      expect(Color.red.bgCode, 41);
      expect(Color.blue.bgCode, 44);
    });

    test('bg codes for bright colors', () {
      expect(Color.brightRed.bgCode, 101);
      expect(Color.brightBlue.bgCode, 104);
    });
  });

  group('CursorStyle enum tests', () {
    test('cursor styles have correct codes', () {
      expect(CursorStyle.blinkingBlock.code, 1);
      expect(CursorStyle.steadyBlock.code, 2);
      expect(CursorStyle.blinkingBar.code, 5);
      expect(CursorStyle.steadyBar.code, 6);
    });

    test('cursorStyle generates correct escape', () {
      expect(Ansi.cursorStyle(CursorStyle.steadyBar), '\x1b[6 q');
    });
  });

  group('Mouse tracking tests', () {
    test('mouseMode enables both tracking and SGR', () {
      expect(Ansi.mouseMode(true), '\x1b[?1000h\x1b[?1006h');
      expect(Ansi.mouseMode(false), '\x1b[?1006l\x1b[?1000l');
    });

    test('mouseDrag enables drag tracking and SGR', () {
      expect(Ansi.mouseDrag(true), '\x1b[?1002h\x1b[?1006h');
      expect(Ansi.mouseDrag(false), '\x1b[?1006l\x1b[?1002l');
    });

    test('mouseAll enables all-motion tracking and SGR', () {
      expect(Ansi.mouseAll(true), '\x1b[?1003h\x1b[?1006h');
      expect(Ansi.mouseAll(false), '\x1b[?1006l\x1b[?1003l');
    });
  });
}
