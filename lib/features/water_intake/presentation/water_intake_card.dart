import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/water_intake_cubit.dart';

class WaterIntakeCard extends StatelessWidget {
  const WaterIntakeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WaterIntakeCubit, WaterIntakeState>(
      builder: (context, state) {
        int glasses = 0;
        int goal = 8;
        double progress = 0.0;
        bool goalReached = false;

        if (state is WaterIntakeLoaded) {
          glasses = state.intake.glasses;
          goal = state.intake.goal;
          progress = state.intake.progress;
          goalReached = state.intake.isGoalReached;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: goalReached
                  ? [
                      const Color(0xFF00E5FF).withOpacity(0.15),
                      const Color(0xFF76FF03).withOpacity(0.10),
                    ]
                  : [
                      const Color(0xFF0091EA).withOpacity(0.12),
                      const Color(0xFF00B8D4).withOpacity(0.08),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: goalReached
                  ? AppTheme.secondary.withOpacity(0.4)
                  : const Color(0xFF00B8D4).withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B8D4).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      color: Color(0xFF00E5FF),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Hydration',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          goalReached
                              ? '🎉 Goal reached! Great job!'
                              : '${goal - glasses} more glass${(goal - glasses) != 1 ? 'es' : ''} to go',
                          style: TextStyle(
                            fontSize: 12,
                            color: goalReached
                                ? AppTheme.secondary
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Progress ring + count
              Row(
                children: [
                  // Circular progress
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: _AnimatedWaterRing(
                      progress: progress,
                      goalReached: goalReached,
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Count display
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$glasses',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: goalReached
                                      ? AppTheme.secondary
                                      : const Color(0xFF00E5FF),
                                ),
                              ),
                              TextSpan(
                                text: ' / $goal',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'glasses today',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // + / - buttons
                  Column(
                    children: [
                      _WaterButton(
                        icon: Icons.add,
                        onTap: () =>
                            context.read<WaterIntakeCubit>().addGlass(),
                        color: const Color(0xFF00E5FF),
                      ),
                      const SizedBox(height: 8),
                      _WaterButton(
                        icon: Icons.remove,
                        onTap: glasses > 0
                            ? () => context
                                .read<WaterIntakeCubit>()
                                .removeGlass()
                            : null,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),

              // Mini glass indicators
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: List.generate(goal, (i) {
                  final filled = i < glasses;
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 200 + i * 50),
                    curve: Curves.easeOut,
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: filled
                          ? const Color(0xFF00E5FF).withOpacity(0.25)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: filled
                            ? const Color(0xFF00E5FF).withOpacity(0.5)
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Icon(
                      Icons.water_drop,
                      size: 14,
                      color: filled
                          ? const Color(0xFF00E5FF)
                          : Colors.white.withOpacity(0.15),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Animated circular progress ring ─────────────────────────────────────────

class _AnimatedWaterRing extends StatelessWidget {
  final double progress;
  final bool goalReached;

  const _AnimatedWaterRing({
    required this.progress,
    required this.goalReached,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return CustomPaint(
          painter: _RingPainter(
            progress: value,
            goalReached: goalReached,
          ),
          child: Center(
            child: Icon(
              goalReached ? Icons.check_circle : Icons.water_drop,
              color: goalReached
                  ? AppTheme.secondary
                  : const Color(0xFF00E5FF),
              size: 28,
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final bool goalReached;

  _RingPainter({required this.progress, required this.goalReached});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 4;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final fgPaint = Paint()
      ..color = goalReached
          ? AppTheme.secondary
          : const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.goalReached != goalReached;
}

// ─── Small round +/- button ──────────────────────────────────────────────────

class _WaterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _WaterButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(onTap != null ? 0.15 : 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(onTap != null ? 0.4 : 0.1),
            ),
          ),
          child: Icon(
            icon,
            color: onTap != null ? color : color.withOpacity(0.3),
            size: 20,
          ),
        ),
      ),
    );
  }
}
