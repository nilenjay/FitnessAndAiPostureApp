import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/pose_detection/presentation/exercise_select_screen.dart';
import '../../features/pose_detection/presentation/pose_session_screen.dart';
import '../../features/pose_detection/presentation/session_summary_screen.dart';
import '../../features/workout_plans/presentation/workout_plans_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../widgets/main_shell_screen.dart';
import '../widgets/splash_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  // Call this once in main.dart after BLoC is ready
  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      refreshListenable: _AuthChangeNotifier(authBloc),
      redirect: (context, state) {
        final authState = authBloc.state;
        final isAuthenticated = authState is AuthAuthenticated;
        final location = state.uri.path; // ✅ fixed: uri.path not matchedLocation

        final isOnAuthScreen = location == '/login' ||
            location == '/signup' ||
            location == '/splash';

        if (authState is AuthInitial || authState is AuthLoading) {
          return '/splash';
        }

        if (!isAuthenticated && !isOnAuthScreen) {
          return '/login';
        }

        if (isAuthenticated && (location == '/login' || location == '/signup')) {
          return '/home';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),

        // Shell route: screens that share the bottom navigation bar
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) => MainShellScreen(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/workout/select',
              builder: (context, state) => const ExerciseSelectScreen(),
            ),
            GoRoute(
              path: '/plans',
              builder: (context, state) => const WorkoutPlansScreen(),
            ),
            GoRoute(
              path: '/history',
              builder: (context, state) => const HistoryScreen(),
            ),
          ],
        ),

        // Full-screen routes (no bottom nav)
        GoRoute(
          path: '/workout/session',
          builder: (context, state) {
            final exercise = state.extra as String? ?? 'squat';
            return PoseSessionScreen(exercise: exercise);
          },
        ),
        GoRoute(
          path: '/workout/summary',
          builder: (context, state) {
            final data = state.extra as Map<String, dynamic>? ?? {};
            return SessionSummaryScreen(summaryData: data);
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Page not found: ${state.error}'),
        ),
      ),
    );
  }
}

// ✅ Properly wired to AuthBloc stream — fires on every auth state change
class _AuthChangeNotifier extends ChangeNotifier {
  final AuthBloc _authBloc;
  late final StreamSubscription _subscription;

  _AuthChangeNotifier(this._authBloc) {
    _subscription = _authBloc.stream.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}