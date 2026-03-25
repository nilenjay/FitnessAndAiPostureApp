import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.error),
            onPressed: () {
              context.read<AuthBloc>().add(AuthLoggedOut());
              context.go('/login');
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('No user found'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(AppConstants.usersCollection)
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                final totalReps = userData['totalReps'] ?? 0;
                final totalSessions = userData['totalSessions'] ?? 0;
                final streak = userData['streak'] ?? 0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primary,
                        child: Icon(Icons.person, size: 50, color: Colors.black),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.displayName ?? 'Athlete',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user.email ?? '',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 32),
                      
                      // Stats Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          _StatCard('Total Reps', '$totalReps', Icons.fitness_center, AppTheme.primary),
                          _StatCard('Sessions', '$totalSessions', Icons.calendar_today, AppTheme.secondary),
                          _StatCard('Streak', '$streak Days', Icons.local_fire_department, Colors.orange),
                          _StatCard('AI Twin', 'Level 1', Icons.psychology, Colors.purpleAccent),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // AI Health Twin Preview (The "Wow" factor)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.auto_awesome, color: Colors.purpleAccent),
                                SizedBox(width: 8),
                                Text(
                                  'AI Health Twin',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purpleAccent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Your digital health model is evolving based on your form and consistency.',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: (totalSessions % 10) / 10.0,
                              backgroundColor: Colors.white10,
                              color: Colors.purpleAccent,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${10 - (totalSessions % 10)} sessions until next AI update',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _StatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
