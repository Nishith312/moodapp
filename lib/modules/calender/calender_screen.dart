import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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

  @override
  Widget build(BuildContext context) {
    final moodController = Get.find<MoodController>();

    return Obx(
      () => Column(
        children: [
          TableCalendar<Mood>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay.value,
            selectedDayPredicate: (day) => isSameDay(_selectedDay.value, day),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(outsideDaysVisible: false, markersMaxCount: 1),
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
                        : Colors.blue[300],
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
            ),
            onDaySelected: (selectedDay, focusedDay) {
              _selectedDay.value = DateTime(
                selectedDay.year,
                selectedDay.month,
                selectedDay.day,
              );
              _focusedDay.value = focusedDay;
            },
            onPageChanged: (focusedDay) {
              _focusedDay.value = focusedDay;
            },
          ),
          SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
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
                ],
              );
            }),
          ),
          SizedBox(height: 16),
          // Selected day details
          if (_selectedDay.value != null) ...[
            Expanded(child: _buildSelectedDayDetails(moodController)),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedDayDetails(MoodController moodController) {
    final mood = moodController.moodsByDate[_selectedDay.value!];

    if (mood == null) {
      return Center(
        child: Text(
          'No mood logged for ${DateFormat('MMMM d, y').format(_selectedDay.value!)}',
        ),
      );
    }

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMMM d, y').format(_selectedDay.value!),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
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
