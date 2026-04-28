import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../db_timeloom/data.dart';
import '../../db_timeloom/db_timeloom_entity.dart';
enum HomeFilter {
  all,
  sticker,
  richNote,
  checklist,
  checklistIncomplete,
  checklistComplete,
  mood,
  media,
  link,
  attachment,
}
class TimeloomHomeLogic extends GetxController {
  final currentFilter = HomeFilter.all.obs;
  final sidebarTabIndex = 0.obs;
  final isChecklistExpanded = false.obs;
  final selectedDate = ''.obs;
  final calendarYear = DateTime.now().year.obs;
  final calendarMonth = DateTime.now().month.obs;
  final markedDates = <int>[].obs;
  final records = <RecordEntity>[].obs;
  final stickerCache = <int, StickerRecordEntity>{};
  final moodCache = <int, MoodRecordEntity>{};
  final checklistCache = <int, ChecklistRecordEntity>{};
  final checklistItemsCache = <int, List<ChecklistItemEntity>>{};
  final linkCache = <int, LinkRecordEntity>{};
  final isLoading = false.obs;
  final tags = <TagEntity>[].obs;
  final selectedTagId = Rxn<int>();
  static String get appVersionLabel => '1.0.0';
  static String get todayDate {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
  static const _monthAbbr = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    selectedDate.value = todayDate;
    calendarYear.value = now.year;
    calendarMonth.value = now.month;
    loadRecords();
    loadTags();
  }
  String get dateLabel {
    final today = todayDate;
    if (selectedDate.value == today) return 'Today';
    final parts = selectedDate.value.split('-');
    if (parts.length < 3) return selectedDate.value;
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? 1;
    final day = int.tryParse(parts[2]) ?? 1;
    if (year == DateTime.now().year) {
      return '${_monthAbbr[month - 1]} $day';
    }
    return '${_monthAbbr[month - 1]} $day, $year';
  }
  String get calendarMonthTitle =>
      '${_monthNames[calendarMonth.value - 1]} ${calendarYear.value}';
  String get filterLabel {
    return switch (currentFilter.value) {
      HomeFilter.all => 'All',
      HomeFilter.sticker => 'Sticker',
      HomeFilter.richNote => 'Note',
      HomeFilter.checklist => 'Checklist',
      HomeFilter.checklistIncomplete => 'Incomplete',
      HomeFilter.checklistComplete => 'Complete',
      HomeFilter.mood => 'Mood',
      HomeFilter.media => 'Photo',
      HomeFilter.link => 'Link',
      HomeFilter.attachment => 'Attachment',
    };
  }
  Future<void> loadRecords() async {
    try {
      isLoading.value = true;
      final db = DbTimeloom.to;
      final date = selectedDate.value;
      List<RecordEntity> result;
      if (currentFilter.value == HomeFilter.checklistIncomplete) {
        result = await db.getChecklistRecordsByCompletion(
          allCompleted: false,
          date: date,
        );
      } else if (currentFilter.value == HomeFilter.checklistComplete) {
        result = await db.getChecklistRecordsByCompletion(
          allCompleted: true,
          date: date,
        );
      } else {
        final typeFilter = switch (currentFilter.value) {
          HomeFilter.sticker => RecordType.sticker,
          HomeFilter.richNote => RecordType.richNote,
          HomeFilter.checklist => RecordType.checklist,
          HomeFilter.mood => RecordType.mood,
          HomeFilter.media => RecordType.media,
          HomeFilter.link => RecordType.link,
          HomeFilter.attachment => RecordType.attachment,
          _ => null,
        };
        result = await db.getRecords(
          type: typeFilter,
          tagId: selectedTagId.value?.toString(),
          date: selectedTagId.value != null ? null : date,
        );
      }
      stickerCache.clear();
      moodCache.clear();
      checklistCache.clear();
      checklistItemsCache.clear();
      linkCache.clear();
      for (final record in result) {
        final id = record.id!;
        switch (record.type) {
          case RecordType.sticker:
            final s = await db.getStickerRecord(id);
            if (s != null) stickerCache[id] = s;
          case RecordType.mood:
            final m = await db.getMoodRecord(id);
            if (m != null) moodCache[id] = m;
          case RecordType.checklist:
            final c = await db.getChecklistRecord(id);
            if (c != null) checklistCache[id] = c;
            checklistItemsCache[id] = await db.getChecklistItems(id);
          case RecordType.link:
            final l = await db.getLinkRecord(id);
            if (l != null) linkCache[id] = l;
          default:
            break;
        }
      }
      records.value = result;
    } catch (e) {
      debugPrint('loadRecords error: $e');
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> loadTags() async {
    try {
      tags.value = await DbTimeloom.to.getTags();
    } catch (e) {
      debugPrint('loadTags error: $e');
    }
  }
  Future<void> loadMarkedDates() async {
    try {
      markedDates.value = await DbTimeloom.to.getRecordDatesInMonth(
        calendarYear.value,
        calendarMonth.value,
      );
    } catch (e) {
      debugPrint('loadMarkedDates error: $e');
    }
  }
  Future<void> refreshAfterEdit() async {
    await Future.wait([loadRecords(), loadTags()]);
  }
  void onFilterChanged(HomeFilter filter) {
    currentFilter.value = filter;
    selectedTagId.value = null;
    Get.back();
    loadRecords();
  }
  void onSidebarTabChanged(int index) {
    sidebarTabIndex.value = index;
    if (index == 1) {
      loadMarkedDates();
    } else if (index == 2) {
      loadTags();
    }
  }
  void onChecklistToggle() {
    isChecklistExpanded.value = !isChecklistExpanded.value;
  }
  void onTagSelected(int? tagId) {
    selectedTagId.value = tagId;
    currentFilter.value = HomeFilter.all;
    Get.back();
    loadRecords();
  }
  void onDateSelected(int day) {
    final month = calendarMonth.value.toString().padLeft(2, '0');
    final dayStr = day.toString().padLeft(2, '0');
    selectedDate.value = '${calendarYear.value}-$month-$dayStr';
    Get.back();
    loadRecords();
  }
  void onJumpToToday() {
    final now = DateTime.now();
    selectedDate.value = todayDate;
    calendarYear.value = now.year;
    calendarMonth.value = now.month;
    loadMarkedDates();
    Get.back();
    loadRecords();
  }
  void onPreviousMonth() {
    if (calendarMonth.value == 1) {
      calendarMonth.value = 12;
      calendarYear.value--;
    } else {
      calendarMonth.value--;
    }
    loadMarkedDates();
  }
  void onNextMonth() {
    if (calendarMonth.value == 12) {
      calendarMonth.value = 1;
      calendarYear.value++;
    } else {
      calendarMonth.value++;
    }
    loadMarkedDates();
  }
  Future<void> onDeleteRecord(int id) async {
    try {
      await DbTimeloom.to.deleteRecord(id);
      await loadRecords();
    } catch (e) {
      debugPrint('onDeleteRecord error: $e');
    }
  }
  Future<void> clearAllData() async {
    try {
      final allRecords = await DbTimeloom.to.getRecords();
      for (final r in allRecords) {
        if (r.id != null) await DbTimeloom.to.deleteRecord(r.id!);
      }
      await loadRecords();
    } catch (e) {
      debugPrint('clearAllData error: $e');
    }
  }
}
