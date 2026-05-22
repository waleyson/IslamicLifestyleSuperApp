import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'modules/general/reminder/data/models/reminder_model.dart';
import 'shared/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(ReminderModelAdapter());

  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.init();

  // TODO: Initialize Firebase once google-services.json is added
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ProviderScope(
      overrides: [
        // Pre-seed the notification service instance
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const IslamicSuperApp(),
    ),
  );
}

class IslamicSuperApp extends ConsumerWidget {
  const IslamicSuperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Islamic Lifestyle Super App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
