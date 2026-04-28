import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../main.dart';
import '../../db_timeloom/data.dart';
import '../../db_timeloom/db_timeloom_entity.dart';
class TimeloomStickerPageTagsDialog extends StatefulWidget {
  const TimeloomStickerPageTagsDialog({
    super.key,
    required this.initialTags,
    required this.onConfirm,
    this.showSaveNoteHint = false,
  });
  final List<String> initialTags;
  final Future<void> Function(List<String> tags) onConfirm;
  final bool showSaveNoteHint;
  @override
  State<TimeloomStickerPageTagsDialog> createState() =>
      _TimeloomStickerPageTagsDialogState();
}
class _TimeloomStickerPageTagsDialogState
    extends State<TimeloomStickerPageTagsDialog> {
  List<TagEntity> _allTags = [];
  late Set<String> _selectedNames;
  late final TextEditingController _input;
  late final FocusNode _inputFocus;
  @override
  void initState() {
    super.initState();
    _selectedNames = Set<String>.from(widget.initialTags);
    _input = TextEditingController();
    _inputFocus = FocusNode();
    _loadAllTags();
  }
  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }
  Future<void> _loadAllTags() async {
    final list = await DbTimeloom.to.getTags();
    if (!mounted) return;
    setState(() => _allTags = list);
  }
  Future<void> _addNewTag() async {
    final name = _input.text.trim();
    if (name.isEmpty) return;
    await DbTimeloom.to.insertTag(TagEntity(name: name));
    _input.clear();
    _inputFocus.unfocus();
    await _loadAllTags();
    if (!mounted) return;
    setState(() => _selectedNames.add(name));
  }
  void _toggleTag(String name) {
    setState(() {
      if (_selectedNames.contains(name)) {
        _selectedNames.remove(name);
      } else {
        _selectedNames.add(name);
      }
    });
  }
  Future<void> _deleteGlobalTag(TagEntity tag) async {
    await DbTimeloom.to.deleteTag(tag.id!);
    if (!mounted) return;
    setState(() => _selectedNames.remove(tag.name));
    await _loadAllTags();
  }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: surfaceColor,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            SizedBox(height: 16.h),
            _buildNewTagRow(),
            SizedBox(height: 16.h),
            _buildAllTagsList(),
            if (widget.showSaveNoteHint) ...[
              SizedBox(height: 10.h),
              Text(
                'Tags are stored when you save the note.',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: textSecondaryColor,
                  height: 1.35,
                ),
              ),
            ],
            SizedBox(height: 20.h),
            _buildActions(context),
          ],
        ),
      ),
    );
  }
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.label_outline, color: primaryColor, size: 22.w),
        SizedBox(width: 8.w),
        Text(
          'Page tags',
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.close, color: textSecondaryColor, size: 22.w),
          onPressed: () => Navigator.of(context).pop(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
  Widget _buildNewTagRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40.h,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: dividerColor),
            ),
            child: TextField(
              controller: _input,
              focusNode: _inputFocus,
              style: TextStyle(fontSize: 14.sp, color: textColor),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'New tag',
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  color: textSecondaryColor.withValues(alpha: 0.55),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 10.h,
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addNewTag(),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        GestureDetector(
          onTap: _addNewTag,
          child: Container(
            height: 40.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(10.r),
            ),
            alignment: Alignment.center,
            child: Text(
              'Add',
              style: TextStyle(
                fontSize: 14.sp,
                color: onPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildAllTagsList() {
    if (_allTags.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Text(
          'No tags yet. Add one above.',
          style: TextStyle(fontSize: 13.sp, color: textSecondaryColor),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Tags',
          style: TextStyle(
            fontSize: 12.sp,
            color: textSecondaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 10.h),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.28,
          ),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: _allTags.map(_buildTagChip).toList(),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildTagChip(TagEntity tag) {
    final isSelected = _selectedNames.contains(tag.name);
    return GestureDetector(
      onTap: () => _toggleTag(tag.name),
      child: Container(
        padding: EdgeInsets.only(
          left: 12.w,
          right: 4.w,
          top: 7.h,
          bottom: 7.h,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : bgColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? primaryColor : dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#${tag.name}',
              style: TextStyle(
                fontSize: 13.sp,
                color: isSelected ? onPrimaryColor : textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            SizedBox(width: 4.w),
            GestureDetector(
              onTap: () => _deleteGlobalTag(tag),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Icon(
                  Icons.close,
                  size: 14.w,
                  color: isSelected
                      ? onPrimaryColor.withValues(alpha: 0.75)
                      : textSecondaryColor.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor,
              side: BorderSide(color: dividerColor),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text('Cancel', style: TextStyle(fontSize: 15.sp)),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: FilledButton(
            onPressed: () async {
              await widget.onConfirm(_selectedNames.toList());
              if (context.mounted) Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: textColor,
              foregroundColor: surfaceColor,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text('Done', style: TextStyle(fontSize: 15.sp)),
          ),
        ),
      ],
    );
  }
}
