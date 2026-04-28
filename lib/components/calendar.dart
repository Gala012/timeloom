import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
const _primary = Color(0xFF3D4F8C);
const _bgColor = Color(0xFFF6F4EF);
const _divider = Color(0xFFE6E2D8);
const _textColor = Color(0xFF1C1B19);
const _textSecondary = Color(0xFF6B6860);
class CalendarView extends StatelessWidget {
  final String monthTitle;
  final int daysInMonth;
  final int firstWeekdayOfMonth;
  final List<int> markedDates;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final Function(int day) isToday;
  final int? selectedDay;
  final Function(int day)? onDaySelected;
  const CalendarView({
    super.key,
    required this.monthTitle,
    required this.daysInMonth,
    required this.firstWeekdayOfMonth,
    required this.markedDates,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.isToday,
    this.selectedDay,
    this.onDaySelected,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Divider(color: _divider, height: 1, thickness: 1),
          ),
          SizedBox(height: 10.h),
          _buildWeekdayLabels(),
          SizedBox(height: 6.h),
          _buildGrid(),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 14.h, 4.w, 14.h),
      child: Row(
        children: [
          _buildNavButton(Icons.chevron_left, onPreviousMonth),
          Expanded(
            child: Text(
              monthTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textColor,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          _buildNavButton(Icons.chevron_right, onNextMonth),
        ],
      ),
    );
  }
  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: _textSecondary, size: 18.sp),
      ),
    );
  }
  Widget _buildWeekdayLabels() {
    const labels = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Row(
        children: labels.asMap().entries.map((e) {
          final isWeekend = e.key == 0 || e.key == 6;
          return Expanded(
            child: Center(
              child: Text(
                e.value,
                style: TextStyle(
                  color: isWeekend
                      ? _primary.withValues(alpha: 0.45)
                      : _textSecondary,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  Widget _buildGrid() {
    final totalCells = ((daysInMonth + firstWeekdayOfMonth) / 7).ceil() * 7;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 0.82,
        ),
        itemCount: totalCells,
        itemBuilder: (context, index) {
          final day = index - firstWeekdayOfMonth + 1;
          if (day <= 0 || day > daysInMonth) return const SizedBox();
          final col = index % 7;
          final isWeekend = col == 0 || col == 6;
          return _buildDayCell(
            day: day,
            isMarked: markedDates.contains(day),
            isCurrent: isToday(day),
            isSelected: selectedDay == day,
            isWeekend: isWeekend,
          );
        },
      ),
    );
  }
  Widget _buildDayCell({
    required int day,
    required bool isMarked,
    required bool isCurrent,
    required bool isSelected,
    required bool isWeekend,
  }) {
    Color circleBg = Colors.transparent;
    Color textCol;
    Border? border;
    if (isSelected) {
      circleBg = _primary;
      textCol = Colors.white;
    } else if (isCurrent) {
      circleBg = _primary.withValues(alpha: 0.1);
      textCol = _primary;
      border = Border.all(color: _primary.withValues(alpha: 0.4), width: 1.2);
    } else if (isWeekend) {
      textCol = _textSecondary.withValues(alpha: 0.7);
    } else {
      textCol = _textColor;
    }
    final dotColor = isSelected ? Colors.white.withValues(alpha: 0.8) : _primary;
    return GestureDetector(
      onTap: () => onDaySelected?.call(day),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              color: circleBg,
              shape: BoxShape.circle,
              border: border,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: textCol,
                  fontSize: 13.sp,
                  fontWeight: (isSelected || isCurrent)
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            ),
          ),
          SizedBox(height: 3.h),
          Container(
            width: 4.w,
            height: 4.w,
            decoration: BoxDecoration(
              color: isMarked ? dotColor : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
