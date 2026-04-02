import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../water_intake/bloc/water_intake_cubit.dart';
import '../../water_intake/presentation/water_intake_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load today's water intake when home screen opens
    context.read<WaterIntakeCubit>().loadToday();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload water intake when app resumes (handles midnight reset)
    if (state == AppLifecycleState.resumed) {
      context.read<WaterIntakeCubit>().loadToday();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.split(' ').first ?? 'Athlete';

    return Scaffold(
      appBar: AppBar(
        title: Text('Good ${_greeting()}, $name 👋',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<WaterIntakeCubit>().loadToday();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Health Twin Status (Quick view)
              _AIStatusCard(user?.uid),
              const SizedBox(height: 20),

              // 💧 Water Intake Tracker
              const WaterIntakeCard(),
              const SizedBox(height: 20),
              
              // Start Workout CTA
              _StartWorkoutCard(context),
              const SizedBox(height: 24),
              
              Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              _QuickActionsGrid(context),
              const SizedBox(height: 24),
              
              Text('Recent Activity', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              _RecentActivityList(user?.uid),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _AIStatusCard(String? uid) {
    if (uid == null) return const SizedBox.shrink();
    
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection(AppConstants.usersCollection).doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final sessions = data['totalSessions'] ?? 0;
        final streak = data['streak'] ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purpleAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.psychology, color: Colors.purpleAccent, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Health Twin', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                    Text(
                      sessions > 0 ? 'Analyzing your $streak-day streak...' : 'Complete a workout to activate AI Twin',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              if (sessions > 0)
                const Icon(Icons.chevron_right, color: Colors.purpleAccent),
            ],
          ),
        );
      },
    );
  }

  Widget _StartWorkoutCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/workout/select'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFF0091EA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.play_circle_fill, color: Colors.black, size: 40),
            const SizedBox(height: 16),
            const Text(
              'Start Workout',
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'AI will analyze your form in real-time',
              style: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _QuickActionsGrid(BuildContext context) {
    final actions = [
      {'icon': Icons.auto_awesome, 'label': 'AI Plans', 'route': '/plans', 'color': AppTheme.secondary},
      {'icon': Icons.history, 'label': 'History', 'route': '/history', 'color': AppTheme.primary},
    ];

    return Row(
      children: actions.map((a) {
        return Expanded(
          child: GestureDetector(
            onTap: () => context.go(a['route'] as String),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(a['icon'] as IconData, color: a['color'] as Color, size: 28),
                  const SizedBox(height: 12),
                  Text(
                    a['label'] as String,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _RecentActivityList(String? uid) {
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.sessionsCollection)
          .orderBy('timestamp', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _EmptyActivityPlaceholder();
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : DateTime.now();
            final exercise = data['exercise'] as String? ?? 'Workout';
            final score = data['score'] as int? ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fitness_center, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exercise.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(DateFormat('MMM dd • HH:mm').format(timestamp), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  Text(
                    'Form: $score%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: score >= 80 ? AppTheme.secondary : (score >= 50 ? AppTheme.primary : AppTheme.error),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _EmptyActivityPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: const Column(
        children: [
          Icon(Icons.fitness_center, color: AppTheme.textSecondary, size: 40),
          SizedBox(height: 12),
          Text('No workouts yet', style: TextStyle(color: AppTheme.textSecondary)),
          Text('Complete your first session to see activity', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
