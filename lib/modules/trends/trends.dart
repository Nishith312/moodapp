import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mood_demo/model/moods.dart';
import 'package:mood_demo/modules/mood_screen/mood_controller.dart';

class TrendsScreen extends StatelessWidget {
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
            _buildWeeklyAverage(context, moodController),
            SizedBox(height: 24),
            _buildMoodChart(context, moodController),
            SizedBox(height: 24),
            _buildMoodDistribution(context, moodController),
          ],
        ),
      );
    });
  }

  Widget _buildWeeklyAverage(BuildContext context, MoodController moodController) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weeklyAverage = moodController.getWeeklyAverage(weekStart);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This Week\'s Average', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            Row(
              children: [
                Text(
                  weeklyAverage > 0 ? weeklyAverage.toStringAsFixed(1) : 'N/A',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: weeklyAverage > 0
                        ? moodController.getMoodColor(weeklyAverage.round().clamp(1, 5))
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
          child: Text('Not enough data for chart'),
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
            Container(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString());
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
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: (last30Days.length - 1).toDouble(),
                  minY: 1,
                  maxY: 5,
                  lineBarsData: [
                    LineChartBarData(
                      spots: last30Days.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.rating.toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
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
            Text('Mood Distribution', style: Theme.of(context).textTheme.titleLarge),
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
}
