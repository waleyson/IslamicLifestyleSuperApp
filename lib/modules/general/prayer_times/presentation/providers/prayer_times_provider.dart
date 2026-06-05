import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/prayer_times_model.dart';
import '../../data/repositories/prayer_times_repository.dart';

final prayerTimesRepositoryProvider = Provider<PrayerTimesRepository>((ref) {
  return PrayerTimesRepository();
});

final prayerTimesProvider =
    AsyncNotifierProvider<PrayerTimesNotifier, PrayerTimesModel>(
  PrayerTimesNotifier.new,
);

class PrayerTimesNotifier extends AsyncNotifier<PrayerTimesModel> {
  static const _boxName = 'prayer_times_box';
  static const _cacheKey = 'current_prayer_times';

  @override
  FutureOr<PrayerTimesModel> build() async {
    final box = await Hive.openBox(_boxName);
    final cached = box.get(_cacheKey);

    if (cached != null) {
      try {
        final map = Map<String, dynamic>.from(cached as Map);
        return PrayerTimesModel.fromJson(map);
      } catch (e) {
        // Cache corrupted or format changed, proceed to fetch
      }
    }

    return _fetchAndSave(box);
  }

  Future<PrayerTimesModel> _fetchAndSave(Box box) async {
    try {
      final repo = ref.read(prayerTimesRepositoryProvider);
      final model = await repo.fetchPrayerTimesByIp();
      await box.put(_cacheKey, model.toJson());
      return model;
    } catch (e) {
      // Offline fallback: return default location
      return PrayerTimesModel.defaultLocation();
    }
  }

  Future<void> refreshTimes() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(prayerTimesRepositoryProvider);
      final model = await repo.fetchPrayerTimesByIp();
      final box = await Hive.openBox(_boxName);
      await box.put(_cacheKey, model.toJson());
      state = AsyncValue.data(model);
    } catch (e, stack) {
      // Try to load cached if refresh fails, otherwise keep old data or default location
      final box = await Hive.openBox(_boxName);
      final cached = box.get(_cacheKey);
      if (cached != null) {
        final map = Map<String, dynamic>.from(cached as Map);
        state = AsyncValue.data(PrayerTimesModel.fromJson(map));
      } else {
        state = AsyncValue.error(e, stack);
      }
    }
  }
}

/// Periodic stream provider ticking every second to update countdowns smoothly
final timerStreamProvider = StreamProvider<DateTime>((ref) {
  final controller = StreamController<DateTime>();
  final timer = Timer.periodic(const Duration(seconds: 1), (_) {
    if (!controller.isClosed) {
      controller.add(DateTime.now());
    }
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

class PrayerMilestone {
  final String name;
  final DateTime dateTime;
  final bool isFardPrayer;

  PrayerMilestone(this.name, this.dateTime, {this.isFardPrayer = true});
}

class PrayerStateInfo {
  final String currentMilestone;
  final String nextMilestone;
  final DateTime nextMilestoneTime;
  final Duration timeRemaining;
  final double progress;
  final Map<String, DateTime> todayPrayerTimes;

  PrayerStateInfo({
    required this.currentMilestone,
    required this.nextMilestone,
    required this.nextMilestoneTime,
    required this.timeRemaining,
    required this.progress,
    required this.todayPrayerTimes,
  });
}

/// Calculate current active prayer, next prayer milestone, countdown and progress using adhan local calculation
PrayerStateInfo getPrayerStateInfo(PrayerTimesModel model, DateTime now) {
  final today = now;
  final yesterday = today.subtract(const Duration(days: 1));
  final tomorrow = today.add(const Duration(days: 1));

  // Compute local prayer times for the three days
  final yt = model.getPrayerTimesForDate(yesterday);
  final tt = model.getPrayerTimesForDate(today);
  final tmt = model.getPrayerTimesForDate(tomorrow);

  final milestones = [
    // Yesterday's Isha
    PrayerMilestone('Isha', yt.isha),
    // Today's milestones
    PrayerMilestone('Fajr', tt.fajr),
    PrayerMilestone('Sunrise', tt.sunrise, isFardPrayer: false),
    PrayerMilestone('Dhuhr', tt.dhuhr),
    PrayerMilestone('Asr', tt.asr),
    PrayerMilestone('Maghrib', tt.maghrib),
    PrayerMilestone('Isha', tt.isha),
    // Tomorrow's Fajr
    PrayerMilestone('Fajr', tmt.fajr),
  ];

  // Find the first milestone that is after 'now'
  int nextIdx = -1;
  for (int i = 0; i < milestones.length; i++) {
    if (milestones[i].dateTime.isAfter(now)) {
      nextIdx = i;
      break;
    }
  }

  if (nextIdx == -1) {
    nextIdx = milestones.length - 1;
  }

  final nextMilestone = milestones[nextIdx];
  final currentMilestone = milestones[nextIdx - 1];

  final totalDuration = nextMilestone.dateTime.difference(currentMilestone.dateTime).inSeconds;
  final elapsed = now.difference(currentMilestone.dateTime).inSeconds;
  final progress = (totalDuration > 0) ? (elapsed / totalDuration).clamp(0.0, 1.0) : 0.0;

  final todayPrayerTimes = {
    'Fajr': tt.fajr,
    'Sunrise': tt.sunrise,
    'Dhuhr': tt.dhuhr,
    'Asr': tt.asr,
    'Maghrib': tt.maghrib,
    'Isha': tt.isha,
  };

  return PrayerStateInfo(
    currentMilestone: currentMilestone.name,
    nextMilestone: nextMilestone.name,
    nextMilestoneTime: nextMilestone.dateTime,
    timeRemaining: nextMilestone.dateTime.difference(now),
    progress: progress,
    todayPrayerTimes: todayPrayerTimes,
  );
}
