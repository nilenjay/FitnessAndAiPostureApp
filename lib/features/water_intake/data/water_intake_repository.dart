import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import 'water_intake_model.dart';

class WaterIntakeRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  DocumentReference? _todayDoc() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.waterIntakeCollection)
        .doc(_todayKey);
  }

  /// Fetches today's water intake (or creates a default entry).
  Future<WaterIntake> getTodayIntake() async {
    final doc = _todayDoc();
    if (doc == null) return WaterIntake(date: _todayKey);

    try {
      final snapshot = await doc
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(
        const Duration(seconds: 6),
        onTimeout: () => doc.get(const GetOptions(source: Source.cache)),
      );

      if (snapshot.exists) {
        return WaterIntake.fromJson(
            snapshot.data() as Map<String, dynamic>, _todayKey);
      }

      // Also read user's custom goal from their profile
      final goal = await _getUserGoal();
      return WaterIntake(date: _todayKey, goal: goal);
    } catch (e) {
      debugPrint('⚠️ getTodayIntake error: $e');
      return WaterIntake(date: _todayKey);
    }
  }

  /// Adds one glass to today's count.
  Future<WaterIntake> addGlass() async {
    final doc = _todayDoc();
    if (doc == null) return WaterIntake(date: _todayKey);

    try {
      final goal = await _getUserGoal();
      await doc.set({
        'glasses': FieldValue.increment(1),
        'goal': goal,
      }, SetOptions(merge: true));

      final snapshot = await doc.get();
      return WaterIntake.fromJson(
          snapshot.data() as Map<String, dynamic>, _todayKey);
    } catch (e) {
      debugPrint('⚠️ addGlass error: $e');
      return await getTodayIntake();
    }
  }

  /// Removes one glass from today's count (min 0).
  Future<WaterIntake> removeGlass() async {
    final doc = _todayDoc();
    if (doc == null) return WaterIntake(date: _todayKey);

    try {
      final current = await getTodayIntake();
      final newGlasses = (current.glasses - 1).clamp(0, 999);
      await doc.set({
        'glasses': newGlasses,
        'goal': current.goal,
      }, SetOptions(merge: true));

      return current.copyWith(glasses: newGlasses);
    } catch (e) {
      debugPrint('⚠️ removeGlass error: $e');
      return await getTodayIntake();
    }
  }

  /// Reads the user's daily water goal from their profile (defaults to 8).
  Future<int> _getUserGoal() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 8;

    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      if (userDoc.exists) {
        return userDoc.data()?['waterGoal'] as int? ?? 8;
      }
    } catch (_) {}
    return 8;
  }
}
