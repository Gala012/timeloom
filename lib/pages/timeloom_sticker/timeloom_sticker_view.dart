import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../main.dart';
import 'timeloom_sticker_logic.dart';
import 'timeloom_sticker_page_tags_dialog.dart';
class TimeloomStickerView extends GetView<TimeloomStickerLogic> {
  const TimeloomStickerView({super.key});
  Future<void> _openPageTagsDialog(BuildContext context) async {
    FocusScope.of(context).unfocus();
    await controller.ensureRecordLoaded();
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => TimeloomStickerPageTagsDialog(
        key: ValueKey(controller.stickerTagNames.join('|')),
        initialTags: controller.stickerTagNames.toList(),
        onConfirm: controller.applyStickerTags,
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
          Expanded(child: _buildEditor()),
          _buildStickerImageStrip(),
          _buildKeyboardToolbar(context),
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
          IconButton(
            icon: Icon(Icons.tag, color: textSecondaryColor, size: 20.w),
            onPressed: () => _openPageTagsDialog(context),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.h),
          ),
          IconButton(
            icon: Icon(
              Icons.image_outlined,
              color: textSecondaryColor,
              size: 20.w,
            ),
            onPressed: () => controller.pickStickerImages(),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.h),
          ),
          SizedBox(width: 4.w),
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
  Widget _buildStickerImageStrip() {
    return GetBuilder<TimeloomStickerLogic>(
      id: 'images',
      builder: (logic) {
        if (logic.stickerImagePaths.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          height: 96.h,
          color: bgColor,
          alignment: Alignment.centerLeft,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            scrollDirection: Axis.horizontal,
            itemCount: logic.stickerImagePaths.length,
            separatorBuilder: (_, _) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final path = logic.stickerImagePaths[index];
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.file(
                      File(path),
                      width: 72.w,
                      height: 80.h,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 72.w,
                        height: 80.h,
                        color: dividerColor,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: textSecondaryColor,
                          size: 28.w,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Material(
                      color: surfaceColor,
                      shape: const CircleBorder(),
                      elevation: 1,
                      child: InkWell(
                        onTap: () => logic.removeStickerImageAt(index),
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: EdgeInsets.all(4.w),
                          child: Icon(
                            Icons.close,
                            size: 16.w,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
  Widget _buildEditor() {
    return Container(
      color: bgColor,
      child: TextField(
        controller: controller.contentController,
        focusNode: controller.contentFocusNode,
        autofocus: true,
        maxLines: null,
        expands: true,
        keyboardType: TextInputType.multiline,
        style: TextStyle(fontSize: 15.sp, color: textColor, height: 1.6),
        decoration: InputDecoration(
          hintText: 'Write a note...',
          hintStyle: TextStyle(
            fontSize: 15.sp,
            color: textSecondaryColor.withValues(alpha: 0.6),
          ),
          contentPadding: EdgeInsets.all(16.w),
          border: InputBorder.none,
          filled: true,
          fillColor: bgColor,
        ),
      ),
    );
  }
  Widget _buildKeyboardToolbar(BuildContext context) {
    return Container(
      height: 44.h,
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: dividerColor)),
      ),
      child: Row(
        children: [
          _buildToolbarBtn(
            child: Text(
              'M+',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: textSecondaryColor,
              ),
            ),
            onTap: () => _openMarkdownSymbolSheet(context),
          ),
          Container(width: 1, height: 20.h, color: dividerColor),
          _buildToolbarBtn(
            icon: Icons.content_paste_outlined,
            onTap: () {
              controller.onPasteTap();
            },
          ),
          GetBuilder<TimeloomStickerLogic>(
            id: 'hist',
            builder: (logic) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToolbarBtn(
                  icon: Icons.undo,
                  onTap: logic.undo,
                  enabled: logic.hasUndo,
                ),
                _buildToolbarBtn(
                  icon: Icons.redo,
                  onTap: logic.redo,
                  enabled: logic.hasRedo,
                ),
              ],
            ),
          ),
          const Spacer(),
          _buildToolbarBtn(
            child: Icon(
              Icons.chevron_left,
              size: 20.w,
              color: textSecondaryColor,
            ),
            onTap: controller.moveCursorLeft,
          ),
          _buildToolbarBtn(
            child: Icon(
              Icons.chevron_right,
              size: 20.w,
              color: textSecondaryColor,
            ),
            onTap: controller.moveCursorRight,
          ),
        ],
      ),
    );
  }
  Widget _buildToolbarBtn({
    IconData? icon,
    Widget? child,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final color = enabled
        ? textSecondaryColor
        : textSecondaryColor.withValues(alpha: 0.35);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44.w,
        height: 44.h,
        alignment: Alignment.center,
        child: child ?? Icon(icon, size: 20.w, color: color),
      ),
    );
  }
  Future<void> _openMarkdownSymbolSheet(BuildContext context) async {
    controller.contentFocusNode.unfocus();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: surfaceColor,
      isScrollControlled: true,
      builder: (sheetContext) {
        void onSymbolPicked() {
          Navigator.of(sheetContext).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.contentFocusNode.requestFocus();
          });
        }
        return SafeArea(
          child: Container(
            height: 280.h,
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(top: BorderSide(color: dividerColor)),
            ),
            child: Column(
              children: [
                Container(
                  height: 40.h,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: dividerColor)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Smart Syntax',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(sheetContext).pop(),
                        child: Icon(
                          Icons.close,
                          size: 20.w,
                          color: textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(12.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Syntax',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: textSecondaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children:
                              [
                                    '#',
                                    '##',
                                    '###',
                                    '####',
                                    '-',
                                    '*',
                                    '[]',
                                    '[x]',
                                    '>',
                                    '`',
                                    '** **',
                                    '__ __',
                                    '~~ ~~',
                                  ]
                                  .map(
                                    (s) => _buildSymbolChip(
                                      s,
                                      onSelected: onSymbolPicked,
                                    ),
                                  )
                                  .toList(),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Common Symbols',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: textSecondaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children:
                              [
                                    '#',
                                    '*',
                                    '-',
                                    '\$',
                                    '&',
                                    '@',
                                    '!',
                                    '?',
                                    '/',
                                    '\\',
                                    '|',
                                    '+',
                                    '=',
                                    '%',
                                    '^',
                                    '~',
                                    '<',
                                    '>',
                                    '(',
                                    ')',
                                    '[',
                                    ']',
                                    '{',
                                    '}',
                                  ]
                                  .map(
                                    (s) => _buildSymbolChip(
                                      s,
                                      onSelected: onSymbolPicked,
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildSymbolChip(String symbol, {required VoidCallback onSelected}) {
    return GestureDetector(
      onTap: () {
        controller.insertSymbol(symbol);
        onSelected();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6.w),
          border: Border.all(color: dividerColor),
        ),
        child: Text(
          symbol,
          style: TextStyle(
            fontSize: 13.sp,
            color: textColor,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
