import 'package:get/get.dart';

import 'timeloom_back_logic.dart';

class TimeloomBackBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(
      TimeloomBackLogic(),
      permanent: true,
    );
  }
}
