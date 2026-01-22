import 'dart:io';
import 'package:termio/termio.dart';

/// Simple demo showing how to detect Ctrl-S for save functionality
void main() {
  final terminal = Terminal();
  terminal.rawMode = true;
  terminal.flowControl = false; // Required to detect Ctrl-S

  print('Text Editor Demo');
  print('================');
  print('Type anything, press Ctrl-S to "save", Ctrl-C to exit\n');

  var unsavedChanges = false;

  terminal.inputEvents.listen((event) {
    if (event is KeyInputEvent) {
      if (event.raw == Keys.ctrlS) {
        // Handle save
        print('\n💾 Saved!');
        unsavedChanges = false;
      } else {
        // Any other key = unsaved changes
        terminal.write(event.key);
        unsavedChanges = true;
      }
    }
  });

  terminal.interrupt.listen((_) {
    terminal.rawMode = false;
    terminal.flowControl = true;

    if (unsavedChanges) {
      print('\n⚠️  You have unsaved changes!');
    }
    print('Exiting...');
    exit(0);
  });
}
