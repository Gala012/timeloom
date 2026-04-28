import 'package:flutter/services.dart';
import 'timeloom_rich_note_controller.dart';
class RichNoteListContinuationFormatter extends TextInputFormatter {
  const RichNoteListContinuationFormatter();
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final old = oldValue.text;
    final novel = newValue.text;
    if (novel.length != old.length + 1) {
      return newValue;
    }
    int? insertAt;
    for (var k = 0; k <= old.length; k++) {
      if ('${old.substring(0, k)}\n${old.substring(k)}' == novel) {
        insertAt = k;
        break;
      }
    }
    if (insertAt == null) {
      return newValue;
    }
    final lineStart = richNoteLineStartInText(old, insertAt);
    final lineEnd = richNoteLineEndInText(old, insertAt);
    final line = old.substring(lineStart, lineEnd);
    final cont = listContinuationForLine(line);
    if (cont == null) {
      return newValue;
    }
    final nextText = '${old.substring(0, insertAt)}\n$cont${old.substring(insertAt)}';
    final selEnd = insertAt + 1 + cont.length;
    return TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(
        offset: selEnd,
        affinity: newValue.selection.affinity,
      ),
      composing: TextRange.empty,
    );
  }
}
