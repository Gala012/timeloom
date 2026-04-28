import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../../components/timeloom_rich_note_controller.dart';
import '../../components/timeloom_rich_note_tokens.dart';
import '../../db_timeloom/data.dart';
import '../../db_timeloom/db_timeloom_entity.dart';
import '../../main.dart';
import '../../utils/index.dart';
import '../../utils/timeloom_open_local_file.dart';
import 'timeloom_rich_note_voice_record_sheet.dart';
class TimeloomRichNoteLogic extends GetxController {
  final toolbarGroup = 0.obs;
  final activeFormats = <String>{}.obs;
  late final RichNoteTextController contentController;
  late final FocusNode editorFocusNode;
  late final ScrollController editorScrollController;
  int? recordId;
  String _originalContent = '';
  final noteTagNames = RxList<String>();
  List<String> _originalTagNames = [];
  Future<void>? _recordLoadFuture;
  static const int _maxHistory = 50;
  final List<TextEditingValue> _undoStack = [];
  final List<TextEditingValue> _redoStack = [];
  TextEditingValue _lastHistoryValue = const TextEditingValue();
  bool _historySuspended = false;
  bool get hasUndo => _undoStack.isNotEmpty;
  TextSelection? _formatRangeFromToolbar;
  @override
  void onInit() {
    super.onInit();
    contentController = RichNoteTextController(
      onImageTap: _onImageTap,
      onFileTap: _onFileTap,
      onVoiceTap: _onVoiceTap,
    );
    editorFocusNode = FocusNode();
    editorScrollController = ScrollController();
    contentController.addListener(_syncActiveFormats);
    _lastHistoryValue = contentController.value;
    contentController.addListener(_onContentHistoryListener);
    final args = Get.arguments as Map<String, dynamic>?;
    recordId = args?['recordId'] as int?;
    if (recordId != null) _recordLoadFuture = _loadRecord();
  }
  @override
  void onClose() {
    contentController.removeListener(_syncActiveFormats);
    contentController.removeListener(_onContentHistoryListener);
    contentController.dispose();
    editorScrollController.dispose();
    editorFocusNode.dispose();
    super.onClose();
  }
  void _syncActiveFormats() {
    final s = contentController.selection;
    if (s.isValid && !s.isCollapsed) {
      _formatRangeFromToolbar = s;
    }
    final offset = s.baseOffset;
    final newFormats = contentController.getActiveFormats(offset);
    if (setEquals(newFormats, Set<String>.from(activeFormats))) {
      return;
    }
    activeFormats
      ..clear()
      ..addAll(newFormats);
    activeFormats.refresh();
  }
  void onToolbarPointerDown() {
    final s = contentController.selection;
    if (s.isValid && !s.isCollapsed) {
      _formatRangeFromToolbar = s;
    }
  }
  TextSelection _resolveFormatSelection() {
    final live = contentController.selection;
    if (!live.isCollapsed) return live;
    final c = _formatRangeFromToolbar;
    if (c != null &&
        c.isValid &&
        c.start < c.end &&
        c.end <= contentController.text.length) {
      return c;
    }
    return live;
  }
  void syncActiveFormatsFromSelection() {
    _syncActiveFormats();
  }
  Future<void> ensureRecordLoaded() async {
    final f = _recordLoadFuture;
    if (f != null) await f;
  }
  Future<void> _loadRecord() async {
    _historySuspended = true;
    try {
      final note = await DbTimeloom.to.getRichNoteRecord(recordId!);
      if (note != null) {
        contentController.text = note.content;
        _originalContent = note.content;
      }
      final tags = await DbTimeloom.to.getTagsByRecord(recordId!);
      final names = tags.map((e) => e.name).toList();
      noteTagNames.assignAll(names);
      _originalTagNames = List<String>.from(names);
    } catch (_) {
      errorToast('Failed to load note');
    } finally {
      _undoStack.clear();
      _redoStack.clear();
      _lastHistoryValue = contentController.value;
      _historySuspended = false;
      _refreshCanUndoRedo();
    }
  }
  void _refreshCanUndoRedo() {
    update(['hist']);
  }
  void _onContentHistoryListener() {
    if (_historySuspended) return;
    final now = contentController.value;
    if (now.text == _lastHistoryValue.text) {
      _lastHistoryValue = now;
      return;
    }
    _undoStack.add(_lastHistoryValue);
    while (_undoStack.length > _maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    _lastHistoryValue = now;
    _refreshCanUndoRedo();
  }
  void undo() {
    if (_undoStack.isEmpty) return;
    final target = _undoStack.removeLast();
    final current = contentController.value;
    _redoStack.add(current);
    _historySuspended = true;
    contentController.value = target;
    _lastHistoryValue = target;
    _historySuspended = false;
    _syncActiveFormats();
    _refreshCanUndoRedo();
  }
  Future<void> applyNoteTags(List<String> names) async {
    final seen = <String>{};
    final next = <String>[];
    for (final raw in names) {
      final t = raw.trim();
      if (t.isEmpty || seen.contains(t)) continue;
      seen.add(t);
      next.add(t);
    }
    noteTagNames.assignAll(next);
    if (recordId != null) {
      try {
        await DbTimeloom.to.replaceRecordTags(recordId!, noteTagNames.toList());
        _originalTagNames = List<String>.from(noteTagNames);
      } catch (_) {
        errorToast('Failed to save tags');
      }
    }
  }
  bool _tagsDifferFromOriginal() {
    if (_originalTagNames.length != noteTagNames.length) return true;
    final a = List<String>.from(_originalTagNames)..sort();
    final b = List<String>.from(noteTagNames)..sort();
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return true;
    }
    return false;
  }
  void _onImageTap(String path) {
    if (Get.context == null) return;
    if (kIsWeb) {
      errorToast('Image preview is not available here');
      return;
    }
    final resolved = richNoteResolveImagePathToFileSystem(path);
    final file = File(resolved);
    if (!file.existsSync()) {
      errorToast('Image file not found');
      return;
    }
    final ctx = Get.context!;
    final mq = MediaQuery.of(ctx);
    final maxW = mq.size.width * 0.92;
    final maxH = mq.size.height * 0.78;
    Get.dialog<void>(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(24.w),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: SizedBox(
                width: maxW,
                height: maxH,
                child: InteractiveViewer(
                  maxScale: 5.0,
                  minScale: 0.5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.w),
                    child: Image.file(
                      file,
                      fit: BoxFit.contain,
                      width: maxW,
                      height: maxH,
                      errorBuilder:
                          (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) => Container(
                            width: maxW,
                            height: 200.h,
                            color: surfaceColor,
                            alignment: Alignment.center,
                            padding: EdgeInsets.all(16.w),
                            child: Text(
                              'Cannot load image',
                              style: TextStyle(
                                color: textSecondaryColor,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16.h,
              right: 16.w,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Get.back<void>(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _onFileTap(String name, String path) {
    openLocalFileForPreview(path);
  }
  void _onVoiceTap(String path) {
    successToast('Voice: $path');
  }
  void onToolbarGroup(int index) {
    if (index < 0 || index > 1) return;
    toolbarGroup.value = index;
  }
  void onFormatText(String key) {
    final markers = _inlineMarkers(key);
    if (markers == null) return;
    final prefix = markers.$1;
    final suffix = markers.$2;
    final ctrl = contentController;
    final text = ctrl.text;
    final sel = _resolveFormatSelection();
    if (!sel.isValid) return;
    final start = sel.start;
    final end = sel.end;
    if (sel.isCollapsed) {
      if (_tryRemoveInlineAtCursor(key, prefix, suffix)) {
        _formatRangeFromToolbar = null;
        return;
      }
      final newText = text.replaceRange(start, start, '$prefix$suffix');
      ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + prefix.length),
      );
      _formatRangeFromToolbar = null;
    } else {
      final selected = text.substring(start, end);
      if (selected.startsWith(prefix) &&
          selected.endsWith(suffix) &&
          selected.length >= prefix.length + suffix.length) {
        final inner = selected.substring(
          prefix.length,
          selected.length - suffix.length,
        );
        ctrl.value = TextEditingValue(
          text: text.replaceRange(start, end, inner),
          selection: TextSelection.collapsed(offset: start + inner.length),
        );
        _formatRangeFromToolbar = null;
        return;
      }
      final newText = text.replaceRange(start, end, '$prefix$selected$suffix');
      ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: start + prefix.length + selected.length + suffix.length,
        ),
      );
      _formatRangeFromToolbar = null;
    }
  }
  bool _tryRemoveInlineAtCursor(String key, String prefix, String suffix) {
    final regex =
        _regexForInlineKey(key) ??
        RegExp(
          RegExp.escape(prefix) + r'(.*?)' + RegExp.escape(suffix),
          dotAll: true,
        );
    final ctrl = contentController;
    final text = ctrl.text;
    final cursor = ctrl.selection.baseOffset;
    final lineStart = _lineStartOf(cursor);
    final lineEnd = _lineEndOf(cursor);
    final line = text.substring(lineStart, lineEnd);
    final posInLine = cursor - lineStart;
    for (final m in regex.allMatches(line)) {
      if (m.start < posInLine && posInLine <= m.end) {
        final absStart = lineStart + m.start;
        final absEnd = lineStart + m.end;
        final inner = m.group(1) ?? '';
        final markerLen = (m.end - m.start - inner.length) ~/ 2;
        ctrl.value = TextEditingValue(
          text: text.replaceRange(absStart, absEnd, inner),
          selection: TextSelection.collapsed(
            offset:
                absStart +
                (posInLine - m.start - markerLen).clamp(0, inner.length),
          ),
        );
        return true;
      }
    }
    return false;
  }
  RegExp? _regexForInlineKey(String key) {
    switch (key) {
      case kFmtBold:
        return RichNoteTextController.reInlineBold;
      case kFmtItalic:
        return RichNoteTextController.reInlineItalic;
      case kFmtStrike:
        return RichNoteTextController.reInlineStrike;
      case kFmtHighlight:
        return RichNoteTextController.reInlineHighlight;
      case kFmtUnderline:
        return RichNoteTextController.reInlineUnderline;
      case kFmtTextColor:
        return RichNoteTextController.reInlineTextColor;
      default:
        return null;
    }
  }
  ({String p, String s})? _inlineMarkersRecord(String key) {
    switch (key) {
      case kFmtBold:
        return (p: '**', s: '**');
      case kFmtItalic:
        return (p: '*', s: '*');
      case kFmtStrike:
        return (p: '~~', s: '~~');
      case kFmtHighlight:
        return (p: '==', s: '==');
      case kFmtUnderline:
        return (p: '%%', s: '%%');
      default:
        return null;
    }
  }
  (String, String)? _inlineMarkers(String key) {
    final r = _inlineMarkersRecord(key);
    if (r == null) return null;
    return (r.p, r.s);
  }
  void onParagraphFormat(String key) {
    final newPrefix = _paragraphPrefix(key);
    if (newPrefix.isEmpty) return;
    final ctrl = contentController;
    final text = ctrl.text;
    final cursor = ctrl.selection.baseOffset;
    final lineStart = _lineStartOf(cursor);
    final lineEnd = _lineEndOf(cursor);
    final line = text.substring(lineStart, lineEnd);
    final iLen = richNoteLineIndentLength(line);
    final indent = line.substring(0, iLen);
    var rest = line.substring(iLen);
    final currentKey = RichNoteTextController.semanticKeyForLineRest(rest);
    if (currentKey == key) {
      for (final lp in _existingPrefixPatterns) {
        final m = lp.firstMatch(rest);
        if (m != null) {
          rest = rest.substring(m.group(0)!.length);
          break;
        }
      }
      final newLine = '$indent$rest';
      final newText = text.replaceRange(lineStart, lineEnd, newLine);
      final newCursor = (lineStart + newLine.length).clamp(0, newText.length);
      ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursor),
      );
      return;
    }
    for (final lp in _existingPrefixPatterns) {
      final m = lp.firstMatch(rest);
      if (m != null) {
        rest = rest.substring(m.group(0)!.length);
        break;
      }
    }
    final newLine = '$indent$newPrefix$rest';
    final newText = text.replaceRange(lineStart, lineEnd, newLine);
    final newCursor = lineStart + newLine.length;
    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }
  void onTextColorToolbarTap() {
    final ctrl = contentController;
    final sel = _resolveFormatSelection();
    if (!sel.isValid) return;
    final at = ctrl.getActiveFormats(sel.baseOffset);
    if (!at.contains(kFmtTextColor)) {
      onShowTextColorSheet();
      return;
    }
    final t = ctrl.text;
    if (sel.isCollapsed) {
      if (_tryRemoveTextColorAtCursor()) {
        _formatRangeFromToolbar = null;
        return;
      }
      onShowTextColorSheet();
      return;
    }
    final selected = t.substring(sel.start, sel.end);
    final reFull = RegExp(r'^#C\[([0-9A-Fa-f]{6})\](.*?)#C$', dotAll: true);
    if (reFull.hasMatch(selected)) {
      final m = reFull.firstMatch(selected);
      if (m != null) {
        final inner = m.group(2) ?? '';
        ctrl.value = TextEditingValue(
          text: t.replaceRange(sel.start, sel.end, inner),
          selection: TextSelection(
            baseOffset: sel.start,
            extentOffset: sel.start + inner.length,
          ),
        );
        _formatRangeFromToolbar = null;
        return;
      }
    }
    onShowTextColorSheet();
  }
  void onIndentIncrease() {
    final ctrl = contentController;
    final text = ctrl.text;
    final pos = ctrl.selection.baseOffset;
    if (!ctrl.selection.isValid || pos < 0) return;
    final lineStart = _lineStartOf(pos);
    final lineEnd = _lineEndOf(pos);
    final line = text.substring(lineStart, lineEnd);
    final level = richNoteLineIndentLength(line) ~/ 2;
    if (level >= kMaxRichNoteIndentLevel) return;
    final newLine = '  $line';
    final newText = text.replaceRange(lineStart, lineEnd, newLine);
    final newPos = pos >= lineStart ? pos + 2 : pos;
    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newPos.clamp(0, newText.length),
      ),
    );
  }
  void onIndentDecrease() {
    final ctrl = contentController;
    final text = ctrl.text;
    final pos = ctrl.selection.baseOffset;
    if (!ctrl.selection.isValid || pos < 0) return;
    final lineStart = _lineStartOf(pos);
    final lineEnd = _lineEndOf(pos);
    final line = text.substring(lineStart, lineEnd);
    final iLen = richNoteLineIndentLength(line);
    if (iLen < 2) return;
    final newLine = line.substring(2);
    final newText = text.replaceRange(lineStart, lineEnd, newLine);
    var newPos = pos;
    if (pos >= lineStart) {
      newPos = (pos - 2).clamp(lineStart, lineStart + newLine.length);
    }
    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newPos.clamp(0, newText.length),
      ),
    );
  }
  String _paragraphPrefix(String key) {
    switch (key) {
      case kFmtBullet:
        return '- ';
      case kFmtOrdered:
        return '1. ';
      case kFmtTodo:
        return '- [ ] ';
      case kFmtQuote:
        return '> ';
      case kFmtH1:
        return '# ';
      case kFmtH2:
        return '## ';
      case kFmtH3:
        return '### ';
      default:
        return '';
    }
  }
  static final _existingPrefixPatterns = [
    RegExp(r'^- \[[ xX]\] '),
    RegExp(r'^- '),
    RegExp(r'^\d+\. '),
    RegExp(r'^> '),
    RegExp(r'^### '),
    RegExp(r'^## '),
    RegExp(r'^# '),
  ];
  void onShowTextSizeSheet() {
    if (Get.context == null) {
      errorToast('Cannot open size options');
      return;
    }
    Get.bottomSheet<void>(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Large'),
                onTap: () {
                  Get.back<void>();
                  onParagraphFormat(kFmtH1);
                },
              ),
              ListTile(
                title: const Text('Medium'),
                onTap: () {
                  Get.back<void>();
                  onParagraphFormat(kFmtH2);
                },
              ),
              ListTile(
                title: const Text('Small'),
                onTap: () {
                  Get.back<void>();
                  onParagraphFormat(kFmtH3);
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: surfaceColor,
    );
  }
  void onShowTextColorSheet() {
    if (Get.context == null) {
      errorToast('Cannot open color palette');
      return;
    }
    const colors = <Color>[
      primaryColor,
      textColor,
      textSecondaryColor,
      Color(0xFFC62828),
      Color(0xFF2E7D32),
      Color(0xFF1565C0),
      Color(0xFF6A1B9A),
    ];
    Get.bottomSheet<void>(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Text color',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final c in colors)
                    Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: () {
                          final hex6 = (c.toARGB32() & 0xFFFFFF)
                              .toRadixString(16)
                              .padLeft(6, '0')
                              .toUpperCase();
                          Get.back<void>();
                          onApplyTextColor(hex6);
                        },
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(color: dividerColor),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      backgroundColor: surfaceColor,
    );
  }
  void onApplyTextColor(String hex6) {
    if (hex6.length != 6) return;
    final open = '#C[$hex6]';
    const close = '#C';
    final ctrl = contentController;
    final text = ctrl.text;
    final sel = _resolveFormatSelection();
    if (!sel.isValid) return;
    if (sel.isCollapsed) {
      if (_tryRemoveTextColorAtCursor()) {
        _formatRangeFromToolbar = null;
        return;
      }
      final start = sel.start;
      final ins = open + close;
      ctrl.value = TextEditingValue(
        text: text.replaceRange(start, start, ins),
        selection: TextSelection.collapsed(offset: start + open.length),
      );
      _formatRangeFromToolbar = null;
      return;
    }
    final start = sel.start;
    final end = sel.end;
    var selected = text.substring(start, end);
    final reFull = RegExp(r'^#C\[([0-9A-Fa-f]{6})\](.*?)#C$', dotAll: true);
    if (reFull.hasMatch(selected)) {
      final m = reFull.firstMatch(selected);
      if (m != null) {
        final inner = m.group(2) ?? '';
        ctrl.value = TextEditingValue(
          text: text.replaceRange(start, end, inner),
          selection: TextSelection(
            baseOffset: start,
            extentOffset: start + inner.length,
          ),
        );
        _formatRangeFromToolbar = null;
        return;
      }
    }
    final newText = text.replaceRange(start, end, '$open$selected$close');
    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: start + open.length + selected.length + close.length,
      ),
    );
    _formatRangeFromToolbar = null;
  }
  bool _tryRemoveTextColorAtCursor() {
    final ctrl = contentController;
    final text = ctrl.text;
    final cursor = ctrl.selection.baseOffset;
    final lineStart = _lineStartOf(cursor);
    final lineEnd = _lineEndOf(cursor);
    final line = text.substring(lineStart, lineEnd);
    final posInLine = cursor - lineStart;
    for (final m in RichNoteTextController.reInlineTextColor.allMatches(line)) {
      if (RichNoteTextController.isCursorInTextColorInner(m, posInLine)) {
        final inner = m.group(2) ?? '';
        final absStart = lineStart + m.start;
        final absEnd = lineStart + m.end;
        const openLen = 3 + 6 + 1;
        final rel = posInLine - m.start;
        final offsetInInner = (rel - openLen).clamp(0, inner.length).toInt();
        ctrl.value = TextEditingValue(
          text: text.replaceRange(absStart, absEnd, inner),
          selection: TextSelection.collapsed(offset: absStart + offsetInInner),
        );
        return true;
      }
    }
    return false;
  }
  void setEditorTextContentWidth(double w) {
    contentController.updateTextContentWidth(w);
  }
  void _insertAtCursor(String insertion) {
    final ctrl = contentController;
    final pos = ctrl.selection.baseOffset;
    final t = ctrl.text;
    final safePos = pos < 0 ? t.length : pos;
    final newText = t.replaceRange(safePos, safePos, insertion);
    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: (safePos + insertion.length).clamp(0, newText.length),
      ),
    );
  }
  void _insertMediaBlockLine(String bodyLine) {
    final ctrl = contentController;
    final pos = ctrl.selection.baseOffset;
    final t = ctrl.text;
    final safePos = pos < 0 ? t.length : pos;
    final lineStart = richNoteLineStartInText(t, safePos);
    final insertAt = richNoteLineEndInText(t, safePos);
    final lineEmpty = lineStart == insertAt;
    final String insert;
    final int replaceStart;
    final atEof = insertAt >= t.length;
    if (lineEmpty) {
      replaceStart = lineStart;
      insert = atEof ? '$bodyLine\n' : bodyLine;
    } else {
      replaceStart = insertAt;
      insert = atEof ? '\n$bodyLine\n' : '\n$bodyLine';
    }
    final newText = t.replaceRange(replaceStart, replaceStart, insert);
    final rawCaret = atEof
        ? replaceStart + insert.length
        : replaceStart + insert.length + 1;
    final caret = rawCaret.clamp(0, newText.length);
    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: caret),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      editorFocusNode.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final safe = caret.clamp(0, ctrl.text.length);
        ctrl.selection = TextSelection.collapsed(offset: safe);
        if (editorScrollController.hasClients) {
          editorScrollController.position.jumpTo(
            editorScrollController.position.maxScrollExtent,
          );
        }
      });
    });
  }
  void onInsertDivider() {
    const divider = '\n---\n';
    _insertAtCursor(divider);
  }
  void onInsertLink() {
    FocusManager.instance.primaryFocus?.unfocus();
    onToolbarPointerDown();
    final labelC = TextEditingController(text: '');
    final urlC = TextEditingController();
    if (Get.context == null) return;
    void disposeCtrls() {
      labelC.dispose();
      urlC.dispose();
    }
    Get.dialog<void>(
      AlertDialog(
        backgroundColor: surfaceColor,
        title: const Text('Insert link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelC,
              decoration: const InputDecoration(
                labelText: 'Link',
                hintText: 'Enter link',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlC,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'Enter link address',
                labelText: 'URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back<void>();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (urlC.text.trim().isEmpty) {
                errorToast('Enter a URL');
                return;
              }
              final u = ensureHttpScheme(urlC.text);
              final l = labelC.text;
              _insertAtCursor('[$l]($u)');
              Get.back<void>();
            },
            child: const Text('Insert'),
          ),
        ],
      ),
    ).then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        disposeCtrls();
      });
    });
  }
  Future<void> onInsertImage() async {
    FocusManager.instance.primaryFocus?.unfocus();
    onToolbarPointerDown();
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(source: ImageSource.gallery);
      if (x == null) return;
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(base.path, 'note_images'));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final ext = p.extension(x.path).isEmpty ? '.jpg' : p.extension(x.path);
      final destPath = p.join(dir.path, '${const Uuid().v4()}$ext');
      await File(x.path).copy(destPath);
      _insertMediaBlockLine(richNoteImageLineText(destPath));
    } catch (_) {
      errorToast('Failed to pick image');
    }
  }
  Future<void> onInsertAttachment() async {
    FocusManager.instance.primaryFocus?.unfocus();
    onToolbarPointerDown();
    try {
      final r = await FilePicker.pickFiles();
      if (r == null || r.files.isEmpty) return;
      final f = r.files.first;
      final src = f.path;
      if (src == null || src.isEmpty) {
        errorToast('No file path');
        return;
      }
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(base.path, 'note_attachments'));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final ext = p.extension(f.name);
      final destPath = p.join(dir.path, '${const Uuid().v4()}$ext');
      await File(src).copy(destPath);
      _insertMediaBlockLine(richNoteFileLineText(f.name, destPath));
    } catch (_) {
      errorToast('Failed to pick file');
    }
  }
  Future<void> onInsertVoice() async {
    if (kIsWeb) {
      errorToast('Voice is not available here');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    onToolbarPointerDown();
    final st = await Permission.microphone.request();
    if (st != PermissionStatus.granted) {
      errorToast('Microphone permission denied');
      return;
    }
    if (Get.context == null) return;
    final path = await Get.bottomSheet<String?>(
      const TimeloomRichNoteVoiceRecordSheet(),
      backgroundColor: surfaceColor,
    );
    if (path == null || path.isEmpty) return;
    _insertMediaBlockLine(richNoteVoiceLineText(path));
  }
  Future<void> onSaveTap() async {
    final content = contentController.text.trim();
    if (content.isEmpty) {
      errorToast('Content cannot be empty');
      return;
    }
    try {
      final db = DbTimeloom.to;
      final now = DateTime.now().toIso8601String();
      final wasNew = recordId == null;
      int finalId;
      if (wasNew) {
        final newId = await db.insertRecord(
          RecordEntity(
            type: RecordType.richNote,
            scheduledAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
        if (newId < 0) throw Exception('Insert record failed');
        await db.insertRichNoteRecord(
          RichNoteRecordEntity(recordId: newId, content: content),
        );
        recordId = newId;
        finalId = newId;
      } else {
        final rid = recordId!;
        await db.updateRecord(
          RecordEntity(
            id: rid,
            type: RecordType.richNote,
            scheduledAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await db.updateRichNoteRecord(
          RichNoteRecordEntity(recordId: rid, content: content),
        );
        finalId = rid;
      }
      await db.replaceRecordTags(finalId, noteTagNames.toList());
      _originalTagNames = List<String>.from(noteTagNames);
      _originalContent = content;
      successToast(wasNew ? 'Note saved' : 'Note updated');
      Get.back(result: true);
    } catch (_) {
      errorToast('Failed to save note');
    }
  }
  void onCloseTap() {
    final current = contentController.text;
    final dirty = (current != _originalContent) || _tagsDifferFromOriginal();
    if (dirty) {
      Get.dialog(
        AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('Your changes will not be saved.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                Get.back();
              },
              child: const Text('Discard', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      Get.back();
    }
  }
  int _lineStartOf(int offset) {
    final text = contentController.text;
    final idx = text.lastIndexOf('\n', offset > 0 ? offset - 1 : 0);
    return idx < 0 ? 0 : idx + 1;
  }
  int _lineEndOf(int offset) {
    final text = contentController.text;
    final idx = text.indexOf('\n', offset);
    return idx < 0 ? text.length : idx;
  }
}
