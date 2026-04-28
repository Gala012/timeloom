import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../db_timeloom/db_timeloom_entity.dart';
class TimeloomMediaViewer extends StatefulWidget {
  final List<MediaFileEntity> files;
  final int initialIndex;
  const TimeloomMediaViewer({
    super.key,
    required this.files,
    this.initialIndex = 0,
  });
  @override
  State<TimeloomMediaViewer> createState() => _TimeloomMediaViewerState();
}
class _TimeloomMediaViewerState extends State<TimeloomMediaViewer> {
  late PageController _pageController;
  late int _currentIndex;
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.files.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final file = widget.files[index];
              return Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: File(file.localPath).existsSync()
                      ? Image.file(
                          File(file.localPath),
                          fit: BoxFit.contain,
                        )
                      : Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 64.w,
                        ),
                ),
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                      const Spacer(),
                      if (widget.files.length > 1)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12.w),
                          ),
                          child: Text(
                            '${_currentIndex + 1} / ${widget.files.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
