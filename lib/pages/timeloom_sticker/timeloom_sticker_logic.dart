import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../db_timeloom/data.dart';
import '../../db_timeloom/db_timeloom_entity.dart';
import '../../utils/index.dart';
class TimeloomStickerLogic extends GetxController {
  static const int _maxHistory = 50;
  static int? _coerceRecordId(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
  late final TextEditingController contentController;
  late final FocusNode contentFocusNode;
  int? recordId;
  final stickerTagNames = RxList<String>();
  List<String> _originalTagNames = [];
  final stickerImagePaths = RxList<String>();
  List<String> _originalImagePaths = [];
  bool get hasUndo => _undoStack.isNotEmpty;
  bool get hasRedo => _redoStack.isNotEmpty;
  String _originalContent = '';
  final List<TextEditingValue> _undoStack = [];
  final List<TextEditingValue> _redoStack = [];
  TextEditingValue _lastHistoryValue = const TextEditingValue();
  bool _historySuspended = false;
  Future<void>? _recordLoadFuture;
  @override
  void onInit() {
    super.onInit();
    contentController = TextEditingController();
    contentFocusNode = FocusNode();
    contentController.addListener(_onContentHistoryListener);
    _lastHistoryValue = contentController.value;
    final args = Get.arguments as Map<String, dynamic>?;
    recordId = _coerceRecordId(args?['recordId']);
    if (recordId != null) {
      _recordLoadFuture = _loadRecord();
    }
  }
  Future<void> ensureRecordLoaded() async {
    final f = _recordLoadFuture;
    if (f != null) await f;
  }
  Future<void> refreshStickerTagsFromDb() async {
    final rid = recordId;
    if (rid == null) return;
    try {
      final tags = await DbTimeloom.to.getTagsByRecord(rid);
      stickerTagNames.assignAll(tags.map((e) => e.name).toList());
    } catch (_) {}
  }
  @override
  void onClose() {
    contentController.removeListener(_onContentHistoryListener);
    contentFocusNode.dispose();
    contentController.dispose();
    super.onClose();
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
    _refreshCanUndoRedo();
  }
  void redo() {
    if (_redoStack.isEmpty) return;
    final target = _redoStack.removeLast();
    final current = contentController.value;
    _undoStack.add(current);
    while (_undoStack.length > _maxHistory) {
      _undoStack.removeAt(0);
    }
    _historySuspended = true;
    contentController.value = target;
    _lastHistoryValue = target;
    _historySuspended = false;
    _refreshCanUndoRedo();
  }
  Future<void> _loadRecord() async {
    _historySuspended = true;
    try {
      final sticker = await DbTimeloom.to.getStickerRecord(recordId!);
      if (sticker != null) {
        contentController.text = sticker.text;
        _originalContent = sticker.text;
        _decodeStickerImages(sticker.images);
        _originalImagePaths = List<String>.from(stickerImagePaths);
      }
      final tags = await DbTimeloom.to.getTagsByRecord(recordId!);
      final names = tags.map((e) => e.name).toList();
      stickerTagNames.assignAll(names);
      _originalTagNames = List<String>.from(names);
    } catch (e) {
      errorToast('Failed to load sticker');
    } finally {
      _undoStack.clear();
      _redoStack.clear();
      _lastHistoryValue = contentController.value;
      _historySuspended = false;
      _refreshCanUndoRedo();
      update(['images']);
    }
  }
  void _applyAtSelection(String inserted) {
    final text = contentController.text;
    final selection = contentController.selection;
    final start = selection.start < 0 ? text.length : selection.start;
    final end = selection.end < 0 ? text.length : selection.end;
    final newText = text.replaceRange(start, end, inserted);
    contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + inserted.length),
    );
  }
  void insertSymbol(String symbol) {
    _applyAtSelection(symbol);
  }
  Future<void> onPasteTap() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final pasted = data?.text;
    if (pasted == null || pasted.isEmpty) {
      errorToast('Clipboard is empty');
      return;
    }
    await Future<void>.delayed(Duration.zero);
    if (isClosed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      _applyAtSelection(pasted);
    });
  }
  void moveCursorLeft() {
    final pos = contentController.selection.baseOffset;
    if (pos > 0) {
      contentController.selection = TextSelection.collapsed(offset: pos - 1);
    }
  }
  void moveCursorRight() {
    final pos = contentController.selection.baseOffset;
    if (pos < contentController.text.length) {
      contentController.selection = TextSelection.collapsed(offset: pos + 1);
    }
  }
  void _decodeStickerImages(String jsonStr) {
    stickerImagePaths.clear();
    final s = jsonStr.trim();
    if (s.isEmpty || s == '[]') return;
    try {
      final decoded = jsonDecode(s);
      if (decoded is List) {
        for (final e in decoded) {
          final p = e.toString();
          if (p.isNotEmpty) stickerImagePaths.add(p);
        }
      }
    } catch (_) {}
  }
  Future<String?> _copyImageToPermanentDir(String sourcePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final destDir = Directory(p.join(appDir.path, 'sticker_images'));
      if (!destDir.existsSync()) destDir.createSync(recursive: true);
      final ext = p.extension(sourcePath).isNotEmpty ? p.extension(sourcePath) : '.jpg';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final destPath = p.join(destDir.path, fileName);
      await File(sourcePath).copy(destPath);
      return destPath;
    } catch (_) {
      return null;
    }
  }
  Future<void> pickStickerImages() async {
    contentFocusNode.unfocus();
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      if (images.isEmpty) return;
      for (final x in images) {
        if (x.path.isEmpty) continue;
        final permanent = await _copyImageToPermanentDir(x.path);
        if (permanent != null && !stickerImagePaths.contains(permanent)) {
          stickerImagePaths.add(permanent);
        }
      }
      update(['images']);
    } catch (e) {
      errorToast('Failed to pick images');
    }
  }
  void removeStickerImageAt(int index) {
    if (index < 0 || index >= stickerImagePaths.length) return;
    stickerImagePaths.removeAt(index);
    update(['images']);
  }
  Future<void> onSaveTap() async {
    final text = contentController.text.trim();
    if (text.isEmpty) {
      errorToast('Content cannot be empty');
      return;
    }
    try {
      final db = DbTimeloom.to;
      final now = DateTime.now().toIso8601String();
      final imagesJson = jsonEncode(stickerImagePaths.toList());
      if (recordId == null) {
        final newRecordId = await db.insertRecord(
          RecordEntity(
            type: RecordType.sticker,
            scheduledAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
        if (newRecordId < 0) throw Exception('Insert record failed');
        await db.insertStickerRecord(
          StickerRecordEntity(
            recordId: newRecordId,
            text: text,
            images: imagesJson,
          ),
        );
        await _syncStickerTags(newRecordId);
      } else {
        await db.updateRecord(
          RecordEntity(
            id: recordId,
            type: RecordType.sticker,
            scheduledAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await db.updateStickerRecord(
          StickerRecordEntity(
            recordId: recordId!,
            text: text,
            images: imagesJson,
          ),
        );
        await _syncStickerTags(recordId!);
      }
      _originalTagNames = List<String>.from(stickerTagNames);
      _originalImagePaths = List<String>.from(stickerImagePaths);
      successToast(recordId == null ? 'Sticker saved' : 'Sticker updated');
      Get.back(result: true);
    } catch (e) {
      errorToast('Failed to save sticker');
    }
  }
  Future<void> _syncStickerTags(int rid) async {
    await DbTimeloom.to.replaceRecordTags(rid, stickerTagNames.toList());
  }
  Future<void> applyStickerTags(List<String> names) async {
    final seen = <String>{};
    final next = <String>[];
    for (final raw in names) {
      final t = raw.trim();
      if (t.isEmpty || seen.contains(t)) continue;
      seen.add(t);
      next.add(t);
    }
    stickerTagNames.assignAll(next);
    if (recordId != null) {
      try {
        await _syncStickerTags(recordId!);
        _originalTagNames = List<String>.from(stickerTagNames);
      } catch (e) {
        errorToast('Failed to save tags');
      }
    }
  }
  bool _tagsDifferFromOriginal() {
    if (_originalTagNames.length != stickerTagNames.length) return true;
    final a = List<String>.from(_originalTagNames)..sort();
    final b = List<String>.from(stickerTagNames)..sort();
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return true;
    }
    return false;
  }
  bool _imagesDifferFromOriginal() {
    if (_originalImagePaths.length != stickerImagePaths.length) return true;
    final a = List<String>.from(_originalImagePaths)..sort();
    final b = List<String>.from(stickerImagePaths)..sort();
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return true;
    }
    return false;
  }
  void onCloseTap() {
    final current = contentController.text;
    final dirty =
        (current != _originalContent) ||
        _tagsDifferFromOriginal() ||
        _imagesDifferFromOriginal();
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
}
