import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/bloc/auth_bloc.dart';

class ProfileSetupScreen extends StatefulWidget {
  /// When true, shows the onboarding variant (no back button, different title).
  final bool isOnboarding;

  const ProfileSetupScreen({super.key, this.isOnboarding = false});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  final _waterGoalController = TextEditingController(text: '8');

  String _selectedGender = 'Male';
  String _selectedActivityLevel = 'Lightly Active';
  bool _waterRemindersEnabled = true;
  int _reminderIntervalHours = 2;
  bool _isLoading = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _activityLevels = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active',
    'Extra Active'
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _waterGoalController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        if (mounted) {
          setState(() {
            _weightController.text = data['weight']?.toString() ?? '';
            _heightController.text = data['height']?.toString() ?? '';
            _ageController.text = data['age']?.toString() ?? '';
            _waterGoalController.text =
                (data['waterGoal'] ?? 8).toString();
            _waterRemindersEnabled = data['waterReminders'] ?? true;
            _reminderIntervalHours = data['reminderInterval'] ?? 2;

            if (data['gender'] != null && _genders.contains(data['gender'])) {
              _selectedGender = data['gender'];
            }
            if (data['activityLevel'] != null &&
                _activityLevels.contains(data['activityLevel'])) {
              _selectedActivityLevel = data['activityLevel'];
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .set({
          'weight': double.tryParse(_weightController.text) ?? 0,
          'height': double.tryParse(_heightController.text) ?? 0,
          'age': int.tryParse(_ageController.text) ?? 0,
          'gender': _selectedGender,
          'activityLevel': _selectedActivityLevel,
          'waterGoal': int.tryParse(_waterGoalController.text) ?? 8,
          'waterReminders': _waterRemindersEnabled,
          'reminderInterval': _reminderIntervalHours,
          'profileComplete': true,
        }, SetOptions(merge: true));

        // Handle water reminder notifications
        await _updateWaterReminders();

        if (mounted) {
          if (widget.isOnboarding) {
            context.read<AuthBloc>().add(AuthProfileCompleted());
            context.go('/home');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!')),
            );
            context.pop();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateWaterReminders() async {
    final notifService = NotificationService.instance;

    if (_waterRemindersEnabled) {
      // Request permission first
      await notifService.requestPermission();
      // Schedule reminders
      await notifService.scheduleWaterReminders(
        intervalHours: _reminderIntervalHours,
      );
    } else {
      await notifService.cancelWaterReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isOnboarding ? 'Complete Your Profile' : 'Edit Physical Details'),
        automaticallyImplyLeading: !widget.isOnboarding,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                widget.isOnboarding
                    ? 'Welcome! Tell us about yourself'
                    : 'Help us personalize your experience',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isOnboarding
                    ? 'We need a few details to create your personalized workout and diet plans.'
                    : 'These details ensure your AI-generated workouts and diet plans are perfectly calibrated for you.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Weight Input
              TextFormField(
                controller: _weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: 'e.g. 75.5',
                  prefixIcon:
                      const Icon(Icons.fitness_center, color: AppTheme.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // Height Input
              TextFormField(
                controller: _heightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Height (cm)',
                  hintText: 'e.g. 180',
                  prefixIcon:
                      const Icon(Icons.height, color: AppTheme.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // Age Input
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Age',
                  hintText: 'e.g. 28',
                  prefixIcon: const Icon(Icons.cake, color: AppTheme.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              // Gender Dropdown
              const Text('Gender',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                dropdownColor: AppTheme.surface,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                items: _genders.map((gender) {
                  return DropdownMenuItem(value: gender, child: Text(gender));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedGender = value!);
                },
              ),
              const SizedBox(height: 24),

              // Activity Level Dropdown
              const Text('Daily Activity Level',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedActivityLevel,
                dropdownColor: AppTheme.surface,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                items: _activityLevels.map((level) {
                  return DropdownMenuItem(value: level, child: Text(level));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedActivityLevel = value!);
                },
              ),
              const SizedBox(height: 32),

              // ── Hydration Section ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0091EA).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF00B8D4).withOpacity(0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.water_drop, color: Color(0xFF00E5FF), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Hydration Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Water Goal
                    const Text('Daily Water Goal (glasses)',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _GoalAdjustButton(
                          icon: Icons.remove,
                          onTap: () {
                            final current =
                                int.tryParse(_waterGoalController.text) ?? 8;
                            if (current > 1) {
                              setState(() =>
                                  _waterGoalController.text = '${current - 1}');
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _waterGoalController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.water_drop,
                                  color: Color(0xFF00B8D4)),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            validator: (value) {
                              final v = int.tryParse(value ?? '');
                              if (v == null || v < 1 || v > 20) {
                                return 'Enter 1–20';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        _GoalAdjustButton(
                          icon: Icons.add,
                          onTap: () {
                            final current =
                                int.tryParse(_waterGoalController.text) ?? 8;
                            if (current < 20) {
                              setState(() =>
                                  _waterGoalController.text = '${current + 1}');
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Recommended: 8 glasses (≈ 2 litres)',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),

                    // ── Water Reminder Toggle ────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active,
                              color: Color(0xFF00E5FF), size: 22),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Water Reminders',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Get notified to drink water',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _waterRemindersEnabled,
                            onChanged: (v) =>
                                setState(() => _waterRemindersEnabled = v),
                            activeColor: const Color(0xFF00E5FF),
                          ),
                        ],
                      ),
                    ),

                    // ── Reminder Interval ────────────────────────────────────
                    if (_waterRemindersEnabled) ...[
                      const SizedBox(height: 16),
                      const Text('Remind me every',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [1, 2, 3, 4].map((hours) {
                          final isSelected = _reminderIntervalHours == hours;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => _reminderIntervalHours = hours),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 8),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF00E5FF)
                                          .withOpacity(0.2)
                                      : AppTheme.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF00E5FF)
                                        : AppTheme.divider,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${hours}h',
                                    style: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFF00E5FF)
                                          : AppTheme.textSecondary,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reminders from 8 AM to 10 PM, every $_reminderIntervalHours hour${_reminderIntervalHours > 1 ? 's' : ''}',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          widget.isOnboarding
                              ? 'Continue'
                              : 'Save Profile',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                ),
              ),
              
              if (widget.isOnboarding) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () {
                      FirebaseFirestore.instance
                          .collection(AppConstants.usersCollection)
                          .doc(FirebaseAuth.instance.currentUser?.uid)
                          .set({'profileComplete': true}, SetOptions(merge: true));
                      context.read<AuthBloc>().add(AuthProfileCompleted());
                      context.go('/home');
                    },
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalAdjustButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GoalAdjustButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF00B8D4).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00B8D4).withOpacity(0.3),
            ),
          ),
          child: Icon(icon, color: const Color(0xFF00E5FF), size: 22),
        ),
      ),
    );
  }
}
