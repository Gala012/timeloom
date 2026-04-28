import 'package:get/get.dart';
import 'timeloom_rich_note_logic.dart';
class TimeloomRichNoteBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TimeloomRichNoteLogic>(() => TimeloomRichNoteLogic());
  }
}
