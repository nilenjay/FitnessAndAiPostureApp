import 'package:cloud_firestore/cloud_firestore.dart';

class DietPlan {
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final String goal;
  final List<MealSuggestion> meals;
  final List<String> tips;

  DietPlan({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.goal,
    required this.meals,
    required this.tips,
  });

  factory DietPlan.fromJson(Map<String, dynamic> json) {
    return DietPlan(
      calories: (json['calories'] as num?)?.toInt() ?? 2000,
      proteinG: (json['proteinG'] as num?)?.toInt() ?? 150,
      carbsG: (json['carbsG'] as num?)?.toInt() ?? 200,
      fatG: (json['fatG'] as num?)?.toInt() ?? 60,
      goal: json['goal'] as String? ?? '',
      meals: (json['meals'] as List<dynamic>? ?? [])
          .map((m) => MealSuggestion.fromJson(m as Map<String, dynamic>))
          .toList(),
      tips: (json['tips'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'proteinG': proteinG,
    'carbsG': carbsG,
    'fatG': fatG,
    'goal': goal,
    'meals': meals.map((m) => m.toJson()).toList(),
    'tips': tips,
  };
}

class MealSuggestion {
  final String name;
  final String example;
  final int calories;
  final int proteinG;

  MealSuggestion({
    required this.name,
    required this.example,
    required this.calories,
    required this.proteinG,
  });

  factory MealSuggestion.fromJson(Map<String, dynamic> json) {
    return MealSuggestion(
      name: json['name'] as String? ?? '',
      example: json['example'] as String? ?? '',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      proteinG: (json['proteinG'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'example': example,
    'calories': calories,
    'proteinG': proteinG,
  };
}

class WorkoutPlan {
  final String id;
  final String goal;
  final String level;
  final int daysPerWeek;
  final String equipment;
  final List<WorkoutDay> days;
  final DateTime createdAt;
  final DietPlan? dietPlan;

  WorkoutPlan({
    required this.id,
    required this.goal,
    required this.level,
    required this.daysPerWeek,
    required this.equipment,
    required this.days,
    required this.createdAt,
    this.dietPlan,
  });

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final raw = json['createdAt'];
    if (raw is Timestamp) {
      parsedDate = raw.toDate();
    } else if (raw is String) {
      parsedDate = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return WorkoutPlan(
      id: json['id'] ?? '',
      goal: json['goal'] ?? '',
      level: json['level'] ?? '',
      daysPerWeek: json['daysPerWeek'] ?? 3,
      equipment: json['equipment'] ?? '',
      days: (json['days'] as List<dynamic>? ?? [])
          .map((d) => WorkoutDay.fromJson(d as Map<String, dynamic>))
          .toList(),
      createdAt: parsedDate,
      dietPlan: json['dietPlan'] != null
          ? DietPlan.fromJson(json['dietPlan'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'goal': goal,
    'level': level,
    'daysPerWeek': daysPerWeek,
    'equipment': equipment,
    'days': days.map((d) => d.toJson()).toList(),
    'createdAt': Timestamp.fromDate(createdAt),
    if (dietPlan != null) 'dietPlan': dietPlan!.toJson(),
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
