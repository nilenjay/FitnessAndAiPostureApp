class AppConstants {
  // Gemini
  static const String geminiModel = 'gemini-1.5-flash';
  // TODO: Move to .env or Firebase Remote Config before production
  static const String geminiApiKey = 'AIzaSyAvCLiTX-Ifuqa0QKoKTYzU20TJ3D9Bk9I';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String workoutPlansCollection = 'workout_plans';
  static const String sessionsCollection = 'sessions';

  // Exercises supported by pose detection
  static const List<String> supportedExercises = [
    'squat',
    'pushup',
    'lunge',
    'plank',
  ];

  // Pose detection thresholds
  static const double poseConfidenceThreshold = 0.5;
  static const double squatDepthAngle = 90.0;   // degrees at knee
  static const double pushupBottomAngle = 90.0; // degrees at elbow
}