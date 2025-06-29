import 'package:cloud_firestore/cloud_firestore.dart';

class Mood {
  final String id;
  final DateTime date;
  final int rating; // 1-5 scale
  final String emoji;
  final String? note;
  final String userId;

  Mood({
    required this.id,
    required this.date,
    required this.rating,
    required this.emoji,
    this.note,
    required this.userId,
  });

  factory Mood.fromMap(Map<String, dynamic> map, String id) {
    return Mood(
      id: id,
      date: (map['date'] as Timestamp).toDate(),
      rating: map['rating'] ?? 1,
      emoji: map['emoji'] ?? '😐',
      note: map['note'],
      userId: map['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'rating': rating,
      'emoji': emoji,
      'note': note,
      'userId': userId,
    };
  }
}
