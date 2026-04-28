import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import '../main.dart';
const double kRichNoteMediaPlaceholderH = 26;
class RichNoteImagePlaceholder extends StatelessWidget {
  const RichNoteImagePlaceholder({
    super.key,
    required this.filePath,
    required this.onTap,
  });
  final String filePath;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final thumbSize = 28.w;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: kRichNoteMediaPlaceholderH.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(6.w),
          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThumb(thumbSize),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Image',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.open_in_new, size: 13.w, color: textSecondaryColor),
          ],
        ),
      ),
    );
  }
  Widget _buildThumb(double size) {
    if (kIsWeb) {
      return _iconFallback(size);
    }
    final f = File(filePath);
    if (!f.existsSync()) {
      return _iconFallback(size);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.w),
      child: Image.file(
        f,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (BuildContext ctx, Object e, StackTrace? s) => _iconFallback(size),
      ),
    );
  }
  Widget _iconFallback(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Icon(Icons.image_outlined, color: primaryColor, size: size * 0.7),
      ),
    );
  }
}
class RichNoteFilePlaceholder extends StatelessWidget {
  const RichNoteFilePlaceholder({
    super.key,
    required this.displayName,
    required this.path,
    required this.onTap,
  });
  final String displayName;
  final String path;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final name = displayName.isEmpty ? 'File' : displayName;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: kRichNoteMediaPlaceholderH.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(6.w),
          border: Border.all(color: dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.attach_file, size: 16.w, color: primaryColor),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.open_in_new, size: 13.w, color: textSecondaryColor),
          ],
        ),
      ),
    );
  }
}
class RichNoteVoicePlaceholder extends StatelessWidget {
  const RichNoteVoicePlaceholder({
    super.key,
    required this.filePath,
    required this.onTap,
  });
  final String filePath;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: kRichNoteMediaPlaceholderH.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(6.w),
          border: Border.all(color: dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic_outlined, size: 16.w, color: primaryColor),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Voice recording',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.play_arrow, size: 15.w, color: textSecondaryColor),
          ],
        ),
      ),
    );
  }
}
class RichNoteImageLineWidget extends StatefulWidget {
  const RichNoteImageLineWidget({
    super.key,
    required this.filePath,
    required this.maxWidth,
    this.onLayoutChanged,
  });
  final String filePath;
  final double maxWidth;
  final VoidCallback? onLayoutChanged;
  @override
  State<RichNoteImageLineWidget> createState() => _RichNoteImageLineWidgetState();
}
class _RichNoteImageLineWidgetState extends State<RichNoteImageLineWidget> {
  int? _pixelW;
  int? _pixelH;
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _decodeSize();
    }
  }
  Future<void> _decodeSize() async {
    try {
      final f = File(widget.filePath);
      if (!await f.exists()) return;
      final bytes = await f.readAsBytes();
      if (bytes.isEmpty) return;
      final codec = await ui.instantiateImageCodec(bytes);
      try {
        final frame = await codec.getNextFrame();
        final w = frame.image.width;
        final h = frame.image.height;
        frame.image.dispose();
        if (!mounted) return;
        setState(() {
          _pixelW = w;
          _pixelH = h;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onLayoutChanged?.call();
          }
        });
      } finally {
        codec.dispose();
      }
    } catch (_) {
    }
  }
  double _layoutWidth(double screenW) {
    return (widget.maxWidth.isFinite ? widget.maxWidth : screenW)
        .clamp(48.0, (screenW - 32.0).clamp(48.0, 280.0));
  }
  double _boxHeight(double w, double screenH) {
    final defaultH = 150.h.clamp(110.0, 200.0);
    final maxH = (screenH * 0.45).clamp(180.0, 900.0);
    if (_pixelW == null || _pixelH == null || _pixelW! <= 0) {
      return defaultH;
    }
    final sw = _pixelW!.toDouble();
    final sH = _pixelH!.toDouble();
    final scaledH = w * sH / sw;
    if (!scaledH.isFinite || scaledH <= 0) return defaultH;
    return math.min(scaledH, maxH);
  }
  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final screenH = MediaQuery.sizeOf(context).height;
    final w = _layoutWidth(screenW);
    final h = _boxHeight(w, screenH);
    if (kIsWeb) {
      return _wrapWebStub(w, h);
    }
    final f = File(widget.filePath);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 4.h, bottom: 8.h),
          child: SizedBox(
            width: w,
            height: h,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.w),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border.all(color: dividerColor),
                ),
                child: f.existsSync()
                    ? Image.file(
                        f,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) =>
                            _errBox(w, h),
                      )
                    : _errBox(w, h),
              ),
            ),
          ),
        ),
        SizedBox(height: math.max(16.h, h * 0.08)),
      ],
    );
  }
  Widget _wrapWebStub(double w, double h) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 4.h, bottom: 8.h),
          child: SizedBox(
            width: w,
            height: h,
            child: const Center(
              child: Text(
                'Image preview unavailable',
                style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
              ),
            ),
          ),
        ),
        SizedBox(height: math.max(16.h, h * 0.08)),
      ],
    );
  }
  Widget _errBox(double w, double h) {
    return SizedBox(
      width: w,
      height: h,
      child: const Center(
        child: Text(
          'Image not found',
          style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
        ),
      ),
    );
  }
}
class RichNoteFileLineWidget extends StatelessWidget {
  const RichNoteFileLineWidget({
    super.key,
    required this.displayName,
    required this.path,
    required this.maxWidth,
  });
  final String displayName;
  final String path;
  final double maxWidth;
  @override
  Widget build(BuildContext context) {
    final name = displayName.isEmpty ? 'File' : displayName;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: path));
          },
          borderRadius: BorderRadius.circular(8.w),
          child: Container(
            width: maxWidth.clamp(48, 400),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(8.w),
              border: Border.all(color: dividerColor),
            ),
            child: Row(
              children: [
                Icon(Icons.attach_file, size: 18.w, color: primaryColor),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  'Tap to copy path',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class RichNoteVoiceLineWidget extends StatefulWidget {
  const RichNoteVoiceLineWidget({
    super.key,
    required this.filePath,
    required this.maxWidth,
  });
  final String filePath;
  final double maxWidth;
  @override
  State<RichNoteVoiceLineWidget> createState() =>
      _RichNoteVoiceLineWidgetState();
}
class _RichNoteVoiceLineWidgetState extends State<RichNoteVoiceLineWidget> {
  final AudioPlayer _player = AudioPlayer();
  bool _ready = false;
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _init();
  }
  Future<void> _init() async {
    if (kIsWeb) {
      setState(() {
        _loading = false;
        _error = 'Voice not supported';
      });
      return;
    }
    final f = File(widget.filePath);
    if (!f.existsSync()) {
      setState(() {
        _loading = false;
        _error = 'Audio not found';
      });
      return;
    }
    try {
      await _player.setFilePath(widget.filePath);
      setState(() {
        _ready = true;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Cannot load audio';
      });
    }
  }
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final w = widget.maxWidth.clamp(48.0, 400.0);
    if (_loading) {
      return SizedBox(
        width: w,
        height: 40.h,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_error != null) {
      return SizedBox(
        width: w,
        height: kRichNoteMediaPlaceholderH.h,
        child: Center(
          child: Text(
            _error!,
            style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
          ),
        ),
      );
    }
    if (!_ready) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Container(
        width: w,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(8.w),
          border: Border.all(color: dividerColor),
        ),
        child: StreamBuilder<PlayerState>(
          stream: _player.playerStateStream,
          builder: (context, snap) {
            final playing = snap.data?.playing ?? false;
            return Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () async {
                    if (playing) {
                      await _player.pause();
                    } else {
                      await _player.seek(Duration.zero);
                      await _player.play();
                    }
                  },
                  icon: Icon(
                    playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    color: primaryColor,
                    size: 28.w,
                  ),
                ),
                Expanded(
                  child: StreamBuilder<Duration?>(
                    stream: _player.positionStream,
                    initialData: Duration.zero,
                    builder: (context, posSnap) {
                      return StreamBuilder<Duration?>(
                        stream: _player.durationStream,
                        builder: (context, durSnap) {
                          final pos = posSnap.data ?? Duration.zero;
                          final dur = durSnap.data ?? Duration.zero;
                          final totalMs = dur.inMilliseconds;
                          final p = totalMs > 0
                              ? pos.inMilliseconds / totalMs
                              : 0.0;
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: p.clamp(0.0, 1.0),
                              minHeight: 3,
                              backgroundColor: dividerColor,
                              color: primaryColor,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                SizedBox(width: 6.w),
                StreamBuilder<Duration?>(
                  stream: _player.positionStream,
                  initialData: Duration.zero,
                  builder: (context, posSnap) {
                    return StreamBuilder<Duration?>(
                      stream: _player.durationStream,
                      builder: (context, durSnap) {
                        final pos = posSnap.data ?? Duration.zero;
                        final dur = durSnap.data ?? Duration.zero;
                        final a = _fmt(pos);
                        final b = _fmt(dur);
                        return Text(
                          '$a / $b',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: textSecondaryColor,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  String _fmt(Duration d) {
    final s = d.inSeconds;
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }
}
