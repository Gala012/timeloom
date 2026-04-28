import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../main.dart';
import 'timeloom_mood_logic.dart';
class TimeloomMoodView extends GetView<TimeloomMoodLogic> {
  const TimeloomMoodView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: Obx(() => controller.tabIndex.value == 0
                ? _buildStickersTab()
                : _buildEmojiTab()),
          ),
        ],
      ),
    );
  }
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: surfaceColor,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: textColor),
            onPressed: () => Get.back(),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.h),
          ),
          const Spacer(),
          Text('Choose Mood', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: textColor)),
          const Spacer(),
          SizedBox(width: 36.w),
        ],
      ),
    );
  }
  Widget _buildTabs() {
    return Container(
      color: surfaceColor,
      child: Obx(() => Row(
        children: [
          _buildTab('Sticker', 0),
          _buildTab('Emoji', 1),
        ],
      )),
    );
  }
  Widget _buildTab(String label, int index) {
    final isSelected = controller.tabIndex.value == index;
    return GestureDetector(
      onTap: () => controller.onTabChanged(index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? primaryColor : textSecondaryColor,
          ),
        ),
      ),
    );
  }
  Widget _buildStickersTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Expression Series'),
          SizedBox(height: 10.h),
          _buildEmojiGrid(controller.catStickers),
          SizedBox(height: 20.h),
          _buildSectionTitle('Lifestyle'),
          SizedBox(height: 10.h),
          _buildEmojiGrid(controller.sceneStickers),
        ],
      ),
    );
  }
  Widget _buildEmojiTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: _buildEmojiGrid(controller.emojis, isEmoji: true),
    );
  }
  Widget _buildSectionTitle(String title) {
    return Text(title, style: TextStyle(fontSize: 12.sp, color: textSecondaryColor, fontWeight: FontWeight.w600, letterSpacing: 0.3));
  }
  Widget _buildEmojiGrid(List<String> items, {bool isEmoji = false}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8.h,
        crossAxisSpacing: 8.w,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (_, index) {
        final emoji = items[index];
        return GestureDetector(
          onTap: () => isEmoji
              ? controller.onEmojiSelected(emoji)
              : controller.onStickerSelected(emoji),
          child: Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12.w),
              border: Border.all(color: dividerColor),
            ),
            child: Center(
              child: Text(emoji, style: TextStyle(fontSize: 28.sp)),
            ),
          ),
        );
      },
    );
  }
}
