import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import '../main.dart';
class TimeloomAudioPlayer extends StatefulWidget {
  final String filePath;
  final String? fileName;
  const TimeloomAudioPlayer({
    super.key,
    required this.filePath,
    this.fileName,
  });
  @override
  State<TimeloomAudioPlayer> createState() => _TimeloomAudioPlayerState();
}
class _TimeloomAudioPlayerState extends State<TimeloomAudioPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }
  Future<void> _initializePlayer() async {
    try {
      if (!File(widget.filePath).existsSync()) {
        setState(() {
          _errorMessage = 'Audio file not found';
        });
        return;
      }
      await _audioPlayer.setFilePath(widget.filePath);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load audio: $e';
        });
      }
    }
  }
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
  @override
  Widget build(BuildContext context) {
    final displayName = widget.fileName ?? p.basenameWithoutExtension(widget.filePath);
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
          if (_errorMessage != null)
            Padding(
              padding: EdgeInsets.all(32.w),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: textSecondaryColor,
                    size: 48.w,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: textSecondaryColor,
                      fontSize: 14.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            )
          else if (!_isInitialized)
            Padding(
              padding: EdgeInsets.all(32.w),
              child: const CircularProgressIndicator(),
            )
          else
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16.w),
                    ),
                    child: Icon(
                      Icons.audiotrack,
                      color: const Color(0xFF9333EA),
                      size: 64.w,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32.h),
                  StreamBuilder<Duration>(
                    stream: _audioPlayer.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final duration = _audioPlayer.duration ?? Duration.zero;
                      final progress = duration.inMilliseconds > 0
                          ? position.inMilliseconds / duration.inMilliseconds
                          : 0.0;
                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4.h,
                              thumbShape: RoundSliderThumbShape(
                                enabledThumbRadius: 8.w,
                              ),
                              overlayShape: RoundSliderOverlayShape(
                                overlayRadius: 16.w,
                              ),
                            ),
                            child: Slider(
                              value: progress.clamp(0.0, 1.0),
                              onChanged: (value) {
                                final newPosition = Duration(
                                  milliseconds: (value * duration.inMilliseconds).round(),
                                );
                                _audioPlayer.seek(newPosition);
                              },
                              activeColor: const Color(0xFF9333EA),
                              inactiveColor: dividerColor,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: textSecondaryColor,
                                  ),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 24.h),
                  StreamBuilder<PlayerState>(
                    stream: _audioPlayer.playerStateStream,
                    builder: (context, snapshot) {
                      final playerState = snapshot.data;
                      final isPlaying = playerState?.playing ?? false;
                      final processingState = playerState?.processingState;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.replay_10, size: 32.w),
                            color: textColor,
                            onPressed: () {
                              final newPosition = _audioPlayer.position - const Duration(seconds: 10);
                              _audioPlayer.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
                            },
                          ),
                          SizedBox(width: 24.w),
                          Container(
                            width: 64.w,
                            height: 64.w,
                            decoration: BoxDecoration(
                              color: const Color(0xFF9333EA),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                processingState == ProcessingState.loading ||
                                        processingState == ProcessingState.buffering
                                    ? Icons.hourglass_empty
                                    : isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                size: 32.w,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                if (isPlaying) {
                                  _audioPlayer.pause();
                                } else {
                                  _audioPlayer.play();
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 24.w),
                          IconButton(
                            icon: Icon(Icons.forward_10, size: 32.w),
                            color: textColor,
                            onPressed: () {
                              final duration = _audioPlayer.duration ?? Duration.zero;
                              final newPosition = _audioPlayer.position + const Duration(seconds: 10);
                              _audioPlayer.seek(newPosition > duration ? duration : newPosition);
                            },
                          ),
                        ],
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
}
