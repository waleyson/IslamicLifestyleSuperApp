import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';

import 'package:islamic_super_app/modules/general/reminder/data/models/reminder_model.dart';
import 'package:islamic_super_app/shared/services/notification_service.dart';
import 'package:islamic_super_app/shared/services/media_playback_service.dart';
import 'package:islamic_super_app/core/router/app_router.dart';
import 'package:islamic_super_app/modules/study/quran/presentation/providers/quran_list_provider.dart';

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

  Future<void> refreshReminders() async {
    final box = await Hive.openBox<ReminderModel>(_boxName);
    state = AsyncData(box.values.toList());
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
      final updated = r.copyWith(
        isEnabled: !r.isEnabled,
        clearSnoozeTime: true,
      );
      await box.put(id, updated);
      state = AsyncData(box.values.toList());
    }
  }

  Future<void> snoozeReminder(String id, DateTime snoozeTime) async {
    final box = await Hive.openBox<ReminderModel>(_boxName);
    final r = box.get(id);
    if (r != null) {
      final updated = r.copyWith(
        isEnabled: true,
        snoozeTime: snoozeTime,
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

/// Helper function to calculate the next recurrence scheduled time safely.
DateTime calculateNextScheduledTime(DateTime current, String recurrence) {
  DateTime next = current;
  final now = DateTime.now();
  do {
    switch (recurrence) {
      case 'hourly':
        next = next.add(const Duration(hours: 1));
        break;
      case 'daily':
        next = next.add(const Duration(days: 1));
        break;
      case 'weekly':
        next = next.add(const Duration(days: 7));
        break;
      case 'monthly':
        final year = next.month == 12 ? next.year + 1 : next.year;
        final month = next.month == 12 ? 1 : next.month + 1;
        int day = next.day;
        final daysInNextMonth = DateUtils.getDaysInMonth(year, month);
        if (day > daysInNextMonth) {
          day = daysInNextMonth;
        }
        next = DateTime(year, month, day, next.hour, next.minute, next.second, next.millisecond, next.microsecond);
        break;
      default:
        return next;
    }
  } while (next.isBefore(now));
  return next;
}

// Foreground/Background Scheduler Provider
final reminderSchedulerProvider = Provider<void>((ref) {
  Timer? timer;

  void checkReminders() async {
    final remindersAsync = ref.read(reminderListProvider);
    final reminders = remindersAsync.value ?? [];
    final now = DateTime.now();

    for (final reminder in reminders) {
      if (reminder.isEnabled) {
        final isSnoozed = reminder.snoozeTime != null;
        final triggerTime = isSnoozed ? reminder.snoozeTime! : reminder.scheduledTime;

        if (triggerTime.isBefore(now)) {
          // 1. Shift scheduledTime or disable, and clear snoozeTime
          final box = await Hive.openBox<ReminderModel>('reminders_box');
          final r = box.get(reminder.id);
          if (r != null) {
            final isSnoozeTrigger = r.snoozeTime != null;
            ReminderModel updated;
            if (isSnoozeTrigger) {
              if (r.recurrence == 'once') {
                updated = r.copyWith(
                  isEnabled: false,
                  clearSnoozeTime: true,
                );
              } else {
                updated = r.copyWith(
                  clearSnoozeTime: true,
                );
              }
            } else {
              if (r.recurrence == 'once') {
                updated = r.copyWith(
                  isEnabled: false,
                  clearSnoozeTime: true,
                );
              } else {
                final nextTime = calculateNextScheduledTime(r.scheduledTime, r.recurrence);
                updated = r.copyWith(
                  scheduledTime: nextTime,
                  clearSnoozeTime: true,
                );
              }
            }
            await box.put(r.id, updated);
            await ref.read(reminderListProvider.notifier).refreshReminders();
          }

          // 2. Show notification
          final notificationService = ref.read(notificationServiceProvider);
          notificationService.showNotification(
            id: reminder.id.hashCode,
            title: reminder.isQuranReminder
                ? 'Quran Verse: Surah ${reminder.surahName}'
                : reminder.title,
            body: reminder.isQuranReminder
                ? (reminder.endAyahNumber != null && reminder.endAyahNumber! > reminder.ayahNumber!
                    ? 'Ayahs ${reminder.ayahNumber}-${reminder.endAyahNumber}: ${reminder.ayahText}'
                    : 'Ayah ${reminder.ayahNumber}: ${reminder.ayahText}')
                : 'It\'s time for your reminder!',
          );

          // 3. Play Quran verse if applicable, and show dialog
          if (reminder.isQuranReminder) {
            final context = rootNavigatorKey.currentContext;
            if (context != null && context.mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => _QuranReminderDialog(reminder: reminder),
              );
            } else if (reminder.audioUrl != null) {
              final mediaService = ref.read(mediaPlaybackServiceProvider);
              await mediaService.playAudioFromUrl(reminder.audioUrl!);
            }
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

class _QuranReminderDialog extends ConsumerStatefulWidget {
  final ReminderModel reminder;

  const _QuranReminderDialog({required this.reminder});

  @override
  ConsumerState<_QuranReminderDialog> createState() => _QuranReminderDialogState();
}

class _QuranReminderDialogState extends ConsumerState<_QuranReminderDialog> {
  late int _currentAyah;
  late String _currentText;
  String? _currentAudioUrl;
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _currentAyah = widget.reminder.ayahNumber ?? 1;
    _currentText = widget.reminder.ayahText ?? '';
    _currentAudioUrl = widget.reminder.audioUrl;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playCurrent();
      _listenToPlayback();
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    super.dispose();
  }

  void _listenToPlayback() {
    final mediaService = ref.read(mediaPlaybackServiceProvider);
    _playerStateSubscription = mediaService.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onAudioCompleted();
      }
    });
  }

  Future<void> _playCurrent() async {
    if (_currentAudioUrl == null) return;
    try {
      final mediaService = ref.read(mediaPlaybackServiceProvider);
      await mediaService.playAudioFromUrl(_currentAudioUrl!);
    } catch (e) {
      debugPrint("Playback error: $e");
    }
  }

  Future<void> _fetchAndPlayNext(int nextAyah) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(quranRepositoryProvider);
      final data = await repo.fetchAyah(widget.reminder.surahNumber!, nextAyah);
      if (mounted) {
        setState(() {
          _currentAyah = nextAyah;
          _currentText = data['text'] as String? ?? '';
          _currentAudioUrl = data['audio'] as String?;
          _isLoading = false;
        });
        await _playCurrent();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "Failed to load next verse. Tap retry or skip.";
        });
      }
    }
  }

  void _onAudioCompleted() {
    final endAyah = widget.reminder.endAyahNumber ?? widget.reminder.ayahNumber ?? 1;
    if (_currentAyah < endAyah) {
      _fetchAndPlayNext(_currentAyah + 1);
    } else {
      ref.read(mediaPlaybackServiceProvider).stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaService = ref.watch(mediaPlaybackServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final hasRange = widget.reminder.endAyahNumber != null &&
        widget.reminder.endAyahNumber! > (widget.reminder.ayahNumber ?? 1);

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
              hasRange
                  ? 'Surah ${widget.reminder.surahName} • Ayah $_currentAyah (Range: ${widget.reminder.ayahNumber}-${widget.reminder.endAyahNumber})'
                  : 'Surah ${widget.reminder.surahName} • Ayah $_currentAyah',
              textAlign: TextAlign.center,
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
                  child: _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Column(
                          children: [
                            Text(
                              _currentText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                height: 1.6,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Amiri',
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: TextStyle(color: colorScheme.error, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                              TextButton(
                                onPressed: () => _fetchAndPlayNext(_currentAyah),
                                child: const Text('Retry'),
                              ),
                            ],
                          ],
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
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  if (isPlaying) {
                                    await mediaService.pause();
                                  } else {
                                    if (_currentAudioUrl != null) {
                                      await mediaService.playAudioFromUrl(_currentAudioUrl!);
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
                        // Snooze Button
                        ElevatedButton.icon(
                          onPressed: () async {
                            await mediaService.stop();
                            // Snooze for 5 minutes
                            final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
                            await ref.read(reminderListProvider.notifier).snoozeReminder(
                                  widget.reminder.id,
                                  snoozeTime,
                                );
                            if (context.mounted) Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.snooze),
                          label: const Text('Snooze (5m)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            foregroundColor: colorScheme.onSurfaceVariant,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: colorScheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (hasRange && _currentAyah < widget.reminder.endAyahNumber!)
                          TextButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () => _fetchAndPlayNext(_currentAyah + 1),
                            icon: const Icon(Icons.skip_next),
                            label: const Text('Skip Verse'),
                          ),
                        ElevatedButton(
                          onPressed: () async {
                            await mediaService.stop();
                            if (context.mounted) Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            minimumSize: const Size(120, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Dismiss'),
                        ),
                      ],
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

