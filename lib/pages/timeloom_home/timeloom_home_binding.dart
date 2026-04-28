import 'package:get/get.dart';
import 'timeloom_home_logic.dart';
class TimeloomHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TimeloomHomeLogic>(() => TimeloomHomeLogic());
  }
}
