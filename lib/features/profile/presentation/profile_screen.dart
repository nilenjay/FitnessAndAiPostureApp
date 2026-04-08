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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(AuthSignOutRequested());
              context.go('/login');
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.primary),
            tooltip: 'Edit Profile',
            onPressed: () => context.push('/profile/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.error),
            tooltip: 'Sign Out',
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('No user found'))
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection(AppConstants.usersCollection)
                  .doc(user.uid)
                  .get(const GetOptions(source: Source.serverAndCache))
                  .timeout(
                    const Duration(seconds: 6),
                    onTimeout: () => FirebaseFirestore.instance
                        .collection(AppConstants.usersCollection)
                        .doc(user.uid)
                        .get(const GetOptions(source: Source.cache)),
                  ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                final userData =
                    snapshot.data?.data() as Map<String, dynamic>? ?? {};
                final totalReps = userData['totalReps'] ?? 0;
                final totalSessions = userData['totalSessions'] ?? 0;
                final streak = userData['streak'] ?? 0;

                final weight = userData['weight'];
                final height = userData['height'];
                final age = userData['age'];
                final gender = userData['gender'];
                final waterGoal = userData['waterGoal'] ?? 8;

                final initial = (user.displayName ?? 'A')
                    .substring(0, 1)
                    .toUpperCase();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppTheme.primary.withOpacity(0.15),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user.displayName ?? 'Athlete',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email ?? '',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),

                      if (weight != null || height != null || age != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildDetailItem(
                                    'Weight',
                                    weight != null ? '${weight}kg' : '--',
                                  ),
                                  _buildDetailItem(
                                    'Height',
                                    height != null ? '${height}cm' : '--',
                                  ),
                                  _buildDetailItem(
                                    'Age',
                                    age != null ? '$age' : '--',
                                  ),
                                ],
                              ),
                              if (gender != null) ...[
                                const SizedBox(height: 12),
                                const Divider(
                                  color: AppTheme.divider,
                                  height: 1,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildDetailItem('Gender', '$gender'),
                                    _buildDetailItem(
                                      'Water Goal',
                                      '$waterGoal 💧',
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],

                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _StatCard(
                            'Total Reps',
                            '$totalReps',
                            Icons.fitness_center,
                            AppTheme.primary,
                          ),
                          _StatCard(
                            'Sessions',
                            '$totalSessions',
                            Icons.calendar_today,
                            AppTheme.secondary,
                          ),
                          _StatCard(
                            'Streak',
                            '$streak Days',
                            Icons.local_fire_department,
                            Colors.orange,
                          ),
                          _StatCard(
                            'Level',
                            totalSessions < 10
                                ? 'Beginner'
                                : totalSessions < 30
                                ? 'Intermediate'
                                : 'Advanced',
                            Icons.psychology,
                            Colors.purpleAccent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.purpleAccent.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: Colors.purpleAccent,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'AI Health Twin',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.purpleAccent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Your digital health model evolves based on your form and consistency.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (totalSessions % 10) / 10.0,
                                backgroundColor: Colors.white10,
                                color: Colors.purpleAccent,
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${10 - (totalSessions % 10)} sessions until next AI update',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      OutlinedButton.icon(
                        onPressed: () => _showLogoutDialog(context),
                        icon: const Icon(
                          Icons.logout,
                          color: AppTheme.error,
                          size: 18,
                        ),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(
                            color: AppTheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.error),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

Widget _buildDetailItem(String label, String value) {
  return Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppTheme.primary,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      ),
    ],
  );
}
