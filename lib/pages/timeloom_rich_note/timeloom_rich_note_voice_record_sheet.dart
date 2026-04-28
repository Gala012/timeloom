import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../../main.dart';
class TimeloomRichNoteVoiceRecordSheet extends StatefulWidget {
  const TimeloomRichNoteVoiceRecordSheet({super.key});
  @override
  State<TimeloomRichNoteVoiceRecordSheet> createState() =>
      _TimeloomRichNoteVoiceRecordSheetState();
}
class _TimeloomRichNoteVoiceRecordSheetState
    extends State<TimeloomRichNoteVoiceRecordSheet> {
  final AudioRecorder _recorder = AudioRecorder();
  String? _path;
  bool _recording = false;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    unawaited(_recorder.dispose());
    super.dispose();
  }
  Future<String> _nextOutputPath() async {
    final base = await getApplicationDocumentsDirectory();
    final sub = Directory(p.join(base.path, 'rich_note_voice'));
    if (!sub.existsSync()) {
      sub.createSync(recursive: true);
    }
    return p.join(sub.path, 'v_${Uuid().v4()}.m4a');
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
          _error = 'Microphone not allowed';
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
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to start';
        _busy = false;
      });
    }
  }
  Future<void> _stop() async {
    if (_busy || !_recording) return;
    setState(() => _busy = true);
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
        setState(() => _error = 'No file');
      }
    } catch (_) {
      setState(() {
        _busy = false;
        _error = 'Failed to save';
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Voice',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _recording
                  ? 'Recording… tap Stop when done'
                  : 'Tap Start to begin recording',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: textSecondaryColor),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_recording)
                  FilledButton.icon(
                    onPressed: _busy ? null : _start,
                    icon: const Icon(Icons.mic, size: 20),
                    label: const Text('Start'),
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                    ),
                  )
                else
                  FilledButton.icon(
                    onPressed: _busy ? null : _stop,
                    icon: const Icon(Icons.stop, size: 20),
                    label: const Text('Stop'),
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                    ),
                  ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          if (_recording) {
                            await _recorder.cancel();
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
          ],
        ),
      ),
    );
  }
}
