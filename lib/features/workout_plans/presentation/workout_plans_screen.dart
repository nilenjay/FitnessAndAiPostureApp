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

class _WorkoutPlansScreenState extends State<WorkoutPlansScreen>
    with SingleTickerProviderStateMixin {
  int _selectedDayIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final state = context.read<WorkoutPlanBloc>().state;
    if (state is! WorkoutPlanLoaded) {
      context.read<WorkoutPlanBloc>().add(WorkoutPlanFetch());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.fitness_center, size: 18), text: 'Workout'),
            Tab(icon: Icon(Icons.restaurant_menu, size: 18), text: 'Diet'),
          ],
        ),
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
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (state is WorkoutPlanLoaded) {
            if (state.plans.isEmpty) {
              return _EmptyView(onGenerate: _showGenerateSheet);
            }
            final selectedPlan = state.selectedPlan ?? state.plans.first;
            return TabBarView(
              controller: _tabController,
              children: [
                // ── Workout tab ──────────────────────────────────────────────
                _PlanView(
                  plans: state.plans,
                  selectedPlan: selectedPlan,
                  selectedDayIndex: _selectedDayIndex,
                  onDaySelected: (i) => setState(() => _selectedDayIndex = i),
                  onPlanSelected: (plan) {
                    context
                        .read<WorkoutPlanBloc>()
                        .add(WorkoutPlanSelect(plan));
                    setState(() => _selectedDayIndex = 0);
                  },
                  onDelete: (id) =>
                      context.read<WorkoutPlanBloc>().add(WorkoutPlanDelete(id)),
                  onGenerate: _showGenerateSheet,
                ),
                // ── Diet tab ─────────────────────────────────────────────────
                selectedPlan.dietPlan != null
                    ? _DietView(dietPlan: selectedPlan.dietPlan!)
                    : _NoDietView(onGenerate: _showGenerateSheet),
              ],
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
        label: const Text('New Plan',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ─── Diet views ──────────────────────────────────────────────────────────────

class _NoDietView extends StatelessWidget {
  final VoidCallback onGenerate;
  const _NoDietView({required this.onGenerate});

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
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle),
              child:
              const Icon(Icons.restaurant_menu, color: AppTheme.primary, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('No Diet Plan',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Generate a new plan to get a personalised diet with macros and meal suggestions.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Generate Plan with Diet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DietView extends StatelessWidget {
  final DietPlan dietPlan;
  const _DietView({required this.dietPlan});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Strategy label ──────────────────────────────────────────────────
        if (dietPlan.goal.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    dietPlan.goal,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Macro cards ─────────────────────────────────────────────────────
        const _SectionHeader('Daily targets'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MacroCard(
                label: 'Calories',
                value: '${dietPlan.calories}',
                unit: 'kcal',
                color: AppTheme.primary,
                icon: Icons.local_fire_department_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MacroCard(
                label: 'Protein',
                value: '${dietPlan.proteinG}g',
                unit: 'per day',
                color: AppTheme.secondary,
                icon: Icons.egg_alt_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MacroCard(
                label: 'Carbs',
                value: '${dietPlan.carbsG}g',
                unit: 'per day',
                color: const Color(0xFFF4A623),
                icon: Icons.grain_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MacroCard(
                label: 'Fat',
                value: '${dietPlan.fatG}g',
                unit: 'per day',
                color: AppTheme.error,
                icon: Icons.opacity_outlined,
              ),
            ),
          ],
        ),

        // ── Macro bar ───────────────────────────────────────────────────────
        const SizedBox(height: 16),
        _MacroBar(
          proteinG: dietPlan.proteinG,
          carbsG: dietPlan.carbsG,
          fatG: dietPlan.fatG,
        ),

        // ── Meals ───────────────────────────────────────────────────────────
        const SizedBox(height: 20),
        const _SectionHeader('Meal suggestions'),
        const SizedBox(height: 10),
        ...dietPlan.meals.map((meal) => _MealCard(meal: meal)),

        // ── Tips ────────────────────────────────────────────────────────────
        if (dietPlan.tips.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionHeader('Nutrition tips'),
          const SizedBox(height: 10),
          ...dietPlan.tips.map((tip) => _TipTile(tip: tip)),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700));
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;
  const _MacroCard(
      {required this.label,
        required this.value,
        required this.unit,
        required this.color,
        required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.w800)),
          Text(unit,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final int proteinG;
  final int carbsG;
  final int fatG;
  const _MacroBar(
      {required this.proteinG, required this.carbsG, required this.fatG});

  @override
  Widget build(BuildContext context) {
    // Convert to calories for proportion (protein=4, carbs=4, fat=9)
    final pCal = proteinG * 4;
    final cCal = carbsG * 4;
    final fCal = fatG * 9;
    final total = (pCal + cCal + fCal).toDouble();
    if (total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Macro split (by calories)',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: [
              Flexible(
                flex: (pCal / total * 100).round(),
                child: Container(
                    height: 12, color: AppTheme.secondary),
              ),
              Flexible(
                flex: (cCal / total * 100).round(),
                child: Container(
                    height: 12, color: const Color(0xFFF4A623)),
              ),
              Flexible(
                flex: (fCal / total * 100).round(),
                child: Container(height: 12, color: AppTheme.error),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _BarLegend(color: AppTheme.secondary, label: 'Protein'),
            const SizedBox(width: 12),
            _BarLegend(color: const Color(0xFFF4A623), label: 'Carbs'),
            const SizedBox(width: 12),
            _BarLegend(color: AppTheme.error, label: 'Fat'),
          ],
        ),
      ],
    );
  }
}

class _BarLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _BarLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  final MealSuggestion meal;
  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
              Text(meal.name,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${meal.calories} kcal',
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${meal.proteinG}g protein',
                    style: const TextStyle(
                        color: AppTheme.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (meal.example.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(meal.example,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.4)),
          ],
        ],
      ),
    );
  }
}

class _TipTile extends StatelessWidget {
  final String tip;
  const _TipTile({required this.tip});

  @override
  Widget build(BuildContext context) {
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
          const Icon(Icons.lightbulb_outline,
              color: AppTheme.primary, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(tip,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ─── Workout tab helpers (unchanged from original) ────────────────────────────

class _GeneratingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                  strokeWidth: 3, color: AppTheme.primary)),
          SizedBox(height: 24),
          Text('AI is crafting your plan...',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('Personalising exercises and diet just for you',
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome,
                  color: AppTheme.primary, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('No Plans Yet',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Let AI generate a personalised workout + diet plan tailored to your goals',
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
    required this.plans,
    required this.selectedPlan,
    required this.selectedDayIndex,
    required this.onDaySelected,
    required this.onPlanSelected,
    required this.onDelete,
    required this.onGenerate,
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
                    margin:
                    const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withOpacity(0.15)
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.divider),
                    ),
                    child: Center(
                      child: Text(
                        DateFormat('MMM d').format(plan.createdAt),
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
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
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                            '${selectedPlan.level} · ${selectedPlan.daysPerWeek} days/week',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13)),
                        if (selectedPlan.dietPlan != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('+ Diet',
                                style: TextStyle(
                                    color: AppTheme.secondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppTheme.error, size: 20),
                onPressed: () => showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    backgroundColor: AppTheme.surface,
                    title: const Text('Delete Plan',
                        style: TextStyle(color: AppTheme.textPrimary)),
                    content: const Text('Are you sure?',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          onDelete(selectedPlan.id);
                        },
                        child: const Text('Delete',
                            style: TextStyle(color: AppTheme.error)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
                    color: isSelected
                        ? AppTheme.primary.withOpacity(0.15)
                        : AppTheme.surface,
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
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Icon(
                        day.isRestDay ? Icons.hotel : Icons.fitness_center,
                        size: 14,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: selectedDay != null
              ? _DayDetail(day: selectedDay)
              : const SizedBox.shrink(),
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
            Text('Rest Day',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            SizedBox(height: 8),
            Text('Recovery is part of training.\nRest, hydrate, and come back stronger!',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center),
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
              Text(day.focus,
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...day.exercises
            .asMap()
            .entries
            .map((e) => _ExerciseCard(index: e.key + 1, exercise: e.value)),
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
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: Center(
                    child: Text('$index',
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800))),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(exercise.name,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700))),
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
              decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: AppTheme.secondary, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(exercise.tip,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12))),
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
      decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}