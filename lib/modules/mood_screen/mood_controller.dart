import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mood_demo/controller/auth_controller.dart';
import 'package:mood_demo/model/moods.dart';

class MoodController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<Mood> _moods = <Mood>[].obs;
  final RxMap<DateTime, Mood> _moodsByDate = <DateTime, Mood>{}.obs;
  final RxBool _isLoading = false.obs;
  final authController = Get.find<AuthController>();
  final RxInt currentIndex = 0.obs;

  List<Mood> get moods => _moods;

  Map<DateTime, Mood> get moodsByDate => _moodsByDate;

  bool get isLoading => _isLoading.value;

  static const List<String> moodEmojis = ['😢', '😟', '😐', '🙂', '😄'];
  static const List<Color> moodColors = [
    Color(0xFFE57373), // Red - Very sad
    Color(0xFFFFB74D), // Orange - Sad
    Color(0xFFFFD54F), // Yellow - Neutral
    Color(0xFF81C784), // Light Green - Happy
    Color(0xFF66BB6A), // Green - Very happy
  ];

  @override
  void onInit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authController.user != null) {
        loadMoods(authController.user!.uid);
      }
    });
    super.onInit();
  }

  Future<void> loadMoods(String userId) async {
    try {
      _isLoading.value = true;

      final querySnapshot = await _firestore
          .collection('moods')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      _moods.value = querySnapshot.docs
          .map((doc) => Mood.fromMap(doc.data(), doc.id))
          .toList();

      _moodsByDate.clear();
      for (var mood in _moods) {
        final dateKey = DateTime(mood.date.year, mood.date.month, mood.date.day);
        _moodsByDate[dateKey] = mood;
      }
    } catch (e) {
      String errorMessage = 'Failed to load moods';

      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Permission denied. Check Firestore rules and authentication.';
      } else if (e.toString().contains('index')) {
        errorMessage =
            'Missing Firestore index. Check Firebase Console → Firestore → Indexes.';
      }

      Get.snackbar(
        'Error',
        '$errorMessage: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> saveMood(DateTime date, int rating, String? note, String userId) async {
    try {
      _isLoading.value = true;
      final dateKey = DateTime(date.year, date.month, date.day);
      final emoji = moodEmojis[rating - 1];

      // Check if mood already exists for this date
      final existingMood = _moodsByDate[dateKey];

      if (existingMood != null) {
        // Update existing mood
        await _firestore.collection('moods').doc(existingMood.id).update({
          'rating': rating,
          'emoji': emoji,
          'note': note,
        });
      } else {
        // Create new mood
        await _firestore.collection('moods').add({
          'date': Timestamp.fromDate(dateKey),
          'rating': rating,
          'emoji': emoji,
          'note': note,
          'userId': userId,
        });
      }

      await loadMoods(userId);

      Get.snackbar(
        'Success',
        'Mood saved successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      String errorMessage = 'Failed to save mood';

      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Permission denied. Check Firestore rules and authentication.';
      } else if (e.toString().contains('index')) {
        errorMessage = 'Missing Firestore index. Check Firebase Console.';
      }

      Get.snackbar(
        'Error',
        '$errorMessage: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  double getWeeklyAverage(DateTime weekStart) {
    final weekEnd = weekStart.add(Duration(days: 7));
    final weekMoods = _moods.where((mood) {
      return mood.date.isAfter(weekStart.subtract(Duration(days: 1))) &&
          mood.date.isBefore(weekEnd);
    }).toList();

    if (weekMoods.isEmpty) return 0.0;

    final sum = weekMoods.fold(0, (prev, mood) => prev + mood.rating);
    return sum / weekMoods.length;
  }

  Color getMoodColor(int rating) {
    return moodColors[rating - 1];
  }

  String getMoodEmoji(int rating) {
    return moodEmojis[rating - 1];
  }
}
