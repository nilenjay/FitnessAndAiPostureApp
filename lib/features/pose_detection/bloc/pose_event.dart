part of 'pose_bloc.dart';

abstract class PoseEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class PoseCameraStarted extends PoseEvent {
  final String exercise;
  PoseCameraStarted(this.exercise);
  @override
  List<Object?> get props => [exercise];
}

class PoseCameraStopped extends PoseEvent {}

class PoseImageProcessed extends PoseEvent {
  final InputImage inputImage;
  PoseImageProcessed(this.inputImage);
  @override
  List<Object?> get props => [inputImage];
}

class PoseSessionCompleted extends PoseEvent {}