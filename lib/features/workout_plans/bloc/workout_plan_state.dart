part of 'workout_plan_bloc.dart';

abstract class WorkoutPlanState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorkoutPlanInitial extends WorkoutPlanState {}

class WorkoutPlanLoading extends WorkoutPlanState {}

class WorkoutPlanGenerating extends WorkoutPlanState {}

class WorkoutPlanLoaded extends WorkoutPlanState {
  final List<WorkoutPlan> plans;
  final WorkoutPlan? selectedPlan;

  WorkoutPlanLoaded({required this.plans, this.selectedPlan});

  WorkoutPlanLoaded copyWith({
    List<WorkoutPlan>? plans,
    WorkoutPlan? selectedPlan,
  }) {
    return WorkoutPlanLoaded(
      plans: plans ?? this.plans,
      selectedPlan: selectedPlan ?? this.selectedPlan,
    );
  }

  @override
  List<Object?> get props => [plans, selectedPlan];
}

class WorkoutPlanGenerated extends WorkoutPlanState {
  final WorkoutPlan plan;
  WorkoutPlanGenerated(this.plan);
  @override
  List<Object?> get props => [plan];
}

class WorkoutPlanError extends WorkoutPlanState {
  final String message;
  WorkoutPlanError(this.message);
  @override
  List<Object?> get props => [message];
}