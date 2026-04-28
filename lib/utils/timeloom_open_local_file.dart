import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:open_filex/open_filex.dart';
import '../components/timeloom_rich_note_tokens.dart';
import 'index.dart' show errorToast;
Future<void> openLocalFileForPreview(String rawPath) async {
  if (kIsWeb) {
    errorToast('File preview is not available here');
    return;
  }
  final resolved = richNoteResolveImagePathToFileSystem(rawPath);
  if (resolved.isEmpty) {
    errorToast('File not found');
    return;
  }
  final file = File(resolved);
  if (!file.existsSync()) {
    errorToast('File not found');
    return;
  }
  final result = await OpenFilex.open(resolved);
  if (result.type == ResultType.done) {
    return;
  }
  final msg = result.message.trim();
  if (msg.isNotEmpty) {
    errorToast(msg);
  } else {
    errorToast('Cannot open file');
  }
}
