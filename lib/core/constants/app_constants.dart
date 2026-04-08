import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const String groqModel = 'llama-3.3-70b-versatile';
  static const String groqBaseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  static const String usersCollection = 'users';
  static const String workoutPlansCollection = 'workout_plans';
  static const String sessionsCollection = 'sessions';
  static const String waterIntakeCollection = 'water_intake';

  static const List<String> supportedExercises = [
    'squat',
    'pushup',
    'lunge',
    'plank',
  ];

  static const double poseConfidenceThreshold = 0.5;
  static const double squatDepthAngle = 90.0;
  static const double pushupBottomAngle = 90.0;
}
