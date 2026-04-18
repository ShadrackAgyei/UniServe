import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/haptics_service.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  static const _tabs = [
    (icon: Icons.home_outlined,      activeIcon: Icons.home,             label: 'HOME'),
    (icon: Icons.report_problem_outlined, activeIcon: Icons.report_problem, label: 'ISSUES'),
    (icon: Icons.search_outlined,    activeIcon: Icons.search,           label: 'LOST'),
    (icon: Icons.person_outline,     activeIcon: Icons.person,           label: 'PROFILE'),
    (icon: Icons.school_outlined,    activeIcon: Icons.school,           label: 'CAMPUS'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _FloatingTabBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class _FloatingTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingTabBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    final navBg    = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0);
    final navBorder = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final inactiveColor = isDark ? const Color(0xFF666666) : const Color(0xFFAAAAAA);
    final activeBg = isDark ? Colors.white : Colors.black;
    final activeContent = isDark ? Colors.black : Colors.white;

    return Container(
      color: navBg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: navBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: navBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            padding: isActive
                                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                                : const EdgeInsets.all(10),
                            decoration: isActive
                                ? BoxDecoration(
                                    color: activeBg,
                                    borderRadius: BorderRadius.circular(20),
                                  )
                                : null,
                            child: isActive
                                ? FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(tab.activeIcon, size: 18, color: activeContent),
                                        const SizedBox(width: 6),
                                        Text(
                                          tab.label,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1.2,
                                            color: activeContent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Icon(tab.icon, size: 22, color: inactiveColor),
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
      ),
    );
  }
}
