import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/workout_plan_bloc.dart';
import '../data/workout_plan_model.dart';
import '../../../core/theme/app_theme.dart';
import 'generate_plan_sheet.dart';

class WorkoutPlansScreen extends StatefulWidget {
  const WorkoutPlansScreen({super.key});

  @override
  State<WorkoutPlansScreen> createState() => _WorkoutPlansScreenState();
}

class _WorkoutPlansScreenState extends State<WorkoutPlansScreen> {
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<WorkoutPlanBloc>().add(WorkoutPlanFetch());
  }

  void _showGenerateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<WorkoutPlanBloc>(),
        child: const GeneratePlanSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Workout Plans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppTheme.primary),
            onPressed: _showGenerateSheet,
          ),
        ],
      ),
      body: BlocConsumer<WorkoutPlanBloc, WorkoutPlanState>(
        listener: (context, state) {
          if (state is WorkoutPlanError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is WorkoutPlanGenerated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ New plan generated and saved!'),
              ),
            );
            setState(() => _selectedDayIndex = 0);
          }
        },
        builder: (context, state) {
          if (state is WorkoutPlanGenerating) return _GeneratingView();
          if (state is WorkoutPlanLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (state is WorkoutPlanLoaded) {
            if (state.plans.isEmpty) return _EmptyView(onGenerate: _showGenerateSheet);
            return _PlanView(
              plans: state.plans,
              selectedPlan: state.selectedPlan ?? state.plans.first,
              selectedDayIndex: _selectedDayIndex,
              onDaySelected: (i) => setState(() => _selectedDayIndex = i),
              onPlanSelected: (plan) {
                context.read<WorkoutPlanBloc>().add(WorkoutPlanSelect(plan));
                setState(() => _selectedDayIndex = 0);
              },
              onDelete: (id) => context.read<WorkoutPlanBloc>().add(WorkoutPlanDelete(id)),
              onGenerate: _showGenerateSheet,
            );
          }
          return _EmptyView(onGenerate: _showGenerateSheet);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showGenerateSheet,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('New Plan', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _GeneratingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 56, height: 56,
              child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.primary)),
          SizedBox(height: 24),
          Text('AI is crafting your plan...',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('Personalizing exercises just for you',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onGenerate;
  const _EmptyView({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('No Plans Yet',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Let AI generate a personalized workout plan tailored to your goals',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Generate My First Plan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanView extends StatelessWidget {
  final List<WorkoutPlan> plans;
  final WorkoutPlan selectedPlan;
  final int selectedDayIndex;
  final ValueChanged<int> onDaySelected;
  final ValueChanged<WorkoutPlan> onPlanSelected;
  final ValueChanged<String> onDelete;
  final VoidCallback onGenerate;

  const _PlanView({
    required this.plans, required this.selectedPlan,
    required this.selectedDayIndex, required this.onDaySelected,
    required this.onPlanSelected, required this.onDelete, required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final selectedDay = selectedPlan.days.isNotEmpty
        ? selectedPlan.days[selectedDayIndex.clamp(0, selectedPlan.days.length - 1)]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (plans.length > 1)
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: plans.length,
              itemBuilder: (context, i) {
                final plan = plans[i];
                final isSelected = plan.id == selectedPlan.id;
                return GestureDetector(
                  onTap: () => onPlanSelected(plan),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary.withOpacity(0.15) : AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.divider),
                    ),
                    child: Center(
                      child: Text(
                        DateFormat('MMM d').format(plan.createdAt),
                        style: TextStyle(
                          color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // Plan header
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(selectedPlan.goal,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${selectedPlan.level} · ${selectedPlan.daysPerWeek} days/week',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                onPressed: () => showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    backgroundColor: AppTheme.surface,
                    title: const Text('Delete Plan', style: TextStyle(color: AppTheme.textPrimary)),
                    content: const Text('Are you sure?', style: TextStyle(color: AppTheme.textSecondary)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () { Navigator.pop(dialogContext); onDelete(selectedPlan.id); },
                        child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Day tabs
        SizedBox(
          height: 64,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: selectedPlan.days.length,
            itemBuilder: (context, i) {
              final day = selectedPlan.days[i];
              final isSelected = i == selectedDayIndex;
              return GestureDetector(
                onTap: () => onDaySelected(i),
                child: Container(
                  width: 56,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary.withOpacity(0.15) : AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.divider,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day.dayName.substring(0, 3).toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                          fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Icon(
                        day.isRestDay ? Icons.hotel : Icons.fitness_center,
                        size: 14,
                        color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Day detail
        Expanded(
          child: selectedDay != null ? _DayDetail(day: selectedDay) : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _DayDetail extends StatelessWidget {
  final WorkoutDay day;
  const _DayDetail({required this.day});

  @override
  Widget build(BuildContext context) {
    if (day.isRestDay) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hotel, color: AppTheme.primary, size: 52),
            SizedBox(height: 16),
            Text('Rest Day', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
            SizedBox(height: 8),
            Text('Recovery is part of training.\nRest, hydrate, and come back stronger!',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.track_changes, color: AppTheme.primary, size: 14),
              const SizedBox(width: 6),
              Text(day.focus, style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...day.exercises.asMap().entries.map((e) => _ExerciseCard(index: e.key + 1, exercise: e.value)),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final int index;
  final WorkoutExercise exercise;
  const _ExerciseCard({required this.index, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text('$index',
                    style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w800))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(exercise.name,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat(label: 'Sets', value: '${exercise.sets}'),
              const SizedBox(width: 12),
              _MiniStat(label: 'Reps', value: exercise.reps),
              const SizedBox(width: 12),
              _MiniStat(label: 'Rest', value: exercise.rest),
            ],
          ),
          if (exercise.tip.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppTheme.secondary, size: 14),
                  const SizedBox(width: 6),
                  Expanded(child: Text(exercise.tip,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}