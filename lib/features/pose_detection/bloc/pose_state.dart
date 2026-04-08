part of 'pose_bloc.dart';

abstract class PoseState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PoseInitial extends PoseState {}

class PoseCameraLoading extends PoseState {}

class PoseCameraReady extends PoseState {}

class PoseDetecting extends PoseState {
  final List<Pose> poses;
  final int repCount;
  final String feedback;
  final double angle;
  final RepPhase repPhase;

  PoseDetecting({
    required this.poses,
    required this.repCount,
    required this.feedback,
    required this.angle,
    required this.repPhase,
  });

  @override
  List<Object?> get props => [poses, repCount, feedback, angle, repPhase];
}

class PoseSessionDone extends PoseState {
  final int totalReps;
  final String exercise;
  final List<String> feedbackList;
  final int score;

  PoseSessionDone({
    required this.totalReps,
    required this.exercise,
    required this.feedbackList,
    required this.score,
  });

  @override
  List<Object?> get props => [totalReps, exercise, feedbackList, score];
}

class PoseError extends PoseState {
  final String message;
  PoseError(this.message);
  @override
  List<Object?> get props => [message];
}

enum RepPhase { up, down }
