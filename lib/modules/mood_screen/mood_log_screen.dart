import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mood_demo/controller/auth_controller.dart';
import 'package:mood_demo/controller/mood_controller.dart';

class MoodLogScreen extends StatefulWidget {
  @override
  _MoodLogScreenState createState() => _MoodLogScreenState();
}

class _MoodLogScreenState extends State<MoodLogScreen> {
  final RxInt _selectedMood = 3.obs;
  final _noteController = TextEditingController();
  final DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final moodController = Get.find<MoodController>();
    final authController = Get.find<AuthController>();

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Obx(() {
        // Check if there's already a mood for today
        final today = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );
        final todaysMood = moodController.moodsByDate[today];

        if (todaysMood != null && _noteController.text.isEmpty) {
          _selectedMood.value = todaysMood.rating;
          _noteController.text = todaysMood.note ?? '';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you feeling today?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 24),
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final moodRating = index + 1;
                  final isSelected = _selectedMood.value == moodRating;

                  return GestureDetector(
                    onTap: () => _selectedMood.value = moodRating,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? moodController.getMoodColor(moodRating).withOpacity(0.3)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? moodController.getMoodColor(moodRating)
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        moodController.getMoodEmoji(moodRating),
                        style: TextStyle(fontSize: 32),
                      ),
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Add a note (optional):',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'What made you feel this way?',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Obx(
                () => ElevatedButton(
                  onPressed: moodController.isLoading
                      ? null
                      : () => _saveMood(moodController, authController),
                  child: moodController.isLoading
                      ? CircularProgressIndicator()
                      : Text(todaysMood != null ? 'Update Mood' : 'Save Mood'),
                ),
              ),
            ),
            if (todaysMood != null) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You already logged your mood today. You can update it.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      }),
    );
  }

  Future<void> _saveMood(
    MoodController moodController,
    AuthController authController,
  ) async {
    if (authController.user == null) return;

    await moodController.saveMood(
      _selectedDate,
      _selectedMood.value,
      _noteController.text.isEmpty ? null : _noteController.text,
      authController.user!.uid,
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}
