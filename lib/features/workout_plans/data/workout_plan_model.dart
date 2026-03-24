class WorkoutPlan {
  final String id;
  final String goal;
  final String level;
  final int daysPerWeek;
  final String equipment;
  final List<WorkoutDay> days;
  final DateTime createdAt;

  WorkoutPlan({
    required this.id,
    required this.goal,
    required this.level,
    required this.daysPerWeek,
    required this.equipment,
    required this.days,
    required this.createdAt,
  });

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id'] ?? '',
      goal: json['goal'] ?? '',
      level: json['level'] ?? '',
      daysPerWeek: json['daysPerWeek'] ?? 3,
      equipment: json['equipment'] ?? '',
      days: (json['days'] as List<dynamic>? ?? [])
          .map((d) => WorkoutDay.fromJson(d as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'goal': goal,
    'level': level,
    'daysPerWeek': daysPerWeek,
    'equipment': equipment,
    'days': days.map((d) => d.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };
}

class WorkoutDay {
  final int dayNumber;
  final String dayName;
  final String focus;
  final bool isRestDay;
  final List<WorkoutExercise> exercises;

  WorkoutDay({
    required this.dayNumber,
    required this.dayName,
    required this.focus,
    required this.isRestDay,
    required this.exercises,
  });

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    return WorkoutDay(
      dayNumber: json['dayNumber'] ?? 1,
      dayName: json['dayName'] ?? '',
      focus: json['focus'] ?? '',
      isRestDay: json['isRestDay'] ?? false,
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'dayNumber': dayNumber,
    'dayName': dayName,
    'focus': focus,
    'isRestDay': isRestDay,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };
}

class WorkoutExercise {
  final String name;
  final int sets;
  final String reps;
  final String rest;
  final String tip;

  WorkoutExercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.rest,
    required this.tip,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      name: json['name'] ?? '',
      sets: json['sets'] ?? 3,
      reps: json['reps'] ?? '10',
      rest: json['rest'] ?? '60s',
      tip: json['tip'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'sets': sets,
    'reps': reps,
    'rest': rest,
    'tip': tip,
  };
}