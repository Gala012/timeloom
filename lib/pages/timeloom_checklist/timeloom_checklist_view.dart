import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../main.dart';
import '../timeloom_sticker/timeloom_sticker_page_tags_dialog.dart';
import 'timeloom_checklist_logic.dart';
class TimeloomChecklistView extends GetView<TimeloomChecklistLogic> {
  const TimeloomChecklistView({super.key});
  void _openPageTagsDialog(BuildContext context) {
    FocusScope.of(context).unfocus();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => TimeloomStickerPageTagsDialog(
        key: ValueKey(controller.checklistTagNames.join('|')),
        initialTags: controller.checklistTagNames.toList(),
        onConfirm: controller.applyChecklistTags,
        showSaveNoteHint: controller.recordId == null,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleField(),
                  SizedBox(height: 8.h),
                  _buildDivider(),
                  SizedBox(height: 8.h),
                  _buildItemsList(),
                  _buildAddItemButton(),
                  SizedBox(height: 16.h),
                  _buildDivider(),
                  SizedBox(height: 8.h),
                  _buildDateRow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: surfaceColor,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: textColor),
            onPressed: controller.onCloseTap,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.h),
          ),
          const Spacer(),
          Text(
            'Checklist',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.tag, color: textSecondaryColor, size: 20.w),
            onPressed: () => _openPageTagsDialog(context),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.h),
          ),
          GestureDetector(
            onTap: controller.onSaveTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20.w),
              ),
              child: Icon(Icons.check, color: onPrimaryColor, size: 18.w),
            ),
          ),
          SizedBox(width: 4.w),
        ],
      ),
    );
  }
  Widget _buildTitleField() {
    return TextField(
      controller: controller.titleController,
      autofocus: true,
      style: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      decoration: InputDecoration(
        hintText: 'Title',
        hintStyle: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: textSecondaryColor.withValues(alpha: 0.5),
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: 4.h),
      ),
    );
  }
  Widget _buildDivider() {
    return Divider(color: dividerColor, height: 1, thickness: 1);
  }
  Widget _buildItemsList() {
    return Obx(
      () => Column(
        children: controller.items
            .map((item) => _buildChecklistItem(item))
            .toList(),
      ),
    );
  }
  Widget _buildChecklistItem(ChecklistItem item) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => controller.onToggleItem(item.localId),
            child: Obx(() {
              final current = controller.items.firstWhere(
                (i) => i.localId == item.localId,
                orElse: () => item,
              );
              return Icon(
                current.isCompleted
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 22.w,
                color: current.isCompleted ? primaryColor : textSecondaryColor,
              );
            }),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Obx(() {
              final current = controller.items.firstWhere(
                (i) => i.localId == item.localId,
                orElse: () => item,
              );
              return TextField(
                controller: current.textController,
                focusNode: current.focusNode,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: current.isCompleted ? textSecondaryColor : textColor,
                  decoration: current.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
                decoration: InputDecoration(
                  hintText: 'Todo item',
                  hintStyle: TextStyle(
                    fontSize: 14.sp,
                    color: textSecondaryColor.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                  isDense: true,
                ),
                onSubmitted: (_) => controller.onAddItem(),
              );
            }),
          ),
          GestureDetector(
            onTap: () => controller.onRemoveItem(item.localId),
            child: Icon(
              Icons.remove_circle_outline,
              size: 18.w,
              color: textSecondaryColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildAddItemButton() {
    return GestureDetector(
      onTap: controller.onAddItem,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 20.w,
              color: primaryColor.withValues(alpha: 0.6),
            ),
            SizedBox(width: 10.w),
            Text(
              'Add item',
              style: TextStyle(
                fontSize: 14.sp,
                color: primaryColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildDateRow() {
    return GestureDetector(
      onTap: () => _showDatePicker(),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 18.w,
              color: textSecondaryColor,
            ),
            SizedBox(width: 10.w),
            Text(
              'Date',
              style: TextStyle(fontSize: 14.sp, color: textColor),
            ),
            const Spacer(),
            Obx(
              () => Text(
                controller.scheduledLabel,
                style: TextStyle(fontSize: 14.sp, color: textSecondaryColor),
              ),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.chevron_right, size: 18.w, color: textSecondaryColor),
          ],
        ),
      ),
    );
  }
  void _showDatePicker() async {
    final now = DateTime.now();
    final initial = controller.scheduledTime.value ?? now;
    final pickedDate = await showDatePicker(
      context: Get.context!,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate == null) return;
    final pickedTime = await showTimePicker(
      context: Get.context!,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime == null) return;
    controller.scheduledTime.value = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }
}
