import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../main.dart';
import 'timeloom_link_logic.dart';
class TimeloomLinkView extends GetView<TimeloomLinkLogic> {
  const TimeloomLinkView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.h),
            _buildDialogCard(),
          ],
        ),
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
          Text('Add Link', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: textColor)),
          const Spacer(),
          SizedBox(width: 36.w),
        ],
      ),
    );
  }
  Widget _buildDialogCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16.w),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18.w, color: primaryColor),
              SizedBox(width: 6.w),
              Text('Edit Link', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: textColor)),
              const Spacer(),
              GestureDetector(
                onTap: () => Get.back(),
                child: Icon(Icons.close, size: 20.w, color: textSecondaryColor),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildInputField(
            label: 'URL',
            hint: 'Enter link address',
            keyboardType: TextInputType.url,
            autofocus: true,
            controller: controller.urlController,
          ),
          SizedBox(height: 12.h),
          _buildInputField(
            label: 'Display Text',
            hint: 'Enter display text (optional)',
            controller: controller.displayTextController,
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10.w),
                      border: Border.all(color: dividerColor),
                    ),
                    child: Text('Cancel', textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, color: textSecondaryColor, fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: GestureDetector(
                  onTap: controller.onSaveTap,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(10.w),
                    ),
                    child: Text('Save', textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, color: onPrimaryColor, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildInputField({
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool autofocus = false,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: textSecondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          autofocus: autofocus,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: 14.sp, color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14.sp,
              color: textSecondaryColor.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: bgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.w),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 12.h,
            ),
          ),
        ),
      ],
    );
  }
}
