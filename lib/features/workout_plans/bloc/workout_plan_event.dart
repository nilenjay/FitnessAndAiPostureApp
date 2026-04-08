part of 'workout_plan_bloc.dart';

abstract class WorkoutPlanEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorkoutPlanGenerate extends WorkoutPlanEvent {
  final String goal;
  final String level;
  final int daysPerWeek;
  final String equipment;

  WorkoutPlanGenerate({
    required this.goal,
    required this.level,
    required this.daysPerWeek,
    required this.equipment,
  });

  @override
  List<Object?> get props => [goal, level, daysPerWeek, equipment];
}

class WorkoutPlanFetch extends WorkoutPlanEvent {}

class WorkoutPlanDelete extends WorkoutPlanEvent {
  final String planId;
  WorkoutPlanDelete(this.planId);
  @override
  List<Object?> get props => [planId];
}

class WorkoutPlanSelect extends WorkoutPlanEvent {
  final WorkoutPlan plan;
  WorkoutPlanSelect(this.plan);
  @override
  List<Object?> get props => [plan];
}
