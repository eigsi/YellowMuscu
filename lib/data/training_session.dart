class TrainingSession {
  final int? id;
  final String date;
  final double duration;
  final String type;

  TrainingSession({
    this.id,
    required this.date,
    required this.duration,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'duration': duration,
      'type': type,
    };
  }

  static TrainingSession fromMap(Map<String, dynamic> map) {
    return TrainingSession(
      id: map['id'],
      date: map['date'],
      duration: map['duration'],
      type: map['type'],
    );
  }
}
