import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../components/timeloom_rich_note_controller.dart';
import '../../components/timeloom_rich_note_list_continuation_formatter.dart';
import '../../components/timeloom_rich_note_media_line_formatter.dart';
import '../../main.dart';
import '../timeloom_sticker/timeloom_sticker_page_tags_dialog.dart';
import 'timeloom_rich_note_logic.dart';
class TimeloomRichNoteView extends GetView<TimeloomRichNoteLogic> {
  const TimeloomRichNoteView({super.key});
  Future<void> _openPageTagsDialog(BuildContext context) async {
    FocusScope.of(context).unfocus();
    await controller.ensureRecordLoaded();
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => TimeloomStickerPageTagsDialog(
        key: ValueKey(controller.noteTagNames.join('|')),
        initialTags: controller.noteTagNames.toList(),
        onConfirm: controller.applyNoteTags,
        showSaveNoteHint: controller.recordId == null,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildEditor()),
            Obx(() {
              final active = Set<String>.from(controller.activeFormats);
              return _buildToolbar(controller.toolbarGroup.value, active);
            }),
          ],
        ),
      ),
    );
  }
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: surfaceColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: textColor, size: 18),
        onPressed: controller.onCloseTap,
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.tag, color: textSecondaryColor, size: 20.w),
          onPressed: () => _openPageTagsDialog(context),
        ),
        GetBuilder<TimeloomRichNoteLogic>(
          id: 'hist',
          builder: (logic) => IconButton(
            icon: Icon(
              Icons.undo,
              color: logic.hasUndo
                  ? textSecondaryColor
                  : textSecondaryColor.withValues(alpha: 0.35),
              size: 20.w,
            ),
            onPressed: logic.hasUndo ? logic.undo : null,
          ),
        ),
        IconButton(
          icon: Icon(Icons.save_outlined, color: primaryColor, size: 20.w),
          onPressed: controller.onSaveTap,
        ),
        SizedBox(width: 4.w),
      ],
    );
  }
  Widget _buildEditor() {
    return Stack(
      children: [
        Container(
          color: bgColor,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth - 32.w;
              if (w > 0) {
                controller.setEditorTextContentWidth(w);
              }
              return TextField(
                controller: controller.contentController,
                focusNode: controller.editorFocusNode,
                scrollController: controller.editorScrollController,
                autofocus: true,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                inputFormatters: const <TextInputFormatter>[
                  RichNoteMediaLineFormatter(),
                  RichNoteListContinuationFormatter(),
                ],
                style: TextStyle(
                  fontSize: 15.sp,
                  color: textColor,
                  height: 1.7,
                ),
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
              );
            },
          ),
        ),
        Positioned(
          right: 16.w,
          bottom: 16.h,
          child: Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(8.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 18.w,
              color: textSecondaryColor,
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildToolbar(int group, Set<String> activeFormats) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      child: Listener(
        behavior: HitTestBehavior.deferToChild,
        onPointerDown: (_) => controller.onToolbarPointerDown(),
        child: Container(
          height: 44.h,
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(top: BorderSide(color: dividerColor)),
          ),
          child: Row(
            children: [
              _buildGroupSwitchBtn(group),
              Container(width: 1, height: 22.h, color: dividerColor),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (group == 0) ..._buildTextStyleButtons(activeFormats),
                      if (group == 1) ..._buildParagraphButtons(activeFormats),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildGroupSwitchBtn(int group) {
    const icons = [Icons.title, Icons.format_list_bulleted];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      child: Container(
        height: 36.h,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8.w),
          border: Border.all(color: dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(2, (i) {
            final selected = i == group;
            final borderRadius = selected
                ? _toolbarSegmentBorderRadius(i)
                : BorderRadius.zero;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => controller.onToolbarGroup(i),
                borderRadius: borderRadius,
                child: Container(
                  width: 32.w,
                  height: 36.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? primaryColor.withValues(alpha: 0.15)
                        : null,
                    borderRadius: borderRadius,
                  ),
                  child: Icon(
                    icons[i],
                    size: 18.w,
                    color: selected ? primaryColor : textSecondaryColor,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
  BorderRadius _toolbarSegmentBorderRadius(int index) {
    final r = 6.w;
    if (index == 0) {
      return BorderRadius.only(
        topLeft: Radius.circular(r),
        bottomLeft: Radius.circular(r),
      );
    }
    if (index == 1) {
      return BorderRadius.only(
        topRight: Radius.circular(r),
        bottomRight: Radius.circular(r),
      );
    }
    return BorderRadius.circular(r);
  }
  List<Widget> _buildTextStyleButtons(Set<String> activeFormats) {
    return [
      _buildTBtn(
        label: 'B',
        bold: true,
        isActive: activeFormats.contains(kFmtBold),
        onTap: () => controller.onFormatText(kFmtBold),
      ),
      _buildTBtn(
        label: 'I',
        italic: true,
        isActive: activeFormats.contains(kFmtItalic),
        onTap: () => controller.onFormatText(kFmtItalic),
      ),
      _buildTBtn(
        label: 'U',
        underline: true,
        isActive: activeFormats.contains(kFmtUnderline),
        onTap: () => controller.onFormatText(kFmtUnderline),
      ),
      _buildTBtn(
        label: 'S',
        strikethrough: true,
        isActive: activeFormats.contains(kFmtStrike),
        onTap: () => controller.onFormatText(kFmtStrike),
      ),
      _buildIconTBtn(
        icon: Icons.highlight_outlined,
        isActive: activeFormats.contains(kFmtHighlight),
        onTap: () => controller.onFormatText(kFmtHighlight),
      ),
      _buildIconTBtn(
        icon: Icons.palette_outlined,
        isActive: activeFormats.contains(kFmtTextColor),
        onTap: controller.onTextColorToolbarTap,
      ),
      _buildIconTBtn(
        icon: Icons.format_size,
        isActive: false,
        onTap: controller.onShowTextSizeSheet,
      ),
    ];
  }
  List<Widget> _buildParagraphButtons(Set<String> activeFormats) {
    return [
      _buildIconTBtn(
        icon: Icons.format_list_bulleted,
        isActive: activeFormats.contains(kFmtBullet),
        onTap: () => controller.onParagraphFormat(kFmtBullet),
      ),
      _buildIconTBtn(
        icon: Icons.format_list_numbered,
        isActive: activeFormats.contains(kFmtOrdered),
        onTap: () => controller.onParagraphFormat(kFmtOrdered),
      ),
      _buildIconTBtn(
        icon: Icons.checklist,
        isActive: activeFormats.contains(kFmtTodo),
        onTap: () => controller.onParagraphFormat(kFmtTodo),
      ),
      _buildIconTBtn(
        icon: Icons.format_quote,
        isActive: activeFormats.contains(kFmtQuote),
        onTap: () => controller.onParagraphFormat(kFmtQuote),
      ),
      _buildIconTBtn(
        icon: Icons.looks_one_outlined,
        isActive: activeFormats.contains(kFmtH1),
        onTap: () => controller.onParagraphFormat(kFmtH1),
      ),
      _buildIconTBtn(
        icon: Icons.looks_two_outlined,
        isActive: activeFormats.contains(kFmtH2),
        onTap: () => controller.onParagraphFormat(kFmtH2),
      ),
      _buildIconTBtn(
        icon: Icons.looks_3_outlined,
        isActive: activeFormats.contains(kFmtH3),
        onTap: () => controller.onParagraphFormat(kFmtH3),
      ),
      _buildIconTBtn(
        icon: Icons.format_indent_increase,
        isActive: false,
        onTap: controller.onIndentIncrease,
      ),
      _buildIconTBtn(
        icon: Icons.format_indent_decrease,
        isActive: false,
        onTap: controller.onIndentDecrease,
      ),
    ];
  }
  Widget _buildTBtn({
    required String label,
    bool bold = false,
    bool italic = false,
    bool underline = false,
    bool strikethrough = false,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36.w,
        height: 44.h,
        alignment: Alignment.center,
        decoration: isActive
            ? BoxDecoration(color: primaryColor.withValues(alpha: 0.12))
            : null,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: isActive ? primaryColor : textSecondaryColor,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w400,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            decoration: underline
                ? TextDecoration.underline
                : strikethrough
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
      ),
    );
  }
  Widget _buildIconTBtn({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36.w,
        height: 44.h,
        alignment: Alignment.center,
        decoration: isActive
            ? BoxDecoration(color: primaryColor.withValues(alpha: 0.12))
            : null,
        child: Icon(
          icon,
          size: 19.w,
          color: isActive ? primaryColor : textSecondaryColor,
        ),
      ),
    );
  }
}
