import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import 'workout_plan_model.dart';

class WorkoutPlanRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _uuid = const Uuid();

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.groq.com',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConstants.groqApiKey}',
      },
    ),
  );

  Future<WorkoutPlan> generatePlan({
    required String goal,
    required String level,
    required int daysPerWeek,
    required String equipment,
  }) async {
    Map<String, dynamic> userDetails = {};
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .get();
        if (doc.exists) {
          userDetails = doc.data() ?? {};
        }
      } catch (e) {
        debugPrint('⚠️ Failed to fetch user details: $e');
      }
    }

    final prompt = _buildPrompt(
      goal: goal,
      level: level,
      daysPerWeek: daysPerWeek,
      equipment: equipment,
      userDetails: userDetails,
    );

    final response = await _dio.post(
      '/openai/v1/chat/completions',
      data: {
        'model': AppConstants.groqModel,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are an expert fitness and nutrition coach. Return ONLY valid JSON with no markdown fences or extra text.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
        'max_tokens': 4096,
        'response_format': {'type': 'json_object'},
      },
    );

    final data = response.data as Map<String, dynamic>;
    final text = data['choices'][0]['message']['content'] as String? ?? '';

    final cleaned = text
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    final Map<String, dynamic> json = jsonDecode(cleaned);

    DietPlan? dietPlan;
    if (json['dietPlan'] != null) {
      try {
        dietPlan = DietPlan.fromJson(json['dietPlan'] as Map<String, dynamic>);
      } catch (e) {
        debugPrint('⚠️ Failed to parse dietPlan: $e');
      }
    }

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
      dietPlan: dietPlan,
    );

    await _savePlan(plan);
    return plan;
  }

  String _buildPrompt({
    required String goal,
    required String level,
    required int daysPerWeek,
    required String equipment,
    required Map<String, dynamic> userDetails,
  }) {
    final weight = userDetails['weight'] ?? 80;
    final height = userDetails['height'] ?? 180;
    final age = userDetails['age'] ?? 30;
    final gender = userDetails['gender'] ?? 'Male';
    final activityLevel = userDetails['activityLevel'] ?? 'Moderately Active';

    return '''
You are an expert fitness and nutrition coach. Generate a $daysPerWeek-day weekly workout plan AND a matching daily diet plan.

User details:
- Goal: $goal
- Fitness level: $level
- Days per week: $daysPerWeek
- Equipment available: $equipment
- Weight: ${weight}kg
- Height: ${height}cm
- Age: $age
- Gender: $gender
- Activity Level: $activityLevel

Return ONLY a valid JSON object with NO explanation, NO markdown, NO extra text.

The JSON must follow this EXACT structure:
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
  ],
  "dietPlan": {
    "goal": "Brief description of the nutrition strategy",
    "calories": 2200,
    "proteinG": 165,
    "carbsG": 240,
    "fatG": 65,
    "meals": [
      {
        "name": "Breakfast",
        "example": "Oatmeal with banana, 3 scrambled eggs, black coffee",
        "calories": 550,
        "proteinG": 35
      },
      {
        "name": "Lunch",
        "example": "Grilled chicken breast, brown rice, steamed broccoli",
        "calories": 650,
        "proteinG": 50
      },
      {
        "name": "Pre-workout snack",
        "example": "Greek yogurt with berries and a handful of almonds",
        "calories": 300,
        "proteinG": 20
      },
      {
        "name": "Dinner",
        "example": "Salmon fillet, sweet potato, mixed salad with olive oil",
        "calories": 600,
        "proteinG": 45
      },
      {
        "name": "Evening snack",
        "example": "Cottage cheese with a tablespoon of peanut butter",
        "calories": 200,
        "proteinG": 18
      }
    ],
    "tips": [
      "Drink at least 3 litres of water daily",
      "Eat protein within 30 minutes of training",
      "Avoid processed sugar on workout days"
    ]
  }
}

Rules for workout:
- Include exactly 7 days (Monday to Sunday)
- Rest days must have isRestDay: true and empty exercises array
- Active days must have 4-6 exercises
- Tailor exercises to the equipment: $equipment
- Adjust intensity to the level: $level
- Each exercise tip must be specific and actionable

Rules for diet:
- Act as a professional nutritionist. Calculate the user's Total Daily Energy Expenditure (TDEE) based on their weight: ${weight}kg, height: ${height}cm, age: $age, gender: $gender, and activity level: $activityLevel.
- Adjust the TDEE calories based on the goal: $goal (e.g., caloric deficit for weight loss, surplus for muscle gain).
- Calories and macros must match this personalized calculation.
- Protein target: at least 1.6g to 2.2g per kg of bodyweight (${weight}kg).
- Meals must add up to approximately the stated total personalized calories.
- Meal examples must be practical, realistic everyday foods.
- Tips must be specific to the goal: $goal

Return ONLY the JSON, nothing else.
''';
  }

  Future<void> _savePlan(WorkoutPlan plan) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint('⚠️ _savePlan: No user logged in');
      return;
    }
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.workoutPlansCollection)
          .doc(plan.id)
          .set(plan.toJson());
      debugPrint('✅ Plan saved: ${plan.id}');
    } catch (e) {
      debugPrint('❌ _savePlan error: $e');
      rethrow;
    }
  }

  Future<List<WorkoutPlan>> fetchSavedPlans() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.workoutPlansCollection)
          .limit(10)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(
            const Duration(seconds: 6),
            onTimeout: () async {
              debugPrint('⚠️ Server timeout, falling back to cache');
              return await _firestore
                  .collection(AppConstants.usersCollection)
                  .doc(uid)
                  .collection(AppConstants.workoutPlansCollection)
                  .limit(10)
                  .get(const GetOptions(source: Source.cache));
            },
          );

      final plans = <WorkoutPlan>[];
      for (final doc in snapshot.docs) {
        try {
          plans.add(WorkoutPlan.fromJson(doc.data()));
        } catch (e) {
          debugPrint('⚠️ Parse error for doc ${doc.id}: $e');
        }
      }

      plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      debugPrint('✅ Fetched ${plans.length} plans');
      return plans;
    } catch (e) {
      debugPrint('❌ fetchSavedPlans error: $e');
      rethrow;
    }
  }

  Future<void> deletePlan(String planId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.workoutPlansCollection)
          .doc(planId)
          .delete();
      debugPrint('✅ Plan deleted: $planId');
    } catch (e) {
      debugPrint('❌ deletePlan error: $e');
      rethrow;
    }
  }
}
