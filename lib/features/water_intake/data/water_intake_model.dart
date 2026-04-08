class WaterIntake {
  final String date;
  final int glasses;
  final int goal;

  const WaterIntake({required this.date, this.glasses = 0, this.goal = 8});

  double get progress => goal > 0 ? (glasses / goal).clamp(0.0, 1.0) : 0.0;
  bool get isGoalReached => glasses >= goal;

  WaterIntake copyWith({int? glasses, int? goal}) {
    return WaterIntake(
      date: date,
      glasses: glasses ?? this.glasses,
      goal: goal ?? this.goal,
    );
  }

  factory WaterIntake.fromJson(Map<String, dynamic> json, String date) {
    return WaterIntake(
      date: date,
      glasses: json['glasses'] as int? ?? 0,
      goal: json['goal'] as int? ?? 8,
    );
  }

  Map<String, dynamic> toJson() {
    return {'glasses': glasses, 'goal': goal};
  }
}
