import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class MainShellScreen extends StatelessWidget {
  final Widget child;
  const MainShellScreen({super.key, required this.child});

  static const _tabs = [
    '/home',
    '/workout/select',
    '/plans',
    '/history',
    '/chat',
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _tabs.length; i++) {
      if (location == _tabs[i]) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.divider)),
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          type: BottomNavigationBarType.fixed,
          onTap: (i) => context.go(_tabs[i]),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.videocam_outlined), label: 'Train'),
            BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), label: 'Plans'),
            BottomNavigationBarItem(icon: Icon(Icons.history_outlined), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), label: 'AI Chat'),
          ],
        ),
      ),
    );
  }
}
