import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../state/settings_controller.dart';
import '../collections/collections_page.dart';
import '../favorites/favorites_page.dart';
import '../history/history_page.dart';
import '../home/home_page.dart';
import '../parent/parent_tab_page.dart';
import '../widgets/app_background.dart';

/// Доступ к переключению вкладок из любого экрана.
class AppShellScope extends InheritedWidget {
  const AppShellScope({
    super.key,
    required this.openParents,
    required this.openTab,
    required super.child,
  });

  /// Открыть вкладку «Родителям».
  final VoidCallback openParents;

  /// Открыть вкладку по индексу.
  final ValueChanged<int> openTab;

  static AppShellScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppShellScope>();

  @override
  bool updateShouldNotify(AppShellScope oldWidget) => false;
}

/// Основной каркас: контент плюс «плавающее» нижнее меню.
///
/// Разделы «Избранное» и «История» можно спрятать в настройках для
/// родителей — тогда меню становится короче и проще для малыша.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static AppShellScope? of(BuildContext context) => AppShellScope.of(context);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _goTo(int index) {
    if (!mounted) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final settings = context.watch<SettingsController>().settings;

    final tabs = <_Tab>[
      _Tab(
        icon: Icons.home_rounded,
        label: strings.navHome,
        page: const HomePage(),
      ),
      _Tab(
        icon: Icons.grid_view_rounded,
        label: strings.navCollections,
        page: const CollectionsPage(),
      ),
      if (settings.showFavorites)
        _Tab(
          icon: Icons.favorite_rounded,
          label: strings.navFavorites,
          page: const FavoritesPage(),
        ),
      if (settings.showHistory)
        _Tab(
          icon: Icons.history_rounded,
          label: strings.navHistory,
          page: const HistoryPage(),
        ),
      _Tab(
        icon: Icons.lock_rounded,
        label: strings.navParents,
        page: const ParentTabPage(),
      ),
    ];

    final index = _index.clamp(0, tabs.length - 1);
    final parentsIndex = tabs.length - 1;

    return AppShellScope(
      openParents: () => _goTo(parentsIndex),
      openTab: _goTo,
      child: Scaffold(
        extendBody: true,
        body: AppBackground(
          child: IndexedStack(
            index: index,
            children: [for (final tab in tabs) tab.page],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: NavigationBar(
                selectedIndex: index,
                onDestinationSelected: _goTo,
                destinations: [
                  for (final tab in tabs)
                    NavigationDestination(
                      icon: Icon(tab.icon),
                      label: tab.label,
                      tooltip: tab.label,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  const _Tab({required this.icon, required this.label, required this.page});

  final IconData icon;
  final String label;
  final Widget page;
}

/// Отступ снизу, чтобы контент не прятался за плавающим меню.
const double kShellBottomInset = 110;
