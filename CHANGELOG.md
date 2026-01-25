
## 0.5.4

- add `Ansi.bracketedPasteMode(bool enabled)` for enabling/disabling bracketed paste mode
- includes unit test for bracketed paste mode

## 0.5.3+1

- fix flowControl stty command by using /dev/tty redirect

## 0.5.3

- add `flowControl` property to `Terminal` for enabling/disabling software flow control (XON/XOFF)
- allows detection of Ctrl-S and Ctrl-Q as input events
- add save_demo example showing Ctrl-S detection

## 0.5.2+1

- add tap_game example - click colorful targets before they disappear

## 0.5.2

- add Shift+Tab (backtab) support with `Keys.shiftTab`
- add modified arrow key constants (Shift, Alt, Ctrl, Ctrl+Shift)
- add modified navigation key constants (Home, End, Delete, PageUp, PageDown)
- add input_demo example for displaying parsed keyboard and mouse events

## 0.5.1+1

- dart format

## 0.5.1

- rename `KeyEvent` to `KeyInputEvent` for consistency with `MouseInputEvent`
- update all examples to use `inputEvents` stream with switch statements
- update README with new API usage

## 0.5.0

- add `InputParser` for parsing terminal input into structured events
- add `InputEvent` sealed class hierarchy with `KeyInputEvent` and `MouseInputEvent`
- add `EscapeSequences` constants for common key sequences
- add `inputEvents` stream to `Terminal` and `TestTerminal`
- update snake and sweep examples to use the new input system

## 0.4.2+1

- fix dangling library doc comment in mouse.dart

## 0.4.2

- add cursor color support (OSC 12) with `setCursorColor`, `resetCursorColor`, `queryCursorColor`

## 0.4.1

- add horizontal scroll support (left/right) to `ScrollDirection` and `MouseEvent`

## 0.4.0

- add mouse tracking support with SGR extended mode
- add `Ansi.mouseMode`, `Ansi.mouseDrag`, `Ansi.mouseAll` methods
- add `MouseEvent` class for parsing mouse events (clicks, drags, scroll)
- add mouse_demo example

## 0.3.1

- rename `alternateScroll` to `altScroll` for consistency with `altBuffer`
- improve `altScroll` documentation
- add Alt Scroll Mode demo to ansi_demo

## 0.3.0+4

- update README example

## 0.3.0+3

- simplify example.dart

## 0.3.0+2

- new comprehensive ansi_demo example
- update README

## 0.3.0+1

- improve README

## 0.3.0

- add terminal interrupt stream

## 0.2.0

- add theme detector

## 0.1.0

- initial release
