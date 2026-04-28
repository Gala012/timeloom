import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../db_timeloom/data.dart';
import '../../db_timeloom/db_timeloom_entity.dart';
import '../../utils/index.dart';
class TimeloomLinkLogic extends GetxController {
  late final TextEditingController urlController;
  late final TextEditingController displayTextController;
  int? recordId;
  @override
  void onInit() {
    super.onInit();
    urlController = TextEditingController();
    displayTextController = TextEditingController();
    final args = Get.arguments as Map<String, dynamic>?;
    recordId = args?['recordId'] as int?;
    if (recordId != null) {
      _loadRecord();
    }
  }
  @override
  void onClose() {
    urlController.dispose();
    displayTextController.dispose();
    super.onClose();
  }
  Future<void> _loadRecord() async {
    try {
      final link = await DbTimeloom.to.getLinkRecord(recordId!);
      if (link != null) {
        urlController.text = link.url;
        displayTextController.text = link.displayText ?? '';
      }
    } catch (e) {
      errorToast('Failed to load link');
    }
  }
  bool _isValidUrl(String url) {
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
  Future<void> onSaveTap() async {
    final url = urlController.text.trim();
    final displayText = displayTextController.text.trim();
    if (url.isEmpty) {
      errorToast('Please enter a link URL');
      return;
    }
    if (!_isValidUrl(url)) {
      errorToast('Please enter a valid URL (must start with http:// or https://)');
      return;
    }
    try {
      final db = DbTimeloom.to;
      final now = DateTime.now().toIso8601String();
      if (recordId == null) {
        final newRecordId = await db.insertRecord(
          RecordEntity(
            type: RecordType.link,
            scheduledAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
        if (newRecordId < 0) throw Exception('Insert record failed');
        await db.insertLinkRecord(
          LinkRecordEntity(
            recordId: newRecordId,
            url: url,
            displayText: displayText.isEmpty ? null : displayText,
          ),
        );
      } else {
        await db.updateRecord(
          RecordEntity(
            id: recordId,
            type: RecordType.link,
            scheduledAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await db.updateLinkRecord(
          LinkRecordEntity(
            recordId: recordId!,
            url: url,
            displayText: displayText.isEmpty ? null : displayText,
          ),
        );
      }
      successToast(recordId == null ? 'Link saved' : 'Link updated');
      Get.back(result: true);
    } catch (e) {
      debugPrint('onSaveTap error: $e');
      errorToast('Failed to save link');
    }
  }
}
