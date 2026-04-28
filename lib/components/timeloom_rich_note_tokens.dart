import 'dart:convert';
import 'package:flutter/foundation.dart';
String richNoteResolveImagePathToFileSystem(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return s;
  if (s.startsWith('file:')) {
    final u = Uri.parse(s);
    if (u.isScheme('file')) {
      return u.toFilePath(windows: defaultTargetPlatform == TargetPlatform.windows);
    }
  }
  final u = Uri.tryParse(s);
  if (u != null && u.isScheme('file')) {
    return u.toFilePath(windows: defaultTargetPlatform == TargetPlatform.windows);
  }
  return s;
}
final RegExp reRichNoteImageLine = RegExp(r'^!\[\]\((.+)\)\s*$');
final RegExp reRichNoteFileLine = RegExp(r'^#FILE:(.+)\s*$');
final RegExp reRichNoteVoiceLine = RegExp(r'^#VOICE:(.+)\s*$');
@immutable
class RichNoteFileLineData {
  const RichNoteFileLineData({required this.name, required this.path});
  final String name;
  final String path;
}
@immutable
class RichNoteVoiceLineData {
  const RichNoteVoiceLineData({required this.path});
  final String path;
}
String richNoteFileLineText(String name, String path) {
  return '#FILE:${jsonEncode(<String, String>{'n': name, 'p': path})}';
}
String richNoteVoiceLineText(String path) {
  return '#VOICE:${jsonEncode(<String, String>{'p': path})}';
}
RichNoteFileLineData? parseRichNoteFileLine(String line) {
  final t = line.trim();
  final m = reRichNoteFileLine.firstMatch(t);
  if (m == null) return null;
  try {
    final o = jsonDecode(m.group(1)!);
    if (o is! Map) return null;
    final p = o['p']?.toString() ?? '';
    if (p.isEmpty) return null;
    return RichNoteFileLineData(
      name: o['n']?.toString() ?? 'File',
      path: p,
    );
  } catch (_) {
    return null;
  }
}
RichNoteVoiceLineData? parseRichNoteVoiceLine(String line) {
  final t = line.trim();
  final m = reRichNoteVoiceLine.firstMatch(t);
  if (m == null) return null;
  try {
    final o = jsonDecode(m.group(1)!);
    if (o is! Map) return null;
    final p = o['p']?.toString() ?? '';
    if (p.isEmpty) return null;
    return RichNoteVoiceLineData(path: p);
  } catch (_) {
    return null;
  }
}
String? pathFromImageMarkdownLine(String line) {
  final t = line.trim();
  final m = reRichNoteImageLine.firstMatch(t);
  if (m == null) return null;
  final s = m.group(1)!.trim();
  return richNoteResolveImagePathToFileSystem(s);
}
String richNoteImageLineText(String filePath) {
  final u = Uri.file(filePath);
  return '![]($u)';
}
String ensureHttpScheme(String url) {
  final t = url.trim();
  if (t.isEmpty) return 'https://';
  final l = t.toLowerCase();
  if (l.startsWith('http://') || l.startsWith('https://')) {
    return t;
  }
  return 'https://$t';
}
