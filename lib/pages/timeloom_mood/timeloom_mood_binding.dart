import 'package:get/get.dart';
import 'timeloom_mood_logic.dart';
class TimeloomMoodBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TimeloomMoodLogic>(() => TimeloomMoodLogic());
  }
}
