import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:islamic_super_app/modules/general/reminder/data/models/reminder_model.dart';
import 'package:islamic_super_app/shared/services/notification_service.dart';
import 'package:islamic_super_app/shared/services/media_playback_service.dart';
import 'package:islamic_super_app/core/router/app_router.dart';

final reminderListProvider =
    AsyncNotifierProvider<ReminderNotifier, List<ReminderModel>>(
        ReminderNotifier.new);

class ReminderNotifier extends AsyncNotifier<List<ReminderModel>> {
  static const _boxName = 'reminders_box';

  @override
  FutureOr<List<ReminderModel>> build() async {
    final box = await Hive.openBox<ReminderModel>(_boxName);

    if (box.isEmpty) {
      final initialReminders = [
        ReminderModel(
          id: '1',
          title: 'Fajr Prayer',
          scheduledTime: DateTime.now().add(const Duration(hours: 4)),
        ),
        ReminderModel(
          id: '2',
          title: 'Read Surah Al-Kahf',
          scheduledTime: DateTime.now().add(const Duration(days: 1)),
        ),
      ];
      for (final r in initialReminders) {
        await box.put(r.id, r);
      }
    }

    return box.values.toList();
  }

  Future<void> addReminder(ReminderModel reminder) async {
    final box = await Hive.openBox<ReminderModel>(_boxName);
    await box.put(reminder.id, reminder);
    state = AsyncData(box.values.toList());
  }

  Future<void> toggleReminder(String id) async {
    final box = await Hive.openBox<ReminderModel>(_boxName);
    final r = box.get(id);
    if (r != null) {
      final updated = ReminderModel(
        id: r.id,
        title: r.title,
        scheduledTime: r.scheduledTime,
        isEnabled: !r.isEnabled,
        isQuranReminder: r.isQuranReminder,
        surahNumber: r.surahNumber,
        surahName: r.surahName,
        ayahNumber: r.ayahNumber,
        ayahText: r.ayahText,
        audioUrl: r.audioUrl,
      );
      await box.put(id, updated);
      state = AsyncData(box.values.toList());
    }
  }

  Future<void> deleteReminder(String id) async {
    final box = await Hive.openBox<ReminderModel>(_boxName);
    await box.delete(id);
    state = AsyncData(box.values.toList());
  }
}

// Foreground/Background Scheduler Provider
final reminderSchedulerProvider = Provider<void>((ref) {
  Timer? timer;

  void checkReminders() async {
    final remindersAsync = ref.read(reminderListProvider);
    final reminders = remindersAsync.value ?? [];
    final now = DateTime.now();

    for (final reminder in reminders) {
      if (reminder.isEnabled && reminder.scheduledTime.isBefore(now)) {
        // 1. Disable the reminder in DB so it doesn't trigger again
        await ref.read(reminderListProvider.notifier).toggleReminder(reminder.id);

        // 2. Show notification
        final notificationService = ref.read(notificationServiceProvider);
        notificationService.showNotification(
          id: reminder.id.hashCode,
          title: reminder.isQuranReminder
              ? 'Quran Verse: Surah ${reminder.surahName}'
              : reminder.title,
          body: reminder.isQuranReminder
              ? 'Ayah ${reminder.ayahNumber}: ${reminder.ayahText}'
              : 'It\'s time for your reminder!',
        );

        // 3. Play Quran verse if applicable, and show dialog
        if (reminder.isQuranReminder && reminder.audioUrl != null) {
          final mediaService = ref.read(mediaPlaybackServiceProvider);
          await mediaService.playAudioFromUrl(reminder.audioUrl!);

          final context = rootNavigatorKey.currentContext;
          if (context != null && context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => _QuranReminderDialog(reminder: reminder),
            );
          }
        }
      }
    }
  }

  // Check immediately upon init and then every 10 seconds
  Future.microtask(() => checkReminders());
  timer = Timer.periodic(const Duration(seconds: 10), (_) => checkReminders());

  ref.onDispose(() {
    timer?.cancel();
  });
});

class _QuranReminderDialog extends ConsumerWidget {
  final ReminderModel reminder;

  const _QuranReminderDialog({required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaService = ref.watch(mediaPlaybackServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.menu_book, color: colorScheme.primary, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Quran Verse Reminder',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Surah ${reminder.surahName} • Ayah ${reminder.ayahNumber}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            
            // Arabic Text Container
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    reminder.ayahText ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      height: 1.6,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Actions
            StreamBuilder<bool>(
              stream: mediaService.playingStream,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data ?? false;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (isPlaying) {
                          await mediaService.pause();
                        } else {
                          if (reminder.audioUrl != null) {
                            await mediaService.playAudioFromUrl(reminder.audioUrl!);
                          }
                        }
                      },
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      label: Text(isPlaying ? 'Pause' : 'Play'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondaryContainer,
                        foregroundColor: colorScheme.onSecondaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await mediaService.stop();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Dismiss'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
