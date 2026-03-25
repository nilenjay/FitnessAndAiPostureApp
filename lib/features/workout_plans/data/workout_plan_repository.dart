import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import 'workout_plan_model.dart';

class WorkoutPlanRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _uuid = const Uuid();

  late final GenerativeModel _model = GenerativeModel(
    model: AppConstants.geminiModel,
    apiKey: AppConstants.geminiApiKey,
  );

  // ─── Generate plan via Gemini ─────────────────────────────────────────────

  Future<WorkoutPlan> generatePlan({
    required String goal,
    required String level,
    required int daysPerWeek,
    required String equipment,
  }) async {
    final prompt = _buildPrompt(
      goal: goal,
      level: level,
      daysPerWeek: daysPerWeek,
      equipment: equipment,
    );

    final response = await _model.generateContent([Content.text(prompt)]);
    final text = response.text ?? '';

    // Strip markdown fences if Gemini wraps in ```json
    final cleaned = text
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    final Map<String, dynamic> json = jsonDecode(cleaned);

    final plan = WorkoutPlan(
      id: _uuid.v4(),
      goal: goal,
      level: level,
      daysPerWeek: daysPerWeek,
      equipment: equipment,
      days: (json['days'] as List<dynamic>)
          .map((d) => WorkoutDay.fromJson(d as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.now(),
    );

    // Save to Firestore
    await _savePlan(plan);
    return plan;
  }

  String _buildPrompt({
    required String goal,
    required String level,
    required int daysPerWeek,
    required String equipment,
  }) {
    return '''
You are an expert fitness coach. Generate a $daysPerWeek-day weekly workout plan.

User details:
- Goal: $goal
- Fitness level: $level
- Days per week: $daysPerWeek
- Equipment available: $equipment

Return ONLY a valid JSON object with NO explanation, NO markdown, NO extra text.

The JSON must follow this exact structure:
{
  "days": [
    {
      "dayNumber": 1,
      "dayName": "Monday",
      "focus": "Upper Body",
      "isRestDay": false,
      "exercises": [
        {
          "name": "Push-ups",
          "sets": 3,
          "reps": "12-15",
          "rest": "60s",
          "tip": "Keep your core tight and back straight"
        }
      ]
    },
    {
      "dayNumber": 2,
      "dayName": "Tuesday",
      "focus": "Rest",
      "isRestDay": true,
      "exercises": []
    }
  ]
}

Rules:
- Include exactly 7 days (Monday to Sunday)
- Rest days must have isRestDay: true and empty exercises array
- Active days must have 4-6 exercises
- Tailor exercises to the equipment: $equipment
- Adjust intensity to the level: $level
- Each exercise tip must be specific and actionable
- Return ONLY the JSON, nothing else
''';
  }

  // ─── Firestore ────────────────────────────────────────────────────────────

  Future<void> _savePlan(WorkoutPlan plan) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.workoutPlansCollection)
        .doc(plan.id)
        .set(plan.toJson());
  }

  Future<List<WorkoutPlan>> fetchSavedPlans() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.workoutPlansCollection)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    return snapshot.docs
        .map((doc) => WorkoutPlan.fromJson(doc.data()))
        .toList();
  }

  Future<void> deletePlan(String planId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.workoutPlansCollection)
        .doc(planId)
        .delete();
  }
}
