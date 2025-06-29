import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mood_demo/controller/auth_controller.dart';
import 'package:mood_demo/modules/calender/calender_screen.dart';
import 'package:mood_demo/modules/mood_screen/mood_controller.dart';
import 'package:mood_demo/modules/mood_screen/mood_log_screen.dart';
import 'package:mood_demo/modules/trends/trends.dart';

class MoodTrackerHome extends StatelessWidget {
  final List<Widget> _pages = [MoodLogScreen(), CalendarScreen(), TrendsScreen()];
  final controller = Get.find<MoodController>();

  MoodTrackerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mood Tracker'),
        actions: [
          Obx(() {
            final authController = Get.find<AuthController>();
            return Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  'UID: ${authController.user?.uid.substring(0, 6) ?? 'None'}...',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            );
          }),
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
