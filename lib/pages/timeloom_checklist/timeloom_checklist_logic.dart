import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../db_timeloom/data.dart';
import '../../db_timeloom/db_timeloom_entity.dart';
import '../../utils/index.dart';
class ChecklistItem {
  final String localId;
  int? dbId;
  final TextEditingController textController;
  final FocusNode focusNode;
  bool isCompleted;
  ChecklistItem({
    required this.localId,
    this.dbId,
    String text = '',
    this.isCompleted = false,
  }) : textController = TextEditingController(text: text),
       focusNode = FocusNode();
  void dispose() {
    textController.dispose();
    focusNode.dispose();
  }
}
class TimeloomChecklistLogic extends GetxController {
  final items = <ChecklistItem>[].obs;
  final scheduledTime = Rxn<DateTime>();
  final checklistTagNames = RxList<String>();
  late final TextEditingController titleController;
  int? recordId;
  @override
  void onInit() {
    super.onInit();
    titleController = TextEditingController();
    final args = Get.arguments as Map<String, dynamic>?;
    recordId = args?['recordId'] as int?;
    if (recordId != null) {
      _loadRecord();
    } else {
      _addEmptyItem();
    }
  }
  @override
  void onClose() {
    titleController.dispose();
    for (final item in items) {
      item.dispose();
    }
    super.onClose();
  }
  Future<void> _loadRecord() async {
    try {
      final db = DbTimeloom.to;
      final checklist = await db.getChecklistRecord(recordId!);
      if (checklist != null) {
        titleController.text = checklist.title;
      }
      final dbItems = await db.getChecklistItems(recordId!);
      final loaded = dbItems
          .map(
            (e) => ChecklistItem(
              localId:
                  e.id?.toString() ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              dbId: e.id,
              text: e.text,
              isCompleted: e.isCompleted,
            ),
          )
          .toList();
      items.value = loaded;
      if (items.isEmpty) _addEmptyItem();
      final record = await db.getRecord(recordId!);
      if (record != null) {
        scheduledTime.value = DateTime.tryParse(record.scheduledAt);
      }
      final tags = await db.getTagsByRecord(recordId!);
      checklistTagNames.assignAll(tags.map((e) => e.name));
    } catch (e) {
      errorToast('Failed to load checklist');
    }
  }
  void _addEmptyItem() {
    items.add(
      ChecklistItem(localId: DateTime.now().millisecondsSinceEpoch.toString()),
    );
  }
  void onAddItem() {
    _addEmptyItem();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      items.last.focusNode.requestFocus();
    });
  }
  void onToggleItem(String localId) async {
    final index = items.indexWhere((i) => i.localId == localId);
    if (index == -1) return;
    items[index].isCompleted = !items[index].isCompleted;
    items.refresh();
    if (recordId != null && items[index].dbId != null) {
      try {
        await DbTimeloom.to.updateChecklistItem(
          ChecklistItemEntity(
            id: items[index].dbId,
            recordId: recordId!,
            text: items[index].textController.text,
            isCompleted: items[index].isCompleted,
            sortOrder: index,
          ),
        );
      } catch (e) {
        debugPrint('updateChecklistItem error: $e');
      }
    }
  }
  void onRemoveItem(String localId) {
    final index = items.indexWhere((i) => i.localId == localId);
    if (index == -1) return;
    items[index].dispose();
    items.removeAt(index);
  }
  String get scheduledLabel {
    if (scheduledTime.value == null) return 'Now';
    final d = scheduledTime.value!;
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
  Future<void> onSaveTap() async {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      errorToast('Please enter a title');
      return;
    }
    final nonEmptyItems = items
        .where((i) => i.textController.text.trim().isNotEmpty)
        .toList();
    if (nonEmptyItems.isEmpty) {
      errorToast('Please add at least one item');
      return;
    }
    try {
      final db = DbTimeloom.to;
      final scheduled = scheduledTime.value ?? DateTime.now();
      final now = DateTime.now().toIso8601String();
      final scheduledStr = scheduled.toIso8601String();
      if (recordId == null) {
        final newRecordId = await db.insertRecord(
          RecordEntity(
            type: RecordType.checklist,
            scheduledAt: scheduledStr,
            createdAt: now,
            updatedAt: now,
          ),
        );
        if (newRecordId < 0) throw Exception('Insert record failed');
        await db.insertChecklistRecord(
          ChecklistRecordEntity(recordId: newRecordId, title: title),
        );
        for (var i = 0; i < nonEmptyItems.length; i++) {
          await db.insertChecklistItem(
            ChecklistItemEntity(
              recordId: newRecordId,
              text: nonEmptyItems[i].textController.text.trim(),
              isCompleted: nonEmptyItems[i].isCompleted,
              sortOrder: i,
            ),
          );
        }
        await db.replaceRecordTags(newRecordId, checklistTagNames.toList());
      } else {
        await db.updateRecord(
          RecordEntity(
            id: recordId,
            type: RecordType.checklist,
            scheduledAt: scheduledStr,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await db.updateChecklistRecord(
          ChecklistRecordEntity(recordId: recordId!, title: title),
        );
        await db.deleteChecklistItemsByRecord(recordId!);
        for (var i = 0; i < nonEmptyItems.length; i++) {
          await db.insertChecklistItem(
            ChecklistItemEntity(
              recordId: recordId!,
              text: nonEmptyItems[i].textController.text.trim(),
              isCompleted: nonEmptyItems[i].isCompleted,
              sortOrder: i,
            ),
          );
        }
        await db.replaceRecordTags(recordId!, checklistTagNames.toList());
      }
      successToast(recordId == null ? 'Checklist saved' : 'Checklist updated');
      Get.back(result: true);
    } catch (e) {
      errorToast('Failed to save checklist');
    }
  }
  Future<void> applyChecklistTags(List<String> names) async {
    final seen = <String>{};
    final next = <String>[];
    for (final raw in names) {
      final t = raw.trim();
      if (t.isEmpty || seen.contains(t)) continue;
      seen.add(t);
      next.add(t);
    }
    checklistTagNames.assignAll(next);
  }
  void onCloseTap() {
    Get.back();
  }
}
