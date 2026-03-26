import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Groq
  static const String groqModel = 'llama-3.3-70b-versatile';
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String workout_plansCollection = 'workout_plans';
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
