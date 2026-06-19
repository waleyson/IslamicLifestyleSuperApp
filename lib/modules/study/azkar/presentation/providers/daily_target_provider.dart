import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:islamic_super_app/shared/services/native_blocker_service.dart';

class DailyTargetState {
  final int quranPagesRead;
  final int quranPagesTarget;
  final int azkarCompletedCount;
  final int azkarTarget;
  final String lastCheckedDate;

  DailyTargetState({
    required this.quranPagesRead,
    required this.quranPagesTarget,
    required this.azkarCompletedCount,
    required this.azkarTarget,
    required this.lastCheckedDate,
  });

  /// Check if both the Quran pages and Azkar targets have been met.
  bool get isTargetMet =>
      quranPagesRead >= quranPagesTarget && azkarCompletedCount >= azkarTarget;

  DailyTargetState copyWith({
    int? quranPagesRead,
    int? quranPagesTarget,
    int? azkarCompletedCount,
    int? azkarTarget,
    String? lastCheckedDate,
  }) {
    return DailyTargetState(
      quranPagesRead: quranPagesRead ?? this.quranPagesRead,
      quranPagesTarget: quranPagesTarget ?? this.quranPagesTarget,
      azkarCompletedCount: azkarCompletedCount ?? this.azkarCompletedCount,
      azkarTarget: azkarTarget ?? this.azkarTarget,
      lastCheckedDate: lastCheckedDate ?? this.lastCheckedDate,
    );
  }
}

final dailyTargetProvider =
    NotifierProvider<DailyTargetNotifier, DailyTargetState>(
  DailyTargetNotifier.new,
);

class DailyTargetNotifier extends Notifier<DailyTargetState> {
  static const _boxName = 'daily_targets_box';
  Timer? _timer;

  @override
  DailyTargetState build() {
    final box = Hive.box(_boxName);
    
    final today = _getTodayString();
    final lastDate = box.get('lastCheckedDate', defaultValue: today) as String;

    int quranRead = box.get('quranPagesRead', defaultValue: 0) as int;
    int azkarRead = box.get('azkarCompletedCount', defaultValue: 0) as int;
    final quranTarget = box.get('quranPagesTarget', defaultValue: 5) as int;
    final azkarTarget = box.get('azkarTarget', defaultValue: 1) as int;

    // Reset daily targets at midnight/new day
    if (lastDate != today) {
      quranRead = 0;
      azkarRead = 0;
      box.put('quranPagesRead', 0);
      box.put('azkarCompletedCount', 0);
      box.put('lastCheckedDate', today);
    }

    final stateObj = DailyTargetState(
      quranPagesRead: quranRead,
      quranPagesTarget: quranTarget,
      azkarCompletedCount: azkarRead,
      azkarTarget: azkarTarget,
      lastCheckedDate: today,
    );

    // Sync screen blocker to native OS level
    Future.microtask(() => _syncNativeBlockState(stateObj.isTargetMet));

    _startResetTimer();

    return stateObj;
  }

  void _startResetTimer() {
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => checkAndResetIfNewDay());
    ref.onDispose(() {
      _timer?.cancel();
    });
  }

  void checkAndResetIfNewDay() {
    final today = _getTodayString();
    if (state.lastCheckedDate != today) {
      final box = Hive.box(_boxName);
      box.put('quranPagesRead', 0);
      box.put('azkarCompletedCount', 0);
      box.put('lastCheckedDate', today);

      state = state.copyWith(
        quranPagesRead: 0,
        azkarCompletedCount: 0,
        lastCheckedDate: today,
      );
      _syncNativeBlockState(state.isTargetMet);
    }
  }

  String _getTodayString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  /// Activates or deactivates OS-level social media block based on target status
  Future<void> _syncNativeBlockState(bool isTargetMet) async {
    final blockerService = ref.read(nativeBlockerServiceProvider);
    // If targets are met, release lock (isLocked = false); else enable lock (isLocked = true).
    await blockerService.setBlockState(!isTargetMet);
  }

  /// Increments pages read in Quran and syncs block status
  Future<void> incrementQuranPages(int pages) async {
    checkAndResetIfNewDay();
    final box = Hive.box(_boxName);
    final newRead = state.quranPagesRead + pages;
    await box.put('quranPagesRead', newRead);
    
    state = state.copyWith(quranPagesRead: newRead);
    await _syncNativeBlockState(state.isTargetMet);
  }

  /// Increments completed Azkar sessions and syncs block status
  Future<void> incrementAzkar() async {
    checkAndResetIfNewDay();
    final box = Hive.box(_boxName);
    final newAzkar = state.azkarCompletedCount + 1;
    await box.put('azkarCompletedCount', newAzkar);
    
    state = state.copyWith(azkarCompletedCount: newAzkar);
    await _syncNativeBlockState(state.isTargetMet);
  }

  /// Updates target configurations
  Future<void> updateTargets({required int quranTarget, required int azkarTarget}) async {
    checkAndResetIfNewDay();
    final box = Hive.box(_boxName);
    await box.put('quranPagesTarget', quranTarget);
    await box.put('azkarTarget', azkarTarget);

    state = state.copyWith(
      quranPagesTarget: quranTarget,
      azkarTarget: azkarTarget,
    );
    await _syncNativeBlockState(state.isTargetMet);
  }
}
