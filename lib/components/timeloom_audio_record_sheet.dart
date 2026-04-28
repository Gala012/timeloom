import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../main.dart';
class TimeloomAudioRecordSheet extends StatefulWidget {
  const TimeloomAudioRecordSheet({super.key});
  @override
  State<TimeloomAudioRecordSheet> createState() =>
      _TimeloomAudioRecordSheetState();
}
class _TimeloomAudioRecordSheetState extends State<TimeloomAudioRecordSheet> {
  final AudioRecorder _recorder = AudioRecorder();
  String? _path;
  bool _recording = false;
  bool _busy = false;
  String? _error;
  int _recordingSeconds = 0;
  Timer? _timer;
  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_recorder.dispose());
    super.dispose();
  }
  Future<String> _nextOutputPath() async {
    final base = await getApplicationDocumentsDirectory();
    final sub = Directory(p.join(base.path, 'media_audios'));
    if (!sub.existsSync()) {
      sub.createSync(recursive: true);
    }
    return p.join(sub.path, '${const Uuid().v4()}.m4a');
  }
  Future<void> _start() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = await _recorder.hasPermission();
      if (!ok) {
        setState(() {
          _error = 'Microphone permission denied';
          _busy = false;
        });
        return;
      }
      final out = await _nextOutputPath();
      _path = out;
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: out,
      );
      setState(() {
        _recording = true;
        _busy = false;
        _recordingSeconds = 0;
      });
      _startTimer();
    } catch (e) {
      setState(() {
        _error = 'Failed to start recording';
        _busy = false;
      });
    }
  }
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingSeconds++;
        });
      }
    });
  }
  Future<void> _stop() async {
    if (_busy || !_recording) return;
    setState(() => _busy = true);
    _timer?.cancel();
    try {
      final out = await _recorder.stop();
      setState(() {
        _recording = false;
        _busy = false;
      });
      final use = out ?? _path;
      if (use != null && use.isNotEmpty) {
        Get.back<String?>(result: use);
      } else {
        setState(() => _error = 'Failed to save recording');
      }
    } catch (_) {
      setState(() {
        _busy = false;
        _error = 'Failed to save recording';
      });
    }
  }
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.w)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12.h),
          Container(
            width: 36.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE6E2D8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                Text(
                  'Record Audio',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18.sp,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  _recording
                      ? 'Recording in progress...'
                      : 'Tap the button to start recording',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: textSecondaryColor,
                  ),
                ),
                if (_error != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
                SizedBox(height: 32.h),
                Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    color: _recording
                        ? const Color(0xFF9333EA).withValues(alpha: 0.1)
                        : dividerColor,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.mic,
                        size: 48.w,
                        color: _recording
                            ? const Color(0xFF9333EA)
                            : textSecondaryColor,
                      ),
                      if (_recording)
                        SizedBox(
                          width: 100.w,
                          height: 100.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF9333EA).withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                if (_recording)
                  Text(
                    _formatDuration(_recordingSeconds),
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w300,
                      color: const Color(0xFF9333EA),
                      fontFeatures: const [
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  )
                else
                  Text(
                    '00:00',
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w300,
                      color: textSecondaryColor,
                      fontFeatures: const [
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                SizedBox(height: 32.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_recording)
                      ElevatedButton.icon(
                        onPressed: _busy ? null : _start,
                        icon: Icon(Icons.mic, size: 20.w),
                        label: const Text('Start Recording'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9333EA),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 12.h,
                          ),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _busy ? null : _stop,
                        icon: Icon(Icons.stop, size: 20.w),
                        label: const Text('Stop & Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9333EA),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 12.h,
                          ),
                        ),
                      ),
                    SizedBox(width: 12.w),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              if (_recording) {
                                await _recorder.cancel();
                                _timer?.cancel();
                                setState(() {
                                  _recording = false;
                                });
                              }
                              Get.back<String?>();
                            },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
