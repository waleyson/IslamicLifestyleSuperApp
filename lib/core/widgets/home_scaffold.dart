import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:islamic_super_app/modules/general/reminder/presentation/providers/reminder_provider.dart';
import 'package:islamic_super_app/modules/study/azkar/presentation/providers/azkar_schedule_provider.dart';
import 'package:islamic_super_app/core/widgets/focus_mode_overlay.dart';

class HomeScaffold extends ConsumerWidget {
  final Widget child;
  final int currentIndex;
  final Function(int) onNavigate;

  const HomeScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the periodic reminder trigger check active
    ref.watch(reminderSchedulerProvider);
    
    // Keep the periodic Azkar schedule check active
    ref.watch(azkarScheduleProvider);

    return Scaffold(
      body: Stack(
        children: [
          child,
          const FocusModeOverlay(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onNavigate,
        indicatorColor:
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.25),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Quran',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_center_outlined),
            selectedIcon: Icon(Icons.business_center),
            label: 'Business',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Azkar',
          ),
        ],
      ),
    );
  }
}
