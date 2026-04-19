import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/haptics_service.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  static const _tabs = [
    (icon: Icons.home_outlined,           activeIcon: Icons.home,             label: 'Home'),
    (icon: Icons.report_problem_outlined, activeIcon: Icons.report_problem,   label: 'Issues'),
    (icon: Icons.search_outlined,         activeIcon: Icons.search,           label: 'Lost'),
    (icon: Icons.school_outlined,         activeIcon: Icons.school,           label: 'Campus'),
    (icon: Icons.person_outline,          activeIcon: Icons.person,           label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _SimpleTabBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class _SimpleTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _SimpleTabBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final navBg     = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0);
    final navBorder = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final activeColor   = isDark ? Colors.white : Colors.black;
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.30)
        : Colors.black.withValues(alpha: 0.25);

    return Container(
      decoration: BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: navBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(AppShell._tabs.length, (i) {
              final tab = AppShell._tabs[i];
              final isActive = i == currentIndex;

              return Expanded(
                child: Semantics(
                  button: true,
                  selected: isActive,
                  label: '${tab.label} tab',
                  child: Tooltip(
                    message: tab.label,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          if (i == currentIndex) return;
                          await HapticsService.selection(context);
                          onTap(i);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isActive ? tab.activeIcon : tab.icon,
                              size: 22,
                              color: isActive ? activeColor : inactiveColor,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tab.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                                letterSpacing: 0.5,
                                color: isActive ? activeColor : inactiveColor,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? const Color(0xFFB0311E)
                                    : Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
