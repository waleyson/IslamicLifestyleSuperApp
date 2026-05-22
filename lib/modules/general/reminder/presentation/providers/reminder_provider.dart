import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/reminder_model.dart';

final reminderListProvider = AsyncNotifierProvider<ReminderNotifier, List<ReminderModel>>(ReminderNotifier.new);

class ReminderNotifier extends AsyncNotifier<List<ReminderModel>> {
  @override
  FutureOr<List<ReminderModel>> build() async {
    // Mocking fetch from storage for sample purposes
    return [
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
  }

  Future<void> addReminder(ReminderModel reminder) async {
    final currentList = state.value ?? [];
    state = AsyncData([...currentList, reminder]);
  }
  
  Future<void> toggleReminder(String id) async {
    final currentList = state.value ?? [];
    final updatedList = currentList.map((r) {
      if (r.id == id) {
        return ReminderModel(
          id: r.id, 
          title: r.title, 
          scheduledTime: r.scheduledTime, 
          isEnabled: !r.isEnabled
        );
      }
      return r;
    }).toList();
    state = AsyncData(updatedList);
  }
}
