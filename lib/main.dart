import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../pages/timeloom_home/timeloom_home_binding.dart';
import '../pages/timeloom_home/timeloom_home_view.dart';
import '../pages/timeloom_sticker/timeloom_sticker_binding.dart';
import '../pages/timeloom_sticker/timeloom_sticker_view.dart';
import '../pages/timeloom_rich_note/timeloom_rich_note_binding.dart';
import '../pages/timeloom_rich_note/timeloom_rich_note_view.dart';
import '../pages/timeloom_checklist/timeloom_checklist_binding.dart';
import '../pages/timeloom_checklist/timeloom_checklist_view.dart';
import '../pages/timeloom_mood/timeloom_mood_binding.dart';
import '../pages/timeloom_mood/timeloom_mood_view.dart';
import '../pages/timeloom_link/timeloom_link_binding.dart';
import '../pages/timeloom_link/timeloom_link_view.dart';
import 'db_timeloom/data.dart';
const Color primaryColor = Color(0xFF3D4F8C);
const Color secondaryColor = Color(0xFFC9A227);
const Color bgColor = Color(0xFFF6F4EF);
const Color surfaceColor = Color(0xFFFFFFFF);
const Color dividerColor = Color(0xFFE6E2D8);
const Color onPrimaryColor = Color(0xFFFFFFFF);
const Color textColor = Color(0xFF1C1B19);
const Color textSecondaryColor = Color(0xFF6B6860);
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Get.putAsync<DbTimeloom>(() => DbTimeloom().init());
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          getPages: Lines,
          initialRoute: '/home',
          theme: ThemeData(
            useMaterial3: true,
            primaryColor: primaryColor,
            scaffoldBackgroundColor: bgColor,
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              secondary: secondaryColor,
              surface: surfaceColor,
            ),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: textColor,
              ),
              backgroundColor: surfaceColor,
              iconTheme: IconThemeData(size: 22, color: textColor),
            ),
            dividerTheme: const DividerThemeData(
              thickness: 1,
              color: dividerColor,
            ),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
          ),
          builder: (context, child) {
            return GestureDetector(
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: child,
            );
          },
        );
      },
    );
  }
}
List<GetPage<dynamic>> Lines = [
  GetPage(
    name: '/home',
    page: () => const TimeloomHomeView(),
    binding: TimeloomHomeBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/note/sticker',
    page: () => const TimeloomStickerView(),
    binding: TimeloomStickerBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/note/rich',
    page: () => const TimeloomRichNoteView(),
    binding: TimeloomRichNoteBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/note/checklist',
    page: () => const TimeloomChecklistView(),
    binding: TimeloomChecklistBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/note/mood',
    page: () => const TimeloomMoodView(),
    binding: TimeloomMoodBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
  GetPage(
    name: '/note/link',
    page: () => const TimeloomLinkView(),
    binding: TimeloomLinkBinding(),
    transition: Transition.cupertino,
    popGesture: true,
    preventDuplicates: false,
  ),
];