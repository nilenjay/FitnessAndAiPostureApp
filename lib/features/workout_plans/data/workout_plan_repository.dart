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

  late final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.groq.com',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AppConstants.groqApiKey}',
    },
  ));

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

    final response = await _dio.post(
      '/openai/v1/chat/completions',
      data: {
        'model': AppConstants.groqModel,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are an expert fitness coach. Return ONLY valid JSON with no markdown fences or extra text.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.7,
        'max_tokens': 4096,
        'response_format': {'type': 'json_object'},
      },
    );

    final data = response.data as Map<String, dynamic>;
    final text =
        data['choices'][0]['message']['content'] as String? ?? '';

    // Strip markdown fences if the model wraps in ```json
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
    if (uid == null) {
      debugPrint('⚠️ _savePlan: No user logged in');
      return;
    }

    try {
      debugPrint('💾 Saving plan ${plan.id} for user $uid');
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.workout_plansCollection)
          .doc(plan.id)
          .set(plan.toJson());
      debugPrint('✅ Plan saved successfully');
    } catch (e) {
      debugPrint('❌ _savePlan error: $e');
      rethrow;
    }
  }

  Future<List<WorkoutPlan>> fetchSavedPlans() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint('⚠️ fetchSavedPlans: No user logged in');
      return [];
    }

    try {
      debugPrint('📥 Fetching plans for user $uid');
      // Use a timeout and fallback to cache to prevent pending writes from deadlocking the server fetch
      final query = _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.workout_plansCollection)
          .orderBy('createdAt', descending: true)
          .limit(10);

      final snapshot = await query
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 4), onTimeout: () async {
        debugPrint('⚠️ Fetch timeout, falling back to cache...');
        return await query.get(const GetOptions(source: Source.cache));
      });

      debugPrint('📥 Got ${snapshot.docs.length} plan docs');

      final plans = <WorkoutPlan>[];
      for (final doc in snapshot.docs) {
        try {
          plans.add(WorkoutPlan.fromJson(doc.data()));
        } catch (parseError) {
          debugPrint('⚠️ Failed to parse plan ${doc.id}: $parseError');
        }
      }

      // Sort in memory (avoids Firestore index requirement and mixed-type issues)
      plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      debugPrint('✅ Returning ${plans.length} plans');
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
      debugPrint('🗑️ Deleting plan $planId');
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.workout_plansCollection)
          .doc(planId)
          .delete();
      debugPrint('✅ Plan deleted');
    } catch (e) {
      debugPrint('❌ deletePlan error: $e');
      rethrow;
    }
  }
}
