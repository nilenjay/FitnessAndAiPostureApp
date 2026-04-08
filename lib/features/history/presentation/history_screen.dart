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
          : FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection(AppConstants.usersCollection)
                  .doc(uid)
                  .collection(AppConstants.sessionsCollection)
                  .limit(50)
                  .get(const GetOptions(source: Source.serverAndCache))
                  .timeout(
                    const Duration(seconds: 6),
                    onTimeout: () => FirebaseFirestore.instance
                        .collection(AppConstants.usersCollection)
                        .doc(uid)
                        .collection(AppConstants.sessionsCollection)
                        .limit(50)
                        .get(const GetOptions(source: Source.cache)),
                  ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.error,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${snapshot.error}',
                          style: const TextStyle(color: AppTheme.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final docs = List.from(snapshot.data?.docs ?? []);
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTs = aData['timestamp'] as Timestamp?;
                  final bTs = bData['timestamp'] as Timestamp?;
                  if (aTs == null && bTs == null) return 0;
                  if (aTs == null) return 1;
                  if (bTs == null) return -1;
                  return bTs.compareTo(aTs);
                });

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: AppTheme.textSecondary.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No workouts recorded yet.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Complete a session to see it here.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
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
                    final color = _getScoreColor(score);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getExerciseIcon(exercise), color: color),
                        ),
                        title: Text(
                          exercise.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat('MMM dd, yyyy • HH:mm').format(timestamp),
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$reps Reps',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Score: $score',
                              style: TextStyle(
                                color: color,
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
      case 'squat':
        return Icons.airline_seat_legroom_extra;
      case 'pushup':
        return Icons.fitness_center;
      case 'lunge':
        return Icons.directions_walk;
      case 'plank':
        return Icons.timer;
      default:
        return Icons.directions_run;
    }
  }
}
