import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:islamic_super_app/modules/study/azkar/data/models/azkar_schedule_model.dart';
import 'package:islamic_super_app/shared/services/notification_service.dart';
import 'package:islamic_super_app/shared/services/media_playback_service.dart';
import 'package:islamic_super_app/core/router/app_router.dart';

final azkarScheduleProvider =
    NotifierProvider<AzkarScheduleNotifier, List<AzkarScheduleModel>>(
  AzkarScheduleNotifier.new,
);

class AzkarScheduleNotifier extends Notifier<List<AzkarScheduleModel>> {
  static const _boxName = 'azkar_schedules_box';

  @override
  List<AzkarScheduleModel> build() {
    final box = Hive.box<AzkarScheduleModel>(_boxName);
    
    // Start background check loop for schedules
    _startSchedulerTimer();

    return box.values.toList();
  }

  /// Adds a new Azkar schedule.
  Future<void> addSchedule(int chapterId, String chapterName, TimeOfDay time) async {
    final box = Hive.box<AzkarScheduleModel>(_boxName);
    
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newSchedule = AzkarScheduleModel(
      id: id,
      chapterId: chapterId,
      chapterName: chapterName,
      hour: time.hour,
      minute: time.minute,
      isEnabled: true,
      notificationId: id.hashCode,
    );

    await box.put(id, newSchedule);
    state = box.values.toList();
  }

  /// Toggles schedule enabled status.
  Future<void> toggleSchedule(String id) async {
    final box = Hive.box<AzkarScheduleModel>(_boxName);
    final schedule = box.get(id);
    if (schedule != null) {
      final updated = schedule.copyWith(isEnabled: !schedule.isEnabled);
      await box.put(id, updated);
      state = box.values.toList();
    }
  }

  /// Deletes a schedule.
  Future<void> deleteSchedule(String id) async {
    final box = Hive.box<AzkarScheduleModel>(_boxName);
    await box.delete(id);
    state = box.values.toList();
  }

  Timer? _timer;
  final Set<String> _triggeredTimesToday = {};
  String _lastTriggerDate = "";

  void _startSchedulerTimer() {
    Future.microtask(() => _checkSchedules());
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _checkSchedules());

    ref.onDispose(() {
      _timer?.cancel();
    });
  }

  void _checkSchedules() async {
    final now = DateTime.now();
    final todayString = "${now.year}-${now.month}-${now.day}";

    // Clear triggered log at midnight
    if (_lastTriggerDate != todayString) {
      _triggeredTimesToday.clear();
      _lastTriggerDate = todayString;
    }

    final currentHour = now.hour;
    final currentMinute = now.minute;

    for (final schedule in state) {
      if (schedule.isEnabled) {
        final triggerKey = "${schedule.id}_${currentHour}_$currentMinute";

        if (schedule.hour == currentHour &&
            schedule.minute == currentMinute &&
            !_triggeredTimesToday.contains(triggerKey)) {
          
          _triggeredTimesToday.add(triggerKey);

          // 1. Show notification
          final notificationService = ref.read(notificationServiceProvider);
          notificationService.showNotification(
            id: schedule.notificationId,
            title: "Time for Azkar",
            body: "It's time to recite: ${schedule.chapterName}",
          );

          // 2. Play beautiful audio
          final mediaService = ref.read(mediaPlaybackServiceProvider);
          // Stream beautiful morning Azkar recitation as default
          const String azkarAudioUrl = "https://server8.mp3quran.net/afs/001.mp3"; 
          await mediaService.playAudioFromUrl(azkarAudioUrl);

          // 3. Show dialog if app is in foreground
          final context = rootNavigatorKey.currentContext;
          if (context != null && context.mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
                    const SizedBox(width: 10),
                    const Expanded(child: Text("Scheduled Azkar")),
                  ],
                ),
                content: Text("It is time for your scheduled Azkar:\n\n${schedule.chapterName}\n\nRecitation is playing."),
                actions: [
                  TextButton(
                    onPressed: () {
                      mediaService.stop();
                      Navigator.pop(ctx);
                    },
                    child: const Text("Stop Audio"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      GoRouter.of(context).push('/azkar_items/${schedule.chapterId}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Open Recitation"),
                  ),
                ],
              ),
            );
          }
        }
      }
    }
  }
}
