import 'package:get/get.dart';
import 'timeloom_sticker_logic.dart';
class TimeloomStickerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TimeloomStickerLogic>(() => TimeloomStickerLogic());
  }
}
