import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../db_timeloom/data.dart';
import '../../db_timeloom/db_timeloom_entity.dart';
import '../../main.dart';
import '../../utils/index.dart';
class TimeloomMoodLogic extends GetxController {
  final tabIndex = 0.obs;
  final selectedEmoji = RxnString();
  int? recordId;
  String? _existingText;
  final catStickers = [
    '😺', '😸', '😹', '😻', '😼', '😽', '🙀', '😿', '😾', '🐱',
  ];
  final sceneStickers = [
    '🍺', '🎵', '📷', '🍣', '✈️', '🏋️', '🎮', '📚', '☕',
    '🌙', '🌈', '🎉',
  ];
  final emojis = [
    '😀', '😂', '🥹', '😍', '🤔', '😴', '😎', '🥳', '😭', '😤',
    '🤩', '😊', '🙃', '😅', '🤣', '😇', '🥰', '😋', '😛', '😜',
    '🤪', '😁', '😆', '😃', '😄', '😉', '🤗', '😏', '😒', '😞',
  ];
  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    recordId = args?['recordId'] as int?;
    if (recordId != null) {
      _loadAndEditRecord();
    }
  }
  Future<void> _loadAndEditRecord() async {
    try {
      final mood = await DbTimeloom.to.getMoodRecord(recordId!);
      if (mood != null) {
        selectedEmoji.value = mood.stickerKey;
        _existingText = mood.text;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.dialog(
            MoodTextDialog(
              emoji: mood.stickerKey,
              initialText: mood.text,
              onSave: (text) => _saveMood(
                stickerKey: mood.stickerKey,
                stickerType: mood.stickerType,
                text: text,
              ),
            ),
            barrierDismissible: false,
          );
        });
      }
    } catch (e) {
      errorToast('Failed to load mood');
    }
  }
  void onTabChanged(int index) {
    tabIndex.value = index;
  }
  void onStickerSelected(String emoji) {
    selectedEmoji.value = emoji;
    Get.dialog(
      MoodTextDialog(
        emoji: emoji,
        initialText: _existingText,
        onSave: (text) => _saveMood(
          stickerKey: emoji,
          stickerType: StickerType.sticker,
          text: text,
        ),
      ),
      barrierDismissible: false,
    );
  }
  void onEmojiSelected(String emoji) {
    selectedEmoji.value = emoji;
    Get.dialog(
      MoodTextDialog(
        emoji: emoji,
        initialText: _existingText,
        onSave: (text) => _saveMood(
          stickerKey: emoji,
          stickerType: StickerType.emoji,
          text: text,
        ),
      ),
      barrierDismissible: false,
    );
  }
  Future<void> _saveMood({
    required String stickerKey,
    required StickerType stickerType,
    String? text,
  }) async {
    try {
      final db = DbTimeloom.to;
      final now = DateTime.now().toIso8601String();
      if (recordId == null) {
        final newRecordId = await db.insertRecord(
          RecordEntity(
            type: RecordType.mood,
            scheduledAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
        if (newRecordId < 0) throw Exception('Insert record failed');
        await db.insertMoodRecord(
          MoodRecordEntity(
            recordId: newRecordId,
            stickerType: stickerType,
            stickerKey: stickerKey,
            text: text,
          ),
        );
      } else {
        await db.updateRecord(
          RecordEntity(
            id: recordId,
            type: RecordType.mood,
            scheduledAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await db.updateMoodRecord(
          MoodRecordEntity(
            recordId: recordId!,
            stickerType: stickerType,
            stickerKey: stickerKey,
            text: text,
          ),
        );
      }
      successToast(recordId == null ? 'Mood saved' : 'Mood updated');
      Get.back();
      Get.back(result: true);
    } catch (e) {
      errorToast('Failed to save mood');
    }
  }
}
class MoodTextDialog extends StatefulWidget {
  final String emoji;
  final String? initialText;
  final Future<void> Function(String? text) onSave;
  const MoodTextDialog({
    super.key,
    required this.emoji,
    this.initialText,
    required this.onSave,
  });
  @override
  State<MoodTextDialog> createState() => _MoodTextDialogState();
}
class _MoodTextDialogState extends State<MoodTextDialog> {
  late final TextEditingController _textController;
  bool _isSaving = false;
  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText ?? '');
  }
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
  Future<void> _onSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    await widget.onSave(_textController.text.trim().isEmpty ? null : _textController.text.trim());
    if (mounted) setState(() => _isSaving = false);
  }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_outlined, size: 18, color: primaryColor),
                const SizedBox(width: 6),
                const Text(
                  'Edit Mood',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: textSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(widget.emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              autofocus: true,
              maxLines: 3,
              minLines: 2,
              style: const TextStyle(fontSize: 14, color: textColor),
              decoration: InputDecoration(
                hintText: 'How are you feeling?',
                hintStyle: const TextStyle(color: textSecondaryColor),
                filled: true,
                fillColor: bgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: dividerColor),
                      ),
                      child: const Text(
                        'Cancel',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _isSaving ? null : _onSave,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _isSaving
                          ? const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: onPrimaryColor,
                                ),
                              ),
                            )
                          : const Text(
                              'Save',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: onPrimaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
