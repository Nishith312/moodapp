import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mood_demo/controller/auth_controller.dart';
import 'package:mood_demo/model/moods.dart';
import 'package:mood_demo/modules/mood_screen/mood_controller.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  CalendarScreenState createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  final Rx<DateTime> _focusedDay = DateTime.now().obs;
  final Rx<DateTime?> _selectedDay = Rx<DateTime>(
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
  );

  // Controllers for mood input
  final RxInt _selectedMood = 3.obs;
  final _noteController = TextEditingController();
  final RxBool _isEditingMood = false.obs;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moodController = Get.find<MoodController>();

    return Obx(
      () => ListView(
        children: [
          TableCalendar<Mood>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay.value,
            selectedDayPredicate: (day) => isSameDay(_selectedDay.value, day),
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
            },
            headerStyle: HeaderStyle(titleCentered: true),
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              markersMaxCount: 1,
              selectedDecoration: BoxDecoration(
                color: Colors.blue[400],
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final mood =
                    moodController.moodsByDate[DateTime(day.year, day.month, day.day)];
                if (mood != null) {
                  return Container(
                    margin: EdgeInsets.all(4),
                    child: Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          CircleAvatar(
                            radius: 4,
                            backgroundColor: moodController.getMoodColor(mood.rating),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return null;
              },
              todayBuilder: (context, day, focusedDay) {
                final mood =
                    moodController.moodsByDate[DateTime(day.year, day.month, day.day)];
                return Container(
                  margin: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: mood != null
                        ? moodController.getMoodColor(mood.rating)
                        : Colors.blueAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
              selectedBuilder: (context, day, focusedDay) {
                final mood =
                    moodController.moodsByDate[DateTime(day.year, day.month, day.day)];
                return Container(
                  margin: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: mood != null
                        ? moodController.getMoodColor(mood.rating)
                        : Colors.blue[400],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue[600]!, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              final dateKey = DateTime(
                selectedDay.year,
                selectedDay.month,
                selectedDay.day,
              );
              _selectedDay.value = dateKey;
              _focusedDay.value = focusedDay;
              _isEditingMood.value = false;

              // Load existing mood data if available
              final existingMood = moodController.moodsByDate[dateKey];
              if (existingMood != null) {
                _selectedMood.value = existingMood.rating;
                _noteController.text = existingMood.note ?? '';
              } else {
                _selectedMood.value = 3;
                _noteController.clear();
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay.value = focusedDay;
            },
          ),

          SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final rating = index + 1;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: moodController.getMoodColor(rating),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(moodController.getMoodEmoji(rating)),
                  SizedBox(width: 10),
                ],
              );
            }),
          ),

          SizedBox(height: 16),

          // Selected day details and mood input
          if (_selectedDay.value != null) ...[_buildSelectedDayContent(moodController)],
        ],
      ),
    );
  }

  Widget _buildSelectedDayContent(MoodController moodController) {
    final mood = moodController.moodsByDate[_selectedDay.value!];
    final authController = Get.find<AuthController>();

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM d, y').format(_selectedDay.value!),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (mood != null && !_isEditingMood.value)
                TextButton.icon(
                  onPressed: () => _isEditingMood.value = true,
                  icon: Icon(Icons.edit),
                  label: Text('Edit'),
                ),
            ],
          ),

          SizedBox(height: 16),

          // Show existing mood or editing interface
          Obx(() {
            if (_isEditingMood.value || mood == null) {
              return _buildMoodInputInterface(moodController, authController, mood);
            } else {
              return _buildMoodDisplay(moodController, mood);
            }
          }),
        ],
      ),
    );
  }

  Widget _buildMoodDisplay(MoodController moodController, Mood mood) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(mood.emoji, style: TextStyle(fontSize: 48)),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rating: ${mood.rating}/5'),
                    Text(
                      'Mood: ${_getMoodLabel(mood.rating)}',
                      style: TextStyle(
                        color: moodController.getMoodColor(mood.rating),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (mood.note != null && mood.note!.isNotEmpty) ...[
              SizedBox(height: 16),
              Text('Note:', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 8),
              Text(mood.note!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMoodInputInterface(
    MoodController moodController,
    AuthController authController,
    Mood? existingMood,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              existingMood != null ? 'Update your mood:' : 'How were you feeling?',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            SizedBox(height: 16),

            // Mood selector
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final moodRating = index + 1;
                  final isSelected = _selectedMood.value == moodRating;

                  return GestureDetector(
                    onTap: () => _selectedMood.value = moodRating,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? moodController.getMoodColor(moodRating).withOpacity(0.3)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? moodController.getMoodColor(moodRating)
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        moodController.getMoodEmoji(moodRating),
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  );
                }),
              ),
            ),

            SizedBox(height: 16),

            // Note input
            Text('Add a note (optional):', style: Theme.of(context).textTheme.titleSmall),
            SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'What made you feel this way?',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
            ),

            SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => ElevatedButton(
                      onPressed: moodController.isLoading
                          ? null
                          : () => _saveMood(moodController, authController),
                      child: moodController.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(existingMood != null ? 'Update Mood' : 'Save Mood'),
                    ),
                  ),
                ),
                if (existingMood != null) ...[
                  SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _isEditingMood.value = false,
                    child: Text('Cancel'),
                  ),
                ],
              ],
            ),

            if (existingMood == null) ...[
              SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  _selectedMood.value = 3;
                  _noteController.clear();
                },
                child: Text('Clear'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveMood(
    MoodController moodController,
    AuthController authController,
  ) async {
    if (authController.user == null || _selectedDay.value == null) return;

    final success = await moodController.saveMood(
      _selectedDay.value!,
      _selectedMood.value,
      _noteController.text.isEmpty ? null : _noteController.text,
      authController.user!.uid,
    );

    if (success) {
      _isEditingMood.value = false;
    }
  }

  String _getMoodLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Very Sad';
      case 2:
        return 'Sad';
      case 3:
        return 'Neutral';
      case 4:
        return 'Happy';
      case 5:
        return 'Very Happy';
      default:
        return 'Unknown';
    }
  }
}
