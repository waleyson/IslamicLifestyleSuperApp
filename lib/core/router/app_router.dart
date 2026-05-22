import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/home_scaffold.dart';
import '../../modules/general/reminder/presentation/screens/reminder_dashboard_screen.dart';
import '../../modules/general/reminder/presentation/screens/create_reminder_screen.dart';
import '../../modules/study/quran/presentation/screens/quran_home_screen.dart';
import '../../modules/study/quran/presentation/screens/quran_audio_player_screen.dart';
import '../../modules/business/presentation/screens/business_dashboard_screen.dart';

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
        path: '/create_reminder',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreateReminderScreen(),
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
        ],
      ),
    ],
  );
});
