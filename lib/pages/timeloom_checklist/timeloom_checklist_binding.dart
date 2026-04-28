import 'package:get/get.dart';
import 'timeloom_checklist_logic.dart';
class TimeloomChecklistBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TimeloomChecklistLogic>(() => TimeloomChecklistLogic());
  }
}
