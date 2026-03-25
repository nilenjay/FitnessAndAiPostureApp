import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class ExerciseSelectScreen extends StatelessWidget {
  const ExerciseSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Exercise'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: AppConstants.supportedExercises.length,
        itemBuilder: (context, index) {
          final exercise = AppConstants.supportedExercises[index];
          return _ExerciseCard(exercise: exercise);
        },
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final String exercise;
  const _ExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/workout/session', extra: exercise),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(exercise),
                color: AppTheme.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              exercise.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'AI Form Check',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String exercise) {
    switch (exercise.toLowerCase()) {
      case 'squat': return Icons.airline_seat_legroom_extra;
      case 'pushup': return Icons.fitness_center;
      case 'lunge': return Icons.directions_walk;
      case 'plank': return Icons.timer;
      default: return Icons.help_outline;
    }
  }
}
