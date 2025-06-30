import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mood_demo/model/moods.dart';
import 'package:mood_demo/controller/mood_controller.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  TrendsScreenState createState() => TrendsScreenState();
}

class TrendsScreenState extends State<TrendsScreen> {
  late Rx<DateTime> _selectedWeekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    _selectedWeekStart = DateTime(
      currentWeekStart.year,
      currentWeekStart.month,
      currentWeekStart.day,
    ).obs;
  }

  @override
  Widget build(BuildContext context) {
    final moodController = Get.find<MoodController>();

    return Obx(() {
      if (moodController.moods.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_up, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No mood data available yet.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8),
              Text('Start logging your moods to see trends!'),
            ],
          ),
        );
      }

      return SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeekNavigator(context, moodController),
            SizedBox(height: 24),
            _buildWeeklyAverage(context, moodController),
            SizedBox(height: 24),
            _buildWeeklyMoodChart(context, moodController),
            SizedBox(height: 24),
            _buildMoodChart(context, moodController),
            SizedBox(height: 24),
            _buildMoodDistribution(context, moodController),
          ],
        ),
      );
    });
  }

  Widget _buildWeekNavigator(BuildContext context, MoodController moodController) {
    final weekEnd = _selectedWeekStart.value.add(Duration(days: 6));
    final isCurrentWeek = _isCurrentWeek(_selectedWeekStart.value);

    // Check if there are any moods in the previous week
    final previousWeekStart = _selectedWeekStart.value.subtract(Duration(days: 7));
    final hasPreviousWeekData = _hasDataInWeek(previousWeekStart, moodController);

    // Check if there are any moods in the next week
    final nextWeekStart = _selectedWeekStart.value.add(Duration(days: 7));
    final hasNextWeekData = _hasDataInWeek(nextWeekStart, moodController);
    final canGoNext = hasNextWeekData || !_isFutureWeek(nextWeekStart);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Week Selection', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous week button
                IconButton(
                  onPressed: hasPreviousWeekData ? () => _changeWeek(-1) : null,
                  icon: Icon(Icons.chevron_left),
                  tooltip: 'Previous Week',
                ),

                // Current week display
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${DateFormat('MMM d').format(_selectedWeekStart.value)} - ${DateFormat('MMM d, yyyy').format(weekEnd)}',
                        style: Theme.of(context).textTheme.titleSmall,
                        textAlign: TextAlign.center,
                      ),
                      if (isCurrentWeek)
                        Text(
                          '(Current Week)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),

                // Next week button
                IconButton(
                  onPressed: canGoNext ? () => _changeWeek(1) : null,
                  icon: Icon(Icons.chevron_right),
                  tooltip: 'Next Week',
                ),
              ],
            ),

            // Quick navigation buttons
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: !isCurrentWeek ? _goToCurrentWeek : null,
                  child: Text('Current Week'),
                ),
                TextButton(
                  onPressed: () => _goToWeekWithMostData(moodController),
                  child: Text('Most Active Week'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyAverage(BuildContext context, MoodController moodController) {
    final weeklyAverage = moodController.getWeeklyAverage(_selectedWeekStart.value);
    final weekMoods = _getWeekMoods(moodController);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly Average', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      weeklyAverage > 0 ? weeklyAverage.toStringAsFixed(1) : 'N/A',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: weeklyAverage > 0
                            ? moodController.getMoodColor(
                                weeklyAverage.round().clamp(1, 5),
                              )
                            : Colors.grey,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      weeklyAverage > 0
                          ? moodController.getMoodEmoji(weeklyAverage.round().clamp(1, 5))
                          : '',
                      style: TextStyle(fontSize: 24),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${weekMoods.length} days logged'),
                    Text(
                      '${weekMoods.length}/7 days',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyMoodChart(BuildContext context, MoodController moodController) {
    final weekMoods = _getWeekMoods(moodController);

    if (weekMoods.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Weekly Mood Chart', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 16),
              Text('No mood data for this week'),
            ],
          ),
        ),
      );
    }

    // Create daily mood map for the week
    Map<int, Mood?> dailyMoods = {};
    for (int i = 0; i < 7; i++) {
      final date = _selectedWeekStart.value.add(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);
      dailyMoods[i] = moodController.moodsByDate[dateKey];
    }

    final List<String> dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly Mood Pattern', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 5,
                  minY: 0,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value >= 1 && value <= 5 && value % 1 == 0) {
                            return Text(value.toInt().toString());
                          }
                          return Text('');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < dayLabels.length) {
                            return Text(dayLabels[index]);
                          }
                          return Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.grey),
                      bottom: BorderSide(color: Colors.grey),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      if (value >= 1 && value <= 5) {
                        return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
                      }
                      return FlLine(color: Colors.transparent);
                    },
                  ),
                  barGroups: List.generate(7, (index) {
                    final mood = dailyMoods[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: mood?.rating.toDouble() ?? 0,
                          color: mood != null
                              ? moodController.getMoodColor(mood.rating)
                              : Colors.grey[300],
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodChart(BuildContext context, MoodController moodController) {
    final last30Days =
        moodController.moods
            .where(
              (Mood mood) =>
                  mood.date.isAfter(DateTime.now().subtract(Duration(days: 30))),
            )
            .toList()
          ..sort((Mood a, Mood b) => a.date.compareTo(b.date));

    if (last30Days.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Not enough data for monthly chart'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood Trend (Last 30 Days)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      if (value >= 1 && value <= 5) {
                        return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
                      }
                      return FlLine(color: Colors.transparent);
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value >= 1 && value <= 5 && value % 1 == 0) {
                            return Text(value.toInt().toString());
                          }
                          return Text('');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < last30Days.length) {
                            return Text(
                              DateFormat('MM/dd').format(last30Days[index].date),
                              style: TextStyle(fontSize: 10),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.grey),
                      bottom: BorderSide(color: Colors.grey),
                    ),
                  ),
                  clipData: FlClipData.all(),
                  minX: 0,
                  maxX: (last30Days.length - 1).toDouble(),
                  minY: 1,
                  maxY: 5.1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: last30Days.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.rating.toDouble(),
                        );
                      }).toList(),
                      isCurved: false,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      aboveBarData: BarAreaData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodDistribution(BuildContext context, MoodController moodController) {
    final moodCounts = <int, int>{};
    for (var mood in moodController.moods) {
      moodCounts[mood.rating] = (moodCounts[mood.rating] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Mood Distribution',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            ...List.generate(5, (index) {
              final rating = index + 1;
              final count = moodCounts[rating] ?? 0;
              final percentage = moodController.moods.isNotEmpty
                  ? (count / moodController.moods.length * 100)
                  : 0.0;

              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(moodController.getMoodEmoji(rating)),
                    SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          moodController.getMoodColor(rating),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$count (${percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Helper methods
  void _changeWeek(int direction) {
    _selectedWeekStart.value = _selectedWeekStart.value.add(
      Duration(days: 7 * direction),
    );
  }

  void _goToCurrentWeek() {
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    _selectedWeekStart.value = DateTime(
      currentWeekStart.year,
      currentWeekStart.month,
      currentWeekStart.day,
    );
  }

  void _goToWeekWithMostData(MoodController moodController) {
    if (moodController.moods.isEmpty) return;

    // Group moods by week and find the week with most data
    Map<DateTime, int> weekCounts = {};

    for (var mood in moodController.moods) {
      final weekStart = mood.date.subtract(Duration(days: mood.date.weekday - 1));
      final weekKey = DateTime(weekStart.year, weekStart.month, weekStart.day);
      weekCounts[weekKey] = (weekCounts[weekKey] ?? 0) + 1;
    }

    if (weekCounts.isNotEmpty) {
      final mostActiveWeek = weekCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      _selectedWeekStart.value = mostActiveWeek;
    }
  }

  bool _isCurrentWeek(DateTime weekStart) {
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final currentWeekKey = DateTime(
      currentWeekStart.year,
      currentWeekStart.month,
      currentWeekStart.day,
    );
    return weekStart.isAtSameMomentAs(currentWeekKey);
  }

  bool _isFutureWeek(DateTime weekStart) {
    final now = DateTime.now();
    return weekStart.isAfter(now);
  }

  bool _hasDataInWeek(DateTime weekStart, MoodController moodController) {
    final weekEnd = weekStart.add(Duration(days: 7));
    return moodController.moods.any(
      (mood) =>
          mood.date.isAfter(weekStart.subtract(Duration(days: 1))) &&
          mood.date.isBefore(weekEnd),
    );
  }

  List<Mood> _getWeekMoods(MoodController moodController) {
    final weekEnd = _selectedWeekStart.value.add(Duration(days: 7));
    return moodController.moods.where((mood) {
      return mood.date.isAfter(_selectedWeekStart.value.subtract(Duration(days: 1))) &&
          mood.date.isBefore(weekEnd);
    }).toList();
  }
}
