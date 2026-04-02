import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/water_intake_model.dart';
import '../data/water_intake_repository.dart';

// ─── States ──────────────────────────────────────────────────────────────────

abstract class WaterIntakeState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WaterIntakeInitial extends WaterIntakeState {}

class WaterIntakeLoading extends WaterIntakeState {}

class WaterIntakeLoaded extends WaterIntakeState {
  final WaterIntake intake;
  WaterIntakeLoaded(this.intake);
  @override
  List<Object?> get props => [intake.glasses, intake.goal, intake.date];
}

class WaterIntakeError extends WaterIntakeState {
  final String message;
  WaterIntakeError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Cubit ───────────────────────────────────────────────────────────────────

class WaterIntakeCubit extends Cubit<WaterIntakeState> {
  final WaterIntakeRepository repository;

  WaterIntakeCubit({required this.repository}) : super(WaterIntakeInitial());

  Future<void> loadToday() async {
    emit(WaterIntakeLoading());
    try {
      final intake = await repository.getTodayIntake();
      emit(WaterIntakeLoaded(intake));
    } catch (e) {
      emit(WaterIntakeError('Failed to load water intake'));
    }
  }

  Future<void> addGlass() async {
    try {
      final intake = await repository.addGlass();
      emit(WaterIntakeLoaded(intake));
    } catch (e) {
      emit(WaterIntakeError('Failed to add glass'));
    }
  }

  Future<void> removeGlass() async {
    try {
      final intake = await repository.removeGlass();
      emit(WaterIntakeLoaded(intake));
    } catch (e) {
      emit(WaterIntakeError('Failed to remove glass'));
    }
  }
}
