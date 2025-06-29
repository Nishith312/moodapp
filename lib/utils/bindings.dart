import 'package:get/get.dart';
import 'package:mood_demo/controller/auth_controller.dart';
import 'package:mood_demo/modules/mood_screen/mood_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<MoodController>(MoodController(), permanent: true);
  }
}
