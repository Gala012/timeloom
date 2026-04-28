import 'package:get/get.dart';
import 'timeloom_link_logic.dart';
class TimeloomLinkBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TimeloomLinkLogic>(() => TimeloomLinkLogic());
  }
}
