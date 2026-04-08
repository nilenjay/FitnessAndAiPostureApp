import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/workout_plan_model.dart';
import '../data/workout_plan_repository.dart';

part 'workout_plan_event.dart';
part 'workout_plan_state.dart';

class WorkoutPlanBloc extends Bloc<WorkoutPlanEvent, WorkoutPlanState> {
  final WorkoutPlanRepository _repository;

  WorkoutPlanBloc({required WorkoutPlanRepository repository})
    : _repository = repository,
      super(WorkoutPlanInitial()) {
    on<WorkoutPlanGenerate>(_onGenerate);
    on<WorkoutPlanFetch>(_onFetch);
    on<WorkoutPlanDelete>(_onDelete);
    on<WorkoutPlanSelect>(_onSelect);
  }

  Future<void> _onGenerate(
    WorkoutPlanGenerate event,
    Emitter<WorkoutPlanState> emit,
  ) async {
    final oldPlans = state is WorkoutPlanLoaded
        ? (state as WorkoutPlanLoaded).plans
        : <WorkoutPlan>[];

    emit(WorkoutPlanGenerating());
    try {
      final plan = await _repository.generatePlan(
        goal: event.goal,
        level: event.level,
        daysPerWeek: event.daysPerWeek,
        equipment: event.equipment,
      );
      emit(WorkoutPlanGenerated(plan));

      final localPlans = List<WorkoutPlan>.from(oldPlans);
      if (!localPlans.any((p) => p.id == plan.id)) {
        localPlans.insert(0, plan);
      }

      emit(WorkoutPlanLoaded(plans: localPlans, selectedPlan: plan));
    } catch (e) {
      debugPrint('❌ Plan generation failed: $e');
      emit(WorkoutPlanError('Failed to generate plan: ${e.toString()}'));
    }
  }

  Future<void> _onFetch(
    WorkoutPlanFetch event,
    Emitter<WorkoutPlanState> emit,
  ) async {
    emit(WorkoutPlanLoading());
    try {
      final plans = await _repository.fetchSavedPlans();
      emit(
        WorkoutPlanLoaded(
          plans: plans,
          selectedPlan: plans.isNotEmpty ? plans.first : null,
        ),
      );
    } catch (e) {
      debugPrint('❌ Fetch plans failed: $e');
      emit(WorkoutPlanError('Failed to load plans: ${e.toString()}'));
    }
  }

  Future<void> _onDelete(
    WorkoutPlanDelete event,
    Emitter<WorkoutPlanState> emit,
  ) async {
    try {
      await _repository.deletePlan(event.planId);

      final plans = await _repository.fetchSavedPlans();
      emit(
        WorkoutPlanLoaded(
          plans: plans,
          selectedPlan: plans.isNotEmpty ? plans.first : null,
        ),
      );
    } catch (e) {
      debugPrint('❌ Delete failed: $e');
      emit(WorkoutPlanError('Failed to delete plan.'));
    }
  }

  void _onSelect(WorkoutPlanSelect event, Emitter<WorkoutPlanState> emit) {
    if (state is WorkoutPlanLoaded) {
      final current = state as WorkoutPlanLoaded;
      emit(current.copyWith(selectedPlan: event.plan));
    }
  }
}
