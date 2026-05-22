import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:islamic_super_app/modules/general/reminder/presentation/providers/reminder_provider.dart';

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

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onNavigate,
        indicatorColor:
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.25),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.notifications_none_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Reminders',
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
        ],
      ),
    );
  }
}
