import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class SessionSummaryScreen extends StatelessWidget {
  final Map<String, dynamic> summaryData;
  const SessionSummaryScreen({super.key, required this.summaryData});

  @override
  Widget build(BuildContext context) {
    final exercise = summaryData['exercise'] as String? ?? 'workout';
    final reps = summaryData['reps'] as int? ?? 0;
    final score = summaryData['score'] as int? ?? 0;
    final feedbackList = summaryData['feedback'] as List<dynamic>? ?? [];
    final color = _scoreColor(score);

    return Scaffold(
      appBar: AppBar(title: const Text('Session Summary')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.emoji_events_rounded, color: color, size: 52),
                  const SizedBox(height: 12),
                  Text(
                    exercise.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _scoreLabel(score),
                    style: TextStyle(
                      color: color,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Reps',
                    value: '$reps',
                    icon: Icons.repeat,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Score',
                    value: '$score/100',
                    icon: Icons.star_outline,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (feedbackList.isNotEmpty) ...[
              Text(
                'AI Feedback',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...feedbackList.map((f) => _FeedbackTile(feedback: f.toString())),
              const SizedBox(height: 24),
            ],

            ElevatedButton(
              onPressed: () => context.go('/workout/select'),
              child: const Text('Start Another Workout'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppTheme.secondary;
    if (score >= 50) return AppTheme.primary;
    return AppTheme.error;
  }

  String _scoreLabel(int score) {
    if (score >= 90) return 'Excellent Form! 🔥';
    if (score >= 75) return 'Great Job! 💪';
    if (score >= 50) return 'Good Effort! 👍';
    return 'Keep Practicing! 🏋️';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _FeedbackTile extends StatelessWidget {
  final String feedback;
  const _FeedbackTile({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final isPositive =
        feedback.toLowerCase().contains('good') ||
        feedback.toLowerCase().contains('great') ||
        feedback.toLowerCase().contains('rep');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.check_circle_outline : Icons.info_outline,
            color: isPositive ? AppTheme.secondary : AppTheme.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              feedback,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
