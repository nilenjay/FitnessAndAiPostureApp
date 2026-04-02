import 'dart:async';
import 'dart:math' as math;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../core/constants/app_constants.dart';
import '../data/pose_repository.dart';

part 'pose_event.dart';
part 'pose_state.dart';

class PoseBloc extends Bloc<PoseEvent, PoseState> {
  final PoseRepository _poseRepository;
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
    ),
  );


  final FlutterTts _tts = FlutterTts();
  String _lastSpoken = '';
  DateTime _lastSpeakTime = DateTime(2000);

  int _repCount = 0;
  RepPhase _currentPhase = RepPhase.up;
  String _exercise = 'squat';
  final List<String> _feedbackLog = [];
  bool _isProcessing = false;

  PoseBloc({required PoseRepository poseRepository})
      : _poseRepository = poseRepository,
        super(PoseInitial()) {
    on<PoseCameraStarted>(_onCameraStarted);
    on<PoseCameraStopped>(_onCameraStopped);
    on<PoseImageProcessed>(_onImageProcessed);
    on<PoseSessionCompleted>(_onSessionCompleted);

    _initTts();
  }



  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.52);   // slightly slower for gym clarity
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  /// Speaks [text] only if it differs from the last utterance and a minimum
  /// cooldown has elapsed. This prevents the TTS queue from flooding during
  /// continuous camera frames.
  Future<void> _speak(String text, {Duration cooldown = const Duration(seconds: 3)}) async {
    final now = DateTime.now();
    if (text == _lastSpoken && now.difference(_lastSpeakTime) < cooldown) {
      return;
    }
    _lastSpoken = text;
    _lastSpeakTime = now;
    await _tts.stop();
    await _tts.speak(text);
  }

  /// Always speaks rep announcements regardless of cooldown.
  Future<void> _speakRepCount(int reps, String exercise) async {
    final exerciseName = _prettyExercise(exercise);
    final text = reps == 1
        ? 'Rep 1! Keep it up!'
        : 'Rep $reps! Great $exerciseName!';
    _lastSpoken = text;
    _lastSpeakTime = DateTime.now();
    await _tts.stop();
    await _tts.speak(text);
  }

  String _prettyExercise(String exercise) {
    switch (exercise) {
      case 'squat': return 'squat';
      case 'pushup': return 'push-up';
      case 'lunge': return 'lunge';
      case 'plank': return 'plank hold';
      default: return exercise;
    }
  }

  // ── BLoC handlers ─────────────────────────────────────────────────────────

  void _onCameraStarted(PoseCameraStarted event, Emitter<PoseState> emit) {
    _exercise = event.exercise;
    _repCount = 0;
    _currentPhase = RepPhase.up;
    _feedbackLog.clear();
    _lastSpoken = '';
    _speak('Starting ${_prettyExercise(_exercise)}. Get into position.',
        cooldown: Duration.zero);
    emit(PoseCameraReady());
  }

  void _onCameraStopped(PoseCameraStopped event, Emitter<PoseState> emit) {
    _tts.stop();
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
      final feedback = result['feedback'] as String;
      final isRepAnnouncement = result['isRepAnnouncement'] as bool? ?? false;

      // Voice feedback
      if (isRepAnnouncement) {
        await _speakRepCount(_repCount, _exercise);
      } else if (feedback.isNotEmpty) {
        await _speak(feedback);
      }

      emit(PoseDetecting(
        poses: poses,
        repCount: _repCount,
        feedback: feedback,
        angle: result['angle'] as double,
        repPhase: _currentPhase,
      ));
    } catch (e) {
      emit(PoseError('Pose detection failed: $e'));
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _onSessionCompleted(
      PoseSessionCompleted event, Emitter<PoseState> emit) async {
    final score = _calculateScore();

    // Speak summary
    await _tts.stop();
    await _tts.speak(
        'Great session! You completed $_repCount ${_prettyExercise(_exercise)}s with a score of $score out of 100.');

    try {
      await _poseRepository.saveSession(
        exercise: _exercise,
        reps: _repCount,
        score: score,
        feedback: List.from(_feedbackLog),
      );
    } catch (e) {
      // ignore save errors, still show summary
    }

    emit(PoseSessionDone(
      totalReps: _repCount,
      exercise: _exercise,
      feedbackList: List.from(_feedbackLog),
      score: score,
    ));
  }

  // ── Exercise analysis ─────────────────────────────────────────────────────

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
        return {'feedback': 'Unknown exercise', 'angle': 0.0, 'isRepAnnouncement': false};
    }
  }

  Map<String, dynamic> _analyzeSquat(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];

    if (!_areLandmarksVisible([hip, knee, ankle, shoulder])) {
      return {
        'feedback': 'Move into frame fully',
        'angle': 0.0,
        'isRepAnnouncement': false,
      };
    }

    final kneeAngle = _calculateAngle(hip!, knee!, ankle!);
    bool isRepAnnouncement = false;
    String feedback = '';

    if (kneeAngle < 110 && _currentPhase == RepPhase.up) {
      _currentPhase = RepPhase.down;
    } else if (kneeAngle > 160 && _currentPhase == RepPhase.down) {
      _currentPhase = RepPhase.up;
      _repCount++;
      isRepAnnouncement = true;
      feedback = 'Rep $_repCount — Good squat!';
      _addFeedback(feedback);
    }

    if (feedback.isEmpty) {
      if (kneeAngle > 160) {
        feedback = 'Lower your squat — go deeper';
      } else if (kneeAngle < 70) {
        feedback = 'Good depth! Drive up through heels';
      } else {
        feedback = 'Good form — keep going';
      }

      final backAngle = _calculateAngle(shoulder!, hip!, knee!);
      if (backAngle < 150) {
        feedback = 'Keep your back straight!';
        _addFeedback('Back was leaning forward');
      }
    }

    return {
      'feedback': feedback,
      'angle': kneeAngle,
      'isRepAnnouncement': isRepAnnouncement,
    };
  }

  Map<String, dynamic> _analyzePushup(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final hip = pose.landmarks[PoseLandmarkType.leftHip];

    if (!_areLandmarksVisible([shoulder, elbow, wrist, hip])) {
      return {
        'feedback': 'Move into frame fully',
        'angle': 0.0,
        'isRepAnnouncement': false,
      };
    }

    final elbowAngle = _calculateAngle(shoulder!, elbow!, wrist!);
    bool isRepAnnouncement = false;
    String feedback = '';

    if (elbowAngle < 90 && _currentPhase == RepPhase.up) {
      _currentPhase = RepPhase.down;
    } else if (elbowAngle > 155 && _currentPhase == RepPhase.down) {
      _currentPhase = RepPhase.up;
      _repCount++;
      isRepAnnouncement = true;
      feedback = 'Rep $_repCount — Great push-up!';
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

      final bodyAngle = _calculateAngle(shoulder, hip!, wrist);
      if (bodyAngle < 160) {
        feedback = 'Keep your body straight — no sagging!';
        _addFeedback('Body was not aligned');
      }
    }

    return {
      'feedback': feedback,
      'angle': elbowAngle,
      'isRepAnnouncement': isRepAnnouncement,
    };
  }

  Map<String, dynamic> _analyzeLunge(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];

    if (!_areLandmarksVisible([hip, knee, ankle])) {
      return {
        'feedback': 'Move into frame fully',
        'angle': 0.0,
        'isRepAnnouncement': false,
      };
    }

    final kneeAngle = _calculateAngle(hip!, knee!, ankle!);
    bool isRepAnnouncement = false;
    String feedback = '';

    if (kneeAngle < 95 && _currentPhase == RepPhase.up) {
      _currentPhase = RepPhase.down;
    } else if (kneeAngle > 160 && _currentPhase == RepPhase.down) {
      _currentPhase = RepPhase.up;
      _repCount++;
      isRepAnnouncement = true;
      feedback = 'Rep $_repCount — Great lunge!';
      _addFeedback(feedback);
    }

    if (feedback.isEmpty) {
      feedback = kneeAngle > 160
          ? 'Step forward and lower your knee'
          : 'Good lunge depth!';
    }

    return {
      'feedback': feedback,
      'angle': kneeAngle,
      'isRepAnnouncement': isRepAnnouncement,
    };
  }

  Map<String, dynamic> _analyzePlank(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];

    if (!_areLandmarksVisible([shoulder, hip, ankle])) {
      return {
        'feedback': 'Move into frame fully',
        'angle': 0.0,
        'isRepAnnouncement': false,
      };
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

    return {
      'feedback': feedback,
      'angle': bodyAngle,
      'isRepAnnouncement': false,
    };
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  double _calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final radians = math.atan2(c.y - b.y, c.x - b.x) -
        math.atan2(a.y - b.y, a.x - b.x);
    double angle = radians * (180 / math.pi);
    if (angle < 0) angle += 360;
    if (angle > 180) angle = 360 - angle;
    return angle.abs();
  }

  bool _areLandmarksVisible(List<PoseLandmark?> landmarks) {
    return landmarks.every(
            (l) => l != null && l.likelihood >= AppConstants.poseConfidenceThreshold);
  }

  void _addFeedback(String feedback) {
    if (!_feedbackLog.contains(feedback)) {
      _feedbackLog.add(feedback);
    }
  }

  int _calculateScore() {
    if (_repCount == 0) return 0;
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
    _tts.stop();
    return super.close();
  }
}