import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/workout_plan_bloc.dart';
import '../../../core/theme/app_theme.dart';

class GeneratePlanSheet extends StatefulWidget {
  const GeneratePlanSheet({super.key});

  @override
  State<GeneratePlanSheet> createState() => _GeneratePlanSheetState();
}

class _GeneratePlanSheetState extends State<GeneratePlanSheet> {
  String _goal = 'Weight Loss';
  String _level = 'Beginner';
  int _daysPerWeek = 3;
  String _equipment = 'No equipment (bodyweight only)';

  final List<String> _goals = [
    'Weight Loss',
    'Muscle Gain',
    'Endurance',
    'Flexibility',
    'General Fitness',
  ];

  final List<String> _levels = ['Beginner', 'Intermediate', 'Advanced'];

  final List<String> _equipmentOptions = [
    'No equipment (bodyweight only)',
    'Dumbbells only',
    'Full gym access',
    'Resistance bands',
    'Home gym (dumbbells + bench)',
  ];

  void _generate() {
    context.read<WorkoutPlanBloc>().add(
      WorkoutPlanGenerate(
        goal: _goal,
        level: _level,
        daysPerWeek: _daysPerWeek,
        equipment: _equipment,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Generate AI Plan',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Gemini will create a personalized weekly plan for you',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Goal
            _SectionLabel('Fitness Goal'),
            _ChipSelector(
              options: _goals,
              selected: _goal,
              onSelected: (v) => setState(() => _goal = v),
            ),
            const SizedBox(height: 20),

            // Level
            _SectionLabel('Fitness Level'),
            _ChipSelector(
              options: _levels,
              selected: _level,
              onSelected: (v) => setState(() => _level = v),
            ),
            const SizedBox(height: 20),

            // Days per week
            _SectionLabel('Days Per Week: $_daysPerWeek'),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppTheme.primary,
                inactiveTrackColor: AppTheme.divider,
                thumbColor: AppTheme.primary,
                overlayColor: AppTheme.primary.withOpacity(0.2),
                valueIndicatorColor: AppTheme.primary,
                valueIndicatorTextStyle:
                const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
              ),
              child: Slider(
                value: _daysPerWeek.toDouble(),
                min: 2,
                max: 6,
                divisions: 4,
                label: '$_daysPerWeek days',
                onChanged: (v) => setState(() => _daysPerWeek = v.toInt()),
              ),
            ),
            const SizedBox(height: 20),

            // Equipment
            _SectionLabel('Equipment Available'),
            _DropdownSelector(
              options: _equipmentOptions,
              selected: _equipment,
              onSelected: (v) => setState(() => _equipment = v),
            ),
            const SizedBox(height: 28),

            ElevatedButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Generate My Plan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ChipSelector extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const _ChipSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option == selected;
        return GestureDetector(
          onTap: () => onSelected(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withOpacity(0.15)
                  : AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.divider,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DropdownSelector extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const _DropdownSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          dropdownColor: AppTheme.surfaceVariant,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) {
            if (v != null) onSelected(v);
          },
        ),
      ),
    );
  }
}