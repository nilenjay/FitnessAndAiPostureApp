import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Workout History')),
      body: uid == null
          ? const Center(child: Text('Please login to see history'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(AppConstants.usersCollection)
                  .doc(uid)
                  .collection(AppConstants.sessionsCollection)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Error loading history'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text('No workouts recorded yet.', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final timestamp = data['timestamp'] != null 
                        ? (data['timestamp'] as Timestamp).toDate() 
                        : DateTime.now();
                    final score = data['score'] as int? ?? 0;
                    final reps = data['reps'] as int? ?? 0;
                    final exercise = data['exercise'] as String? ?? 'Workout';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getScoreColor(score).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getExerciseIcon(exercise),
                            color: _getScoreColor(score),
                          ),
                        ),
                        title: Text(
                          exercise.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        subtitle: Text(
                          DateFormat('MMM dd, yyyy • HH:mm').format(timestamp),
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$reps Reps', style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                              'Score: $score',
                              style: TextStyle(
                                color: _getScoreColor(score),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppTheme.secondary;
    if (score >= 50) return AppTheme.primary;
    return AppTheme.error;
  }

  IconData _getExerciseIcon(String exercise) {
    switch (exercise.toLowerCase()) {
      case 'squat': return Icons.airline_seat_legroom_extra;
      case 'pushup': return Icons.fitness_center;
      case 'lunge': return Icons.directions_walk;
      case 'plank': return Icons.timer;
      default: return Icons.directions_run;
    }
  }
}
