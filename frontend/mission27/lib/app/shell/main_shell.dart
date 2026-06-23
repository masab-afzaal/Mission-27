import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  static final _scaffoldKey = GlobalKey<ScaffoldState>();

  const MainShell({super.key, required this.child});

  static void openSidebar() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return Scaffold(
      key: _scaffoldKey,
      drawer: _SideDrawer(currentLocation: location),
      body: child,
      bottomNavigationBar: _BottomNav(currentLocation: location),
    );
  }
}

// ── Sidebar drawer ────────────────────────────────────────────────────────────

class _SideDrawer extends StatelessWidget {
  final String currentLocation;
  const _SideDrawer({required this.currentLocation});

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(label: 'Dashboard',  icon: Icons.home_outlined,       activeIcon: Icons.home_rounded,       route: AppRoutes.dashboard),
      _NavItem(label: 'Goals',      icon: Icons.flag_outlined,       activeIcon: Icons.flag_rounded,       route: AppRoutes.goals),
      _NavItem(label: 'Focus',      icon: Icons.timer_outlined,      activeIcon: Icons.timer_rounded,      route: AppRoutes.pomodoro),
      _NavItem(label: 'Namaz',      icon: Icons.mosque_outlined,     activeIcon: Icons.mosque_rounded,     route: AppRoutes.namaz),
      _NavItem(label: 'AI Coach',   icon: Icons.psychology_outlined, activeIcon: Icons.psychology_rounded, route: AppRoutes.aiCoach),
    ];

    return Drawer(
      backgroundColor: AppColors.surface,
      width: 260,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Mission 27', style: AppTypography.titleLarge.copyWith(color: AppColors.primary)),
                const SizedBox(height: 2),
                Text('Personal Growth OS', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
              ]),
            ),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 8),
            ...items.map((item) {
              final isActive = currentLocation == item.route;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: ListTile(
                  leading: Icon(isActive ? item.activeIcon : item.icon,
                      color: isActive ? AppColors.primary : AppColors.textSecondary, size: 22),
                  title: Text(item.label, style: TextStyle(
                    color: isActive ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 15,
                  )),
                  selected: isActive,
                  selectedTileColor: AppColors.primary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  dense: true,
                  onTap: () {
                    Navigator.pop(context);
                    context.go(item.route);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Bottom nav ────────────────────────────────────────────────────────────────

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

class _BottomNav extends StatelessWidget {
  final String currentLocation;
  const _BottomNav({required this.currentLocation});

  static const _items = [
    _NavItem(label: 'Home',   icon: Icons.home_outlined,   activeIcon: Icons.home_rounded,   route: AppRoutes.dashboard),
    _NavItem(label: 'Goals',  icon: Icons.flag_outlined,   activeIcon: Icons.flag_rounded,   route: AppRoutes.goals),
    _NavItem(label: 'Focus',  icon: Icons.timer_outlined,  activeIcon: Icons.timer_rounded,  route: AppRoutes.pomodoro),
    _NavItem(label: 'Namaz',  icon: Icons.mosque_outlined, activeIcon: Icons.mosque_rounded, route: AppRoutes.namaz),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ..._items.map((item) {
                final isActive = currentLocation == item.route;
                return _NavTile(item: item, isActive: isActive);
              }),
              // Menu tile opens left sidebar
              GestureDetector(
                onTap: MainShell.openSidebar,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.menu_rounded, size: 22, color: AppColors.textTertiary),
                    const SizedBox(height: 2),
                    Text('More', style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary, fontSize: 10,
                    )),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;

  const _NavTile({super.key, required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(item.route),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              size: 22,
              color: isActive ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: AppTypography.labelSmall.copyWith(
                color: isActive ? AppColors.primary : AppColors.textTertiary,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
