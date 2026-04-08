import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_constants.dart';

class PoseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveSession({
    required String exercise,
    required int reps,
    required int score,
    required List<String> feedback,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final sessionData = {
      'exercise': exercise,
      'reps': reps,
      'score': score,
      'feedback': feedback,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.sessionsCollection)
        .add(sessionData);

    await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
      'totalReps': FieldValue.increment(reps),
      'totalSessions': FieldValue.increment(1),
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
