import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../components/calendar.dart';
import '../../db_timeloom/data.dart';
import '../../db_timeloom/db_timeloom_entity.dart';
import '../../main.dart';
import '../../utils/index.dart';
import '../../utils/timeloom_open_local_file.dart';
import '../../components/timeloom_media_viewer.dart';
import '../../components/timeloom_video_player.dart';
import '../../components/timeloom_audio_player.dart';
import '../../components/timeloom_audio_record_sheet.dart';
import 'timeloom_home_logic.dart';
class TimeloomHomeView extends GetView<TimeloomHomeLogic> {
  const TimeloomHomeView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      drawer: _buildDrawer(),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildTimeline()),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: surfaceColor,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: textColor),
              onPressed: () {
                controller.loadTags();
                Scaffold.of(ctx).openDrawer();
              },
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.h),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: textColor),
            onPressed: () => _showSettingsDialog(),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.h),
          ),
          const Spacer(),
          _buildLogo(),
          const Spacer(),
          IconButton(
            icon: Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(8.w),
              ),
              child: Icon(Icons.add, color: onPrimaryColor, size: 18.w),
            ),
            onPressed: () => _showAddBottomSheet(),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.h),
          ),
        ],
      ),
    );
  }
  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22.w,
          height: 22.w,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(6.w),
          ),
          child: Icon(Icons.schedule, color: onPrimaryColor, size: 14.w),
        ),
        SizedBox(width: 6.w),
        Text(
          'Timeloom',
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: primaryColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
  Widget _buildFilterBar() {
    return Obx(
      () => Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(bottom: BorderSide(color: dividerColor, width: 1)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14.w,
              color: primaryColor,
            ),
            SizedBox(width: 5.w),
            Text(
              controller.dateLabel,
              style: TextStyle(
                fontSize: 13.sp,
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (controller.currentFilter.value != HomeFilter.all ||
                controller.selectedTagId.value != null) ...[
              SizedBox(width: 8.w),
              Container(width: 1, height: 12.h, color: dividerColor),
              SizedBox(width: 8.w),
              Icon(
                _filterIcon(controller.currentFilter.value),
                size: 13.w,
                color: textSecondaryColor,
              ),
              SizedBox(width: 4.w),
              Text(
                controller.filterLabel,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (controller.selectedTagId.value != null) ...[
                SizedBox(width: 4.w),
                Text(
                  '#${controller.tags.firstWhere((t) => t.id == controller.selectedTagId.value, orElse: () => TagEntity(name: '')).name}',
                  style: TextStyle(fontSize: 12.sp, color: textSecondaryColor),
                ),
              ],
            ],
            const Spacer(),
            if (controller.currentFilter.value != HomeFilter.all ||
                controller.selectedTagId.value != null)
              GestureDetector(
                onTap: () => controller.onFilterChanged(HomeFilter.all),
                child: Icon(Icons.close, size: 16.w, color: textSecondaryColor),
              ),
          ],
        ),
      ),
    );
  }
  IconData _filterIcon(HomeFilter type) {
    switch (type) {
      case HomeFilter.all:
        return Icons.all_inclusive;
      case HomeFilter.sticker:
        return Icons.sticky_note_2_outlined;
      case HomeFilter.richNote:
        return Icons.description_outlined;
      case HomeFilter.checklist:
      case HomeFilter.checklistIncomplete:
      case HomeFilter.checklistComplete:
        return Icons.checklist_outlined;
      case HomeFilter.mood:
        return Icons.sentiment_satisfied_outlined;
      case HomeFilter.media:
        return Icons.photo_outlined;
      case HomeFilter.link:
        return Icons.link_outlined;
      case HomeFilter.attachment:
        return Icons.attach_file_outlined;
    }
  }
  Widget _buildTimeline() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.records.isEmpty) {
        return _buildEmptyState();
      }
      final groups = <String, List<RecordEntity>>{};
      for (final record in controller.records) {
        final date = record.scheduledAt.substring(0, 10);
        groups.putIfAbsent(date, () => []).add(record);
      }
      final dates = groups.keys.toList();
      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: dates.length + 1,
        itemBuilder: (context, groupIndex) {
          if (groupIndex == dates.length) return SizedBox(height: 26.h);
          final date = dates[groupIndex];
          final dayRecords = groups[date]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateGroup(date),
              ...dayRecords.asMap().entries.map((entry) {
                final i = entry.key;
                final record = entry.value;
                final isLast =
                    groupIndex == dates.length - 1 &&
                    i == dayRecords.length - 1;
                return _buildTimelineItemForRecord(record, isLast: isLast);
              }),
            ],
          );
        },
      );
    });
  }
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64.w,
            color: textSecondaryColor.withValues(alpha: 0.5),
          ),
          SizedBox(height: 12.h),
          Text(
            'No records yet',
            style: TextStyle(
              fontSize: 16.sp,
              color: textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Tap + to create your first record',
            style: TextStyle(fontSize: 13.sp, color: textSecondaryColor),
          ),
        ],
      ),
    );
  }
  Widget _buildDateGroup(String isoDate) {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yest =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    String label;
    if (isoDate == today) {
      label = 'Today';
    } else if (isoDate == yest) {
      label = 'Yesterday';
    } else {
      final parts = isoDate.split('-');
      label = '${parts[1]}/${parts[2]}/${parts[0]}';
    }
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h, top: 2.h),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            isoDate,
            style: TextStyle(fontSize: 11.sp, color: textSecondaryColor),
          ),
          SizedBox(width: 8.w),
          Expanded(child: Container(height: 1, color: dividerColor)),
        ],
      ),
    );
  }
  Widget _buildTimelineItemForRecord(
    RecordEntity record, {
    bool isLast = false,
  }) {
    final timeParts = record.scheduledAt.length >= 16
        ? record.scheduledAt.substring(11, 16)
        : '';
    final dotColor = _dotColorForType(record.type);
    Widget cardWidget;
    switch (record.type) {
      case RecordType.sticker:
        final sticker = controller.stickerCache[record.id!];
        cardWidget = _buildStickerCard(record, sticker);
      case RecordType.mood:
        final mood = controller.moodCache[record.id!];
        cardWidget = _buildMoodCard(record, mood);
      case RecordType.checklist:
        final checklist = controller.checklistCache[record.id!];
        final items = controller.checklistItemsCache[record.id!] ?? [];
        cardWidget = _buildChecklistCard(record, checklist, items);
      case RecordType.richNote:
        cardWidget = _buildRichNoteCard(record);
      case RecordType.link:
        final link = controller.linkCache[record.id!];
        cardWidget = _buildLinkCard(record, link);
      case RecordType.media:
        cardWidget = _buildMediaCard(record);
      case RecordType.attachment:
        cardWidget = _buildAttachmentPlaceholderCard(record);
    }
    return Dismissible(
      key: Key('record_${record.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 16.w),
        color: Colors.red.withValues(alpha: 0.1),
        child: Icon(Icons.delete_outline, color: Colors.red, size: 22.w),
      ),
      confirmDismiss: (_) async {
        return await Get.dialog<bool>(
              AlertDialog(
                title: const Text('Delete Record'),
                content: const Text(
                  'Are you sure you want to delete this record?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Get.back(result: true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => controller.onDeleteRecord(record.id!),
      child: _buildTimelineItem(
        time: timeParts,
        dotColor: dotColor,
        child: cardWidget,
        isLast: isLast,
      ),
    );
  }
  Color _dotColorForType(RecordType type) {
    switch (type) {
      case RecordType.sticker:
        return const Color(0xFF3D4F8C);
      case RecordType.mood:
        return const Color(0xFFC9A227);
      case RecordType.checklist:
        return const Color(0xFF5B8A5B);
      case RecordType.richNote:
        return const Color(0xFF8B5CF6);
      case RecordType.media:
        return const Color(0xFFEC4899);
      case RecordType.link:
        return const Color(0xFF0EA5E9);
      case RecordType.attachment:
        return const Color(0xFFF59E0B);
    }
  }
  Widget _buildTimelineItem({
    required String time,
    required Color dotColor,
    required Widget child,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 54.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(height: 14.h),
                Text(
                  time,
                  style: TextStyle(fontSize: 11.sp, color: textSecondaryColor),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Column(
            children: [
              SizedBox(height: 15.h),
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: dividerColor,
                    margin: EdgeInsets.only(top: 4.h),
                  ),
                ),
            ],
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildStickerCard(RecordEntity record, StickerRecordEntity? sticker) {
    return GestureDetector(
      onTap: () => Get.toNamed(
        '/note/sticker',
        arguments: {'recordId': record.id},
      )?.then((_) => controller.refreshAfterEdit()),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sticky_note_2_outlined,
                  size: 13.w,
                  color: primaryColor,
                ),
                SizedBox(width: 4.w),
                Text(
                  'Sticker',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              sticker?.text ?? '',
              style: TextStyle(fontSize: 13.sp, color: textColor, height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildMoodCard(RecordEntity record, MoodRecordEntity? mood) {
    final display = mood?.stickerType == StickerType.emoji
        ? mood!.stickerKey
        : (mood?.stickerKey ?? '😊');
    return GestureDetector(
      onTap: () => Get.toNamed(
        '/note/mood',
        arguments: {'recordId': record.id},
      )?.then((_) => controller.refreshAfterEdit()),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Text(display, style: TextStyle(fontSize: 32.sp)),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.sentiment_satisfied_outlined,
                        size: 13.w,
                        color: const Color(0xFFC9A227),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Mood',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFFC9A227),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (mood?.text != null && mood!.text!.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      mood.text!,
                      style: TextStyle(fontSize: 13.sp, color: textColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildChecklistCard(
    RecordEntity record,
    ChecklistRecordEntity? checklist,
    List<ChecklistItemEntity> items,
  ) {
    final completed = items.where((i) => i.isCompleted).length;
    return GestureDetector(
      onTap: () => Get.toNamed(
        '/note/checklist',
        arguments: {'recordId': record.id},
      )?.then((_) => controller.refreshAfterEdit()),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.checklist_outlined,
                  size: 13.w,
                  color: const Color(0xFF5B8A5B),
                ),
                SizedBox(width: 4.w),
                Text(
                  'Checklist',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF5B8A5B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '$completed/${items.length}',
                  style: TextStyle(fontSize: 11.sp, color: textSecondaryColor),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              checklist?.title ?? '',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            SizedBox(height: 6.h),
            ...items
                .take(3)
                .map(
                  (item) => Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Row(
                      children: [
                        Icon(
                          item.isCompleted
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 15.w,
                          color: item.isCompleted
                              ? const Color(0xFF5B8A5B)
                              : textSecondaryColor,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          item.text,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: item.isCompleted
                                ? textSecondaryColor
                                : textColor,
                            decoration: item.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (items.length > 3)
              Text(
                '+ ${items.length - 3} more',
                style: TextStyle(fontSize: 11.sp, color: textSecondaryColor),
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildRichNoteCard(RecordEntity record) {
    return GestureDetector(
      onTap: () => Get.toNamed(
        '/note/rich',
        arguments: {'recordId': record.id},
      )?.then((_) => controller.refreshAfterEdit()),
      child: FutureBuilder<RichNoteRecordEntity?>(
        future: DbTimeloom.to.getRichNoteRecord(record.id!),
        builder: (context, snapshot) {
          final content = snapshot.data?.content ?? '';
          return Container(
            padding: EdgeInsets.all(12.w),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 13.w,
                      color: const Color(0xFF8B5CF6),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Note',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: const Color(0xFF8B5CF6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: textSecondaryColor,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  Widget _buildMediaCard(RecordEntity record) {
    return FutureBuilder<List<MediaFileEntity>>(
      future: DbTimeloom.to.getMediaFiles(record.id!),
      builder: (context, snapshot) {
        final files = snapshot.data ?? [];
        if (files.isEmpty) {
          return Container(
            padding: EdgeInsets.all(12.w),
            decoration: _cardDecoration(),
            child: Text(
              'No media',
              style: TextStyle(fontSize: 12.sp, color: textSecondaryColor),
            ),
          );
        }
        final mediaType = files.first.mediaType;
        if (mediaType == MediaType.audio) {
          return _buildAudioCard(record, files.first);
        } else if (mediaType == MediaType.video) {
          return _buildVideoCard(record, files.first);
        } else {
          final count = files.length;
          return GestureDetector(
            onTap: () {
              Get.to(() => TimeloomMediaViewer(files: files, initialIndex: 0));
            },
            child: Container(
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 6.h),
                    child: Row(
                      children: [
                        Icon(
                          Icons.photo_outlined,
                          size: 13.w,
                          color: const Color(0xFFEC4899),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Photo',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: const Color(0xFFEC4899),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$count ${count == 1 ? 'photo' : 'photos'}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12.w),
                      bottomRight: Radius.circular(12.w),
                    ),
                    child: _buildMediaThumbnailGrid(files),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
  Widget _buildMediaThumbnailGrid(List<MediaFileEntity> files) {
    final count = files.length;
    final displayCount = count > 4 ? 4 : count;
    if (displayCount == 0) return const SizedBox();
    Widget cell(int index) {
      final isOverlay = index == 3 && count > 4;
      final file = index < files.length ? files[index] : null;
      return Container(
        color: dividerColor,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (file != null && File(file.localPath).existsSync())
              Image.file(
                File(file.localPath),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            else
              Icon(Icons.image_outlined, color: textSecondaryColor, size: 24.w),
            if (isOverlay)
              Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: Center(
                  child: Text(
                    '+${count - 3}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    if (count == 1) {
      return AspectRatio(aspectRatio: 2.0, child: cell(0));
    }
    final rows = <Widget>[];
    for (var i = 0; i < displayCount; i += 2) {
      final hasSecond = i + 1 < displayCount;
      rows.add(
        Row(
          children: [
            Expanded(child: AspectRatio(aspectRatio: 1.0, child: cell(i))),
            const SizedBox(width: 2),
            Expanded(
              child: hasSecond
                  ? AspectRatio(aspectRatio: 1.0, child: cell(i + 1))
                  : const SizedBox(),
            ),
          ],
        ),
      );
      if (i + 2 < displayCount) rows.add(const SizedBox(height: 2));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
  Widget _buildVideoCard(RecordEntity record, MediaFileEntity videoFile) {
    return GestureDetector(
      onTap: () {
        Get.to(() => TimeloomVideoPlayer(filePath: videoFile.localPath));
      },
      child: Container(
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 6.h),
              child: Row(
                children: [
                  Icon(
                    Icons.videocam_outlined,
                    size: 13.w,
                    color: const Color(0xFFEF4444),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Video',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFFEF4444),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12.w),
                bottomRight: Radius.circular(12.w),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: dividerColor,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.movie_outlined,
                        color: textSecondaryColor,
                        size: 48.w,
                      ),
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 32.w,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAudioCard(RecordEntity record, MediaFileEntity audioFile) {
    final fileName = p.basenameWithoutExtension(audioFile.localPath);
    return GestureDetector(
      onTap: () {
        Get.bottomSheet(
          TimeloomAudioPlayer(
            filePath: audioFile.localPath,
            fileName: fileName,
          ),
          isScrollControlled: true,
        );
      },
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: const Color(0xFF9333EA).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.w),
              ),
              child: Icon(
                Icons.audiotrack,
                color: const Color(0xFF9333EA),
                size: 20.w,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Audio',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle_outline,
              size: 28.w,
              color: const Color(0xFF9333EA),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildLinkCard(RecordEntity record, LinkRecordEntity? link) {
    final displayText = (link?.displayText?.isNotEmpty == true)
        ? link!.displayText!
        : (link?.url ?? '');
    String domain = '';
    if (link?.url != null) {
      try {
        domain = Uri.parse(link!.url).host;
      } catch (_) {
        domain = link?.url ?? '';
      }
    }
    return GestureDetector(
      onTap: () => Get.toNamed(
        '/note/link',
        arguments: {'recordId': record.id},
      )?.then((_) => controller.refreshAfterEdit()),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(color: dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.w),
              ),
              child: Icon(
                Icons.link,
                color: const Color(0xFF0EA5E9),
                size: 18.w,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    domain,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF0EA5E9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12.w,
              color: textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAttachmentPlaceholderCard(RecordEntity record) {
    return FutureBuilder<AttachmentRecordEntity?>(
      future: DbTimeloom.to.getAttachmentRecord(record.id!),
      builder: (context, snapshot) {
        final att = snapshot.data;
        final fileName = att?.fileName ?? 'Attachment';
        final fileType = att?.fileType.toUpperCase() ?? '';
        final fileSize = att != null
            ? '${(att.fileSize / 1024).toStringAsFixed(1)} KB'
            : '';
        return GestureDetector(
          onTap: () {
            if (att != null && att.localPath.isNotEmpty) {
              openLocalFileForPreview(att.localPath);
            }
          },
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.w),
                  ),
                  child: Center(
                    child: Text(
                      fileType.isNotEmpty ? fileType : 'FILE',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        fileSize,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.more_horiz, size: 18.w, color: textSecondaryColor),
              ],
            ),
          ),
        );
      },
    );
  }
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(12.w),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
  Widget _buildBottomBar(BuildContext context) {
    return Container(
      height: 88.h,
      padding: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildQuickButton(
            icon: Icons.text_fields,
            label: 'Sticker',
            color: primaryColor,
            onTap: () => Get.toNamed(
              '/note/sticker',
            )?.then((_) => controller.refreshAfterEdit()),
          ),
          _buildQuickButton(
            icon: Icons.checklist,
            label: 'Checklist',
            color: const Color(0xFF5B8A5B),
            onTap: () => Get.toNamed(
              '/note/checklist',
            )?.then((_) => controller.refreshAfterEdit()),
          ),
          _buildQuickButton(
            icon: Icons.sentiment_satisfied_outlined,
            label: 'Mood',
            color: secondaryColor,
            onTap: () => Get.toNamed(
              '/note/mood',
            )?.then((_) => controller.refreshAfterEdit()),
          ),
          _buildQuickButton(
            icon: Icons.photo_outlined,
            label: 'Photo',
            color: const Color(0xFFEC4899),
            onTap: () => _pickPhotos(),
          ),
        ],
      ),
    );
  }
  Future<void> _pickPhotos() async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      if (images.isEmpty) return;
      final db = DbTimeloom.to;
      final now = DateTime.now().toIso8601String();
      final recordId = await db.insertRecord(
        RecordEntity(
          type: RecordType.media,
          scheduledAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );
      if (recordId < 0) {
        errorToast('Failed to save photos');
        return;
      }
      for (var i = 0; i < images.length; i++) {
        await db.insertMediaFile(
          MediaFileEntity(
            recordId: recordId,
            localPath: images[i].path,
            mediaType: MediaType.image,
            sortOrder: i,
          ),
        );
      }
      successToast('Photos saved');
      controller.loadRecords();
    } catch (e) {
      errorToast('Failed to pick photos');
    }
  }
  Future<void> _pickVideos() async {
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(source: ImageSource.gallery);
      if (video == null) return;
      final db = DbTimeloom.to;
      final now = DateTime.now().toIso8601String();
      final recordId = await db.insertRecord(
        RecordEntity(
          type: RecordType.media,
          scheduledAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );
      if (recordId < 0) {
        errorToast('Failed to save video');
        return;
      }
      await db.insertMediaFile(
        MediaFileEntity(
          recordId: recordId,
          localPath: video.path,
          mediaType: MediaType.video,
          sortOrder: 0,
        ),
      );
      successToast('Video saved');
      controller.loadRecords();
    } catch (e) {
      errorToast('Failed to pick video');
    }
  }
  Future<void> _recordAudio() async {
    try {
      final audioPath = await Get.bottomSheet<String?>(
        const TimeloomAudioRecordSheet(),
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
      );
      if (audioPath == null || audioPath.isEmpty) return;
      final db = DbTimeloom.to;
      final now = DateTime.now().toIso8601String();
      final recordId = await db.insertRecord(
        RecordEntity(
          type: RecordType.media,
          scheduledAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );
      if (recordId < 0) {
        errorToast('Failed to save audio');
        return;
      }
      await db.insertMediaFile(
        MediaFileEntity(
          recordId: recordId,
          localPath: audioPath,
          mediaType: MediaType.audio,
          sortOrder: 0,
        ),
      );
      successToast('Audio saved');
      controller.loadRecords();
    } catch (e) {
      errorToast('Failed to record audio');
    }
  }
  Future<void> _pickAttachment() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.path == null) {
        errorToast('No file path available');
        return;
      }
      final appDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${appDir.path}/attachments');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      final fileName = '${const Uuid().v4()}${p.extension(file.name)}';
      final targetPath = '${targetDir.path}/$fileName';
      await File(file.path!).copy(targetPath);
      final fileSize = file.size;
      final fileType = p.extension(file.name).replaceFirst('.', '');
      final db = DbTimeloom.to;
      final now = DateTime.now().toIso8601String();
      final recordId = await db.insertRecord(
        RecordEntity(
          type: RecordType.attachment,
          scheduledAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );
      if (recordId < 0) {
        errorToast('Failed to save attachment');
        return;
      }
      await db.insertAttachmentRecord(
        AttachmentRecordEntity(
          recordId: recordId,
          fileName: file.name,
          fileSize: fileSize,
          fileType: fileType,
          localPath: targetPath,
        ),
      );
      successToast('Attachment saved');
      controller.loadRecords();
    } catch (e) {
      errorToast('Failed to pick attachment');
    }
  }
  Widget _buildQuickButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.w),
              ),
              child: Icon(icon, size: 20.w, color: color),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: surfaceColor,
      width: 280.w,
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(),
            Obx(() => _buildDrawerTabs()),
            Expanded(child: Obx(() => _buildDrawerContent())),
          ],
        ),
      ),
    );
  }
  Widget _buildDrawerHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
      child: Row(
        children: [
          _buildLogo(),
          const Spacer(),
          GestureDetector(
            onTap: () => Get.back(),
            child: Icon(Icons.close, size: 20.w, color: textSecondaryColor),
          ),
        ],
      ),
    );
  }
  Widget _buildDrawerTabs() {
    final tabs = ['Type', 'Date', 'Tags'];
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10.w),
      ),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final isSelected = controller.sidebarTabIndex.value == e.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => controller.onSidebarTabChanged(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.all(3.w),
                padding: EdgeInsets.symmetric(vertical: 7.h),
                decoration: BoxDecoration(
                  color: isSelected ? surfaceColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.w),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  e.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? primaryColor : textSecondaryColor,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  Widget _buildDrawerContent() {
    switch (controller.sidebarTabIndex.value) {
      case 0:
        return _buildTypeFilter();
      case 1:
        return _buildDateTab();
      case 2:
        return _buildTagsFilter();
      default:
        return const SizedBox();
    }
  }
  Widget _buildDateTab() {
    return Obx(() {
      final now = DateTime.now();
      final year = controller.calendarYear.value;
      final month = controller.calendarMonth.value;
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final firstWeekday = DateTime(year, month, 1).weekday % 7;
      final parts = controller.selectedDate.value.split('-');
      int? selectedDay;
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y == year && m == month) selectedDay = d;
      }
      return ListView(
        padding: EdgeInsets.only(bottom: 16.h),
        children: [
          if (controller.selectedDate.value != TimeloomHomeLogic.todayDate)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              child: GestureDetector(
                onTap: controller.onJumpToToday,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.w),
                  ),
                  child: Center(
                    child: Text(
                      'Back to Today',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          CalendarView(
            monthTitle: controller.calendarMonthTitle,
            daysInMonth: daysInMonth,
            firstWeekdayOfMonth: firstWeekday,
            markedDates: controller.markedDates,
            selectedDay: selectedDay,
            isToday: (day) =>
                year == now.year && month == now.month && day == now.day,
            onPreviousMonth: controller.onPreviousMonth,
            onNextMonth: controller.onNextMonth,
            onDaySelected: controller.onDateSelected,
          ),
        ],
      );
    });
  }
  Widget _buildTypeFilter() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      children: [
        _buildTypeItem(
          icon: Icons.all_inclusive,
          label: 'All Notes',
          type: HomeFilter.all,
          color: primaryColor,
        ),
        _buildTypeItem(
          icon: Icons.sticky_note_2_outlined,
          label: 'Sticker',
          type: HomeFilter.sticker,
          color: const Color(0xFF3D4F8C),
        ),
        _buildTypeItem(
          icon: Icons.description_outlined,
          label: 'Note',
          type: HomeFilter.richNote,
          color: const Color(0xFF8B5CF6),
        ),
        _buildExpandableTypeItem(),
        _buildTypeItem(
          icon: Icons.sentiment_satisfied_outlined,
          label: 'Mood',
          type: HomeFilter.mood,
          color: const Color(0xFFC9A227),
        ),
        _buildTypeItem(
          icon: Icons.photo_outlined,
          label: 'Photo',
          type: HomeFilter.media,
          color: const Color(0xFFEC4899),
        ),
        _buildTypeItem(
          icon: Icons.link_outlined,
          label: 'Link',
          type: HomeFilter.link,
          color: const Color(0xFF0EA5E9),
        ),
        _buildTypeItem(
          icon: Icons.attach_file_outlined,
          label: 'Attachment',
          type: HomeFilter.attachment,
          color: const Color(0xFFF59E0B),
        ),
      ],
    );
  }
  Widget _buildTypeItem({
    required IconData icon,
    required String label,
    required HomeFilter type,
    required Color color,
  }) {
    return Obx(() {
      final isSelected = controller.currentFilter.value == type;
      return GestureDetector(
        onTap: () => controller.onFilterChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.symmetric(vertical: 2.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10.w),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18.w, color: isSelected ? primaryColor : color),
              SizedBox(width: 10.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isSelected ? primaryColor : textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Icon(Icons.check, size: 16.w, color: primaryColor),
              ],
            ],
          ),
        ),
      );
    });
  }
  Widget _buildExpandableTypeItem() {
    return Obx(() {
      final isExpanded = controller.isChecklistExpanded.value;
      final isSelected =
          controller.currentFilter.value == HomeFilter.checklist ||
          controller.currentFilter.value == HomeFilter.checklistIncomplete ||
          controller.currentFilter.value == HomeFilter.checklistComplete;
      return Column(
        children: [
          GestureDetector(
            onTap: controller.onChecklistToggle,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 2.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10.w),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.checklist_outlined,
                    size: 18.w,
                    color: isSelected ? primaryColor : const Color(0xFF5B8A5B),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Checklist',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isSelected ? primaryColor : textColor,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18.w,
                    color: textSecondaryColor,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            _buildSubTypeItem(
              label: 'Incomplete',
              type: HomeFilter.checklistIncomplete,
            ),
            _buildSubTypeItem(
              label: 'Complete',
              type: HomeFilter.checklistComplete,
            ),
          ],
        ],
      );
    });
  }
  Widget _buildSubTypeItem({required String label, required HomeFilter type}) {
    return Obx(() {
      final isSelected = controller.currentFilter.value == type;
      return GestureDetector(
        onTap: () => controller.onFilterChanged(type),
        child: Container(
          margin: EdgeInsets.only(left: 28.w, top: 2.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10.w),
          ),
          child: Row(
            children: [
              Container(
                width: 4.w,
                height: 4.w,
                decoration: BoxDecoration(
                  color: textSecondaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: isSelected ? primaryColor : textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Icon(Icons.check, size: 14.w, color: primaryColor),
              ],
            ],
          ),
        ),
      );
    });
  }
  Widget _buildTagsFilter() {
    return Obx(() {
      if (controller.tags.isEmpty) {
        return Center(
          child: Text(
            'No tags yet',
            style: TextStyle(fontSize: 14.sp, color: textSecondaryColor),
          ),
        );
      }
      return ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        children: [
          Text(
            'All Tags',
            style: TextStyle(
              fontSize: 12.sp,
              color: textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: controller.tags.map((tag) {
              final isSelected = controller.selectedTagId.value == tag.id;
              return GestureDetector(
                onTap: () =>
                    controller.onTagSelected(isSelected ? null : tag.id),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withValues(alpha: 0.1)
                        : bgColor,
                    borderRadius: BorderRadius.circular(20.w),
                    border: Border.all(
                      color: isSelected ? primaryColor : dividerColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        tag.name,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: isSelected ? primaryColor : textColor,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    });
  }
  void _showSettingsDialog() {
    Get.dialog<void>(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20.w),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.w),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.w),
                      ),
                      child: Icon(
                        Icons.settings_outlined,
                        size: 18.w,
                        color: primaryColor,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12.w),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16.w,
                        color: textSecondaryColor,
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'Version',
                        style: TextStyle(fontSize: 14.sp, color: textColor),
                      ),
                      const Spacer(),
                      Text(
                        TimeloomHomeLogic.appVersionLabel,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Divider(color: dividerColor, height: 1),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 4.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Danger zone',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: textSecondaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    GestureDetector(
                      onTap: () {
                        Get.back();
                        _confirmClearAllData();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12.w),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_sweep_outlined,
                              size: 16.w,
                              color: Colors.red,
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'Clear all data',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_right,
                              size: 16.w,
                              color: Colors.red.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(
                      backgroundColor: primaryColor.withValues(alpha: 0.08),
                      foregroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.w),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _confirmClearAllData() {
    Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20.w),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 28.h),
                child: Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_forever_outlined,
                    size: 28.w,
                    color: Colors.red,
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'Clear all data?',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text(
                  'This will permanently delete all records, tags and app-stored files. This cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: textSecondaryColor,
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(result: false),
                        style: TextButton.styleFrom(
                          backgroundColor: bgColor,
                          foregroundColor: textColor,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.w),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(result: true),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.w),
                          ),
                        ),
                        child: Text(
                          'Clear all',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        await controller.clearAllData();
      }
    });
  }
  void _showAddBottomSheet() {
    Get.bottomSheet(
      _AddRecordSheet(
        onAdded: controller.refreshAfterEdit,
        onPickPhotos: _pickPhotos,
        onPickVideos: _pickVideos,
        onRecordAudio: _recordAudio,
        onPickAttachment: _pickAttachment,
      ),
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.w)),
      ),
      isScrollControlled: true,
    );
  }
}
class _AddRecordSheet extends StatelessWidget {
  final VoidCallback onAdded;
  final VoidCallback onPickPhotos;
  final VoidCallback onPickVideos;
  final VoidCallback onRecordAudio;
  final VoidCallback onPickAttachment;
  const _AddRecordSheet({
    required this.onAdded,
    required this.onPickPhotos,
    required this.onPickVideos,
    required this.onRecordAudio,
    required this.onPickAttachment,
  });
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {
        'icon': Icons.text_fields_rounded,
        'label': 'Sticker',
        'color': const Color(0xFF4F46E5),
        'onTap': () {
          Get.back();
          Get.toNamed('/note/sticker')?.then((_) => onAdded());
        },
      },
      {
        'icon': Icons.description_rounded,
        'label': 'Note',
        'color': const Color(0xFF8B5CF6),
        'onTap': () {
          Get.back();
          Get.toNamed('/note/rich')?.then((_) => onAdded());
        },
      },
      {
        'icon': Icons.checklist_rounded,
        'label': 'Checklist',
        'color': const Color(0xFF10B981),
        'onTap': () {
          Get.back();
          Get.toNamed('/note/checklist')?.then((_) => onAdded());
        },
      },
      {
        'icon': Icons.sentiment_satisfied_rounded,
        'label': 'Mood',
        'color': const Color(0xFFF59E0B),
        'onTap': () {
          Get.back();
          Get.toNamed('/note/mood')?.then((_) => onAdded());
        },
      },
      {
        'icon': Icons.image_rounded,
        'label': 'Photo',
        'color': const Color(0xFFEC4899),
        'onTap': () {
          Get.back();
          onPickPhotos();
        },
      },
      {
        'icon': Icons.videocam_rounded,
        'label': 'Video',
        'color': const Color(0xFFEF4444),
        'onTap': () {
          Get.back();
          onPickVideos();
        },
      },
      {
        'icon': Icons.mic_rounded,
        'label': 'Audio',
        'color': const Color(0xFF06B6D4),
        'onTap': () {
          Get.back();
          onRecordAudio();
        },
      },
      {
        'icon': Icons.link_rounded,
        'label': 'Link',
        'color': const Color(0xFF3B82F6),
        'onTap': () {
          Get.back();
          Get.toNamed('/note/link')?.then((_) => onAdded());
        },
      },
      {
        'icon': Icons.attach_file_rounded,
        'label': 'Attachment',
        'color': const Color(0xFF64748B),
        'onTap': () {
          Get.back();
          onPickAttachment();
        },
      },
    ];
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom
            : 24.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: textSecondaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.grid_view_rounded,
                      size: 20.w,
                      color: primaryColor,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Basic',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 24.h,
                    crossAxisSpacing: 12.w,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildAddItem(
                      icon: item['icon'] as IconData,
                      label: item['label'] as String,
                      color: item['color'] as Color,
                      onTap: item['onTap'] as VoidCallback,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildAddItem({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: color.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(icon, size: 28.w, color: color),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
