import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/home_scaffold.dart';
import '../../modules/general/reminder/presentation/screens/reminder_dashboard_screen.dart';
import '../../modules/general/reminder/presentation/screens/create_reminder_screen.dart';
import '../../modules/general/reminder/presentation/screens/all_reminders_screen.dart';
import '../../modules/study/quran/presentation/screens/quran_home_screen.dart';
import '../../modules/study/quran/presentation/screens/quran_audio_player_screen.dart';
import '../../modules/study/quran/presentation/screens/quran_downloads_screen.dart';
import '../../modules/business/presentation/screens/business_dashboard_screen.dart';

// Azkar screen imports
import '../../modules/study/azkar/presentation/screens/azkar_home_screen.dart';
import '../../modules/study/azkar/presentation/screens/azkar_chapters_screen.dart';
import '../../modules/study/azkar/presentation/screens/azkar_items_screen.dart';
import '../../modules/study/azkar/presentation/screens/azkar_schedule_screen.dart';
import '../../modules/study/azkar/presentation/screens/daily_target_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/general',
    routes: [
      // Full-screen routes (outside shell)
      GoRoute(
        path: '/quran_player',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const QuranAudioPlayerScreen(),
      ),
      GoRoute(
        path: '/quran_downloads',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const QuranDownloadsScreen(),
      ),
      GoRoute(
        path: '/create_reminder',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreateReminderScreen(),
      ),
      GoRoute(
        path: '/all_reminders',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AllRemindersScreen(),
      ),
      GoRoute(
        path: '/azkar_chapters/:categoryId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final idStr = state.pathParameters['categoryId'] ?? '0';
          final id = int.tryParse(idStr) ?? 0;
          return AzkarChaptersScreen(categoryId: id);
        },
      ),
      GoRoute(
        path: '/azkar_items/:chapterId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final idStr = state.pathParameters['chapterId'] ?? '0';
          final id = int.tryParse(idStr) ?? 0;
          return AzkarItemsScreen(chapterId: id);
        },
      ),
      GoRoute(
        path: '/azkar_schedule',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AzkarScheduleScreen(),
      ),
      GoRoute(
        path: '/daily_target',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const DailyTargetScreen(),
      ),

      // Bottom-nav shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeScaffold(
            currentIndex: navigationShell.currentIndex,
            onNavigate: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            child: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/general',
                builder: (context, state) => const ReminderDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/study',
                builder: (context, state) => const QuranHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/business',
                builder: (context, state) => const BusinessDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/azkar',
                builder: (context, state) => const AzkarHomeScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
