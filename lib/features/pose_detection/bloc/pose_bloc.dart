import 'dart:async';
import 'dart:math' as math;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../core/constants/app_constants.dart';

part 'pose_event.dart';
part 'pose_state.dart';

class PoseBloc extends Bloc<PoseEvent, PoseState> {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
    ),
  );

  int _repCount = 0;
  RepPhase _currentPhase = RepPhase.up;
  String _exercise = 'squat';
  final List<String> _feedbackLog = [];
  bool _isProcessing = false;

  PoseBloc() : super(PoseInitial()) {
    on<PoseCameraStarted>(_onCameraStarted);
    on<PoseCameraStopped>(_onCameraStopped);
    on<PoseImageProcessed>(_onImageProcessed);
    on<PoseSessionCompleted>(_onSessionCompleted);
  }

  void _onCameraStarted(PoseCameraStarted event, Emitter<PoseState> emit) {
    _exercise = event.exercise;
    _repCount = 0;
    _currentPhase = RepPhase.up;
    _feedbackLog.clear();
    emit(PoseCameraReady());
  }

  void _onCameraStopped(PoseCameraStopped event, Emitter<PoseState> emit) {
    emit(PoseInitial());
  }

  Future<void> _onImageProcessed(
      PoseImageProcessed event,
      Emitter<PoseState> emit,
      ) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final poses = await _poseDetector.processImage(event.inputImage);

      if (poses.isEmpty) {
        _isProcessing = false;
        return;
      }

      final pose = poses.first;
      final result = _analyzeExercise(pose);

      emit(PoseDetecting(
        poses: poses,
        repCount: _repCount,
        feedback: result['feedback'] as String,
        angle: result['angle'] as double,
        repPhase: _currentPhase,
      ));
    } catch (e) {
      emit(PoseError('Pose detection failed: $e'));
    } finally {
      _isProcessing = false;
    }
  }

  void _onSessionCompleted(PoseSessionCompleted event, Emitter<PoseState> emit) {
    final score = _calculateScore();
    emit(PoseSessionDone(
      totalReps: _repCount,
      exercise: _exercise,
      feedbackList: List.from(_feedbackLog),
      score: score,
    ));
  }


  Map<String, dynamic> _analyzeExercise(Pose pose) {
    switch (_exercise) {
      case 'squat':
        return _analyzeSquat(pose);
      case 'pushup':
        return _analyzePushup(pose);
      case 'lunge':
        return _analyzeLunge(pose);
      case 'plank':
        return _analyzePlank(pose);
      default:
        return {'feedback': 'Unknown exercise', 'angle': 0.0};
    }
  }

  Map<String, dynamic> _analyzeSquat(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];

    if (!_areLandmarksVisible([hip, knee, ankle, shoulder])) {
      return {'feedback': 'Move into frame fully', 'angle': 0.0};
    }

    final kneeAngle = _calculateAngle(hip!, knee!, ankle!);
    String feedback = '';

    // Rep counting: down = knee < 110°, up = knee > 160°
    if (kneeAngle < 110 && _currentPhase == RepPhase.up) {
      _currentPhase = RepPhase.down;
    } else if (kneeAngle > 160 && _currentPhase == RepPhase.down) {
      _currentPhase = RepPhase.up;
      _repCount++;
      feedback = 'Rep $_repCount — Good squat!';
      _addFeedback(feedback);
    }

    // Form feedback
    if (feedback.isEmpty) {
      if (kneeAngle > 160) {
        feedback = 'Lower your squat — go deeper';
      } else if (kneeAngle < 70) {
        feedback = 'Good depth! Drive up through heels';
      } else {
        feedback = 'Good form — keep going';
      }

      // Check back angle
      final backAngle = _calculateAngle(shoulder!, hip!, knee!);
      if (backAngle < 150) {
        feedback = 'Keep your back straight!';
        _addFeedback('Back was leaning forward');
      }
    }

    return {'feedback': feedback, 'angle': kneeAngle};
  }

  Map<String, dynamic> _analyzePushup(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final hip = pose.landmarks[PoseLandmarkType.leftHip];

    if (!_areLandmarksVisible([shoulder, elbow, wrist, hip])) {
      return {'feedback': 'Move into frame fully', 'angle': 0.0};
    }

    final elbowAngle = _calculateAngle(shoulder!, elbow!, wrist!);
    String feedback = '';

    // Rep counting: down = elbow < 90°, up = elbow > 155°
    if (elbowAngle < 90 && _currentPhase == RepPhase.up) {
      _currentPhase = RepPhase.down;
    } else if (elbowAngle > 155 && _currentPhase == RepPhase.down) {
      _currentPhase = RepPhase.up;
      _repCount++;
      feedback = 'Rep $_repCount — Great pushup!';
      _addFeedback(feedback);
    }

    if (feedback.isEmpty) {
      if (elbowAngle > 155) {
        feedback = 'Lower your chest to the ground';
      } else if (elbowAngle < 90) {
        feedback = 'Good depth! Push back up';
      } else {
        feedback = 'Good form — keep going';
      }

      // Check body alignment
      final bodyAngle = _calculateAngle(shoulder, hip!, wrist);
      if (bodyAngle < 160) {
        feedback = 'Keep your body straight — no sagging!';
        _addFeedback('Body was not aligned');
      }
    }

    return {'feedback': feedback, 'angle': elbowAngle};
  }

  Map<String, dynamic> _analyzeLunge(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];

    if (!_areLandmarksVisible([hip, knee, ankle])) {
      return {'feedback': 'Move into frame fully', 'angle': 0.0};
    }

    final kneeAngle = _calculateAngle(hip!, knee!, ankle!);
    String feedback = '';

    if (kneeAngle < 95 && _currentPhase == RepPhase.up) {
      _currentPhase = RepPhase.down;
    } else if (kneeAngle > 160 && _currentPhase == RepPhase.down) {
      _currentPhase = RepPhase.up;
      _repCount++;
      feedback = 'Rep $_repCount — Great lunge!';
      _addFeedback(feedback);
    }

    if (feedback.isEmpty) {
      feedback = kneeAngle > 160
          ? 'Step forward and lower your knee'
          : 'Good lunge depth!';
    }

    return {'feedback': feedback, 'angle': kneeAngle};
  }

  Map<String, dynamic> _analyzePlank(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];

    if (!_areLandmarksVisible([shoulder, hip, ankle])) {
      return {'feedback': 'Move into frame fully', 'angle': 0.0};
    }

    final bodyAngle = _calculateAngle(shoulder!, hip!, ankle!);
    String feedback;

    if (bodyAngle > 165 && bodyAngle < 195) {
      feedback = 'Perfect plank! Hold it strong';
    } else if (bodyAngle <= 165) {
      feedback = 'Raise your hips — body too low';
      _addFeedback('Hips too low during plank');
    } else {
      feedback = 'Lower your hips — body too high';
      _addFeedback('Hips too high during plank');
    }

    return {'feedback': feedback, 'angle': bodyAngle};
  }

  double _calculateAngle(
      PoseLandmark a,
      PoseLandmark b,
      PoseLandmark c,
      ) {
    final radians = math.atan2(c.y - b.y, c.x - b.x) -
        math.atan2(a.y - b.y, a.x - b.x);
    double angle = radians * (180 / math.pi);
    if (angle < 0) angle += 360;
    if (angle > 180) angle = 360 - angle;
    return angle.abs();
  }

  bool _areLandmarksVisible(List<PoseLandmark?> landmarks) {
    return landmarks.every((l) =>
    l != null &&
        l.likelihood >= AppConstants.poseConfidenceThreshold);
  }

  void _addFeedback(String feedback) {
    if (!_feedbackLog.contains(feedback)) {
      _feedbackLog.add(feedback);
    }
  }

  int _calculateScore() {
    if (_repCount == 0) return 0;
    // Deduct points for each form error logged
    final deduction = (_feedbackLog
        .where((f) =>
    f.contains('leaning') ||
        f.contains('sagging') ||
        f.contains('aligned') ||
        f.contains('hips'))
        .length) *
        10;
    return (100 - deduction).clamp(0, 100);
  }

  @override
  Future<void> close() {
    _poseDetector.close();
    return super.close();
  }
}