import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mood_demo/controller/auth_controller.dart';
import 'package:mood_demo/controller/mood_controller.dart';
import 'package:mood_demo/modules/calender/calender_screen.dart';
import 'package:mood_demo/modules/mood_screen/mood_log_screen.dart';
import 'package:mood_demo/modules/trends/trends.dart';

class MoodTrackerHome extends StatefulWidget {
  const MoodTrackerHome({super.key});

  @override
  State<MoodTrackerHome> createState() => _MoodTrackerHomeState();
}

class _MoodTrackerHomeState extends State<MoodTrackerHome> {
  final List<Widget> _pages = [MoodLogScreen(), CalendarScreen(), TrendsScreen()];

  final controller = Get.find<MoodController>();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.find<AuthController>().user != null) {
        controller.loadMoods(Get.find<AuthController>().user!.uid);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mood Tracker'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Get.find<AuthController>().signOut();
            },
          ),
        ],
      ),
      body: Obx(() => _pages[controller.currentIndex.value]),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: controller.currentIndex.value,
          onTap: (index) => controller.currentIndex.value = index,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.mood), label: 'Log Mood'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
            BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Trends'),
          ],
        ),
      ),
    );
  }
}
