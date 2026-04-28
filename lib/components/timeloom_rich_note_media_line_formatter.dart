import 'package:flutter/services.dart';
import 'timeloom_rich_note_controller.dart';
import 'timeloom_rich_note_tokens.dart';
class RichNoteMediaLineFormatter extends TextInputFormatter {
  const RichNoteMediaLineFormatter();
  static bool _isFullMediaLine(String line) {
    final t = line.trim();
    if (t.isEmpty) return false;
    return reRichNoteImageLine.hasMatch(t) ||
        reRichNoteFileLine.hasMatch(t) ||
        reRichNoteVoiceLine.hasMatch(t);
  }
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
    if (!oldValue.selection.isCollapsed) {
      return newValue;
    }
    final insertAt = oldValue.selection.baseOffset;
    if (insertAt < 0 || insertAt > old.length) {
      return newValue;
    }
    if (insertAt >= novel.length || novel[insertAt] != '\n') {
      return newValue;
    }
    final lineStart = richNoteLineStartInText(old, insertAt);
    final lineEnd = richNoteLineEndInText(old, insertAt);
    final line = old.substring(lineStart, lineEnd);
    if (!_isFullMediaLine(line)) {
      return newValue;
    }
    if (insertAt <= lineStart || insertAt >= lineEnd) {
      return newValue;
    }
    final nextText = '${old.substring(0, lineEnd)}\n${old.substring(lineEnd)}';
    final selEnd = lineEnd + 1;
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
