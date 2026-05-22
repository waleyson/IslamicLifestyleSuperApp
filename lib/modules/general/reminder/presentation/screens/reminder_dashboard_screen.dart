import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/reminder_provider.dart';

class ReminderDashboardScreen extends ConsumerWidget {
  const ReminderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderState = ref.watch(reminderListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders (General)')),
      body: reminderState.when(
        data: (reminders) {
          if (reminders.isEmpty) {
            return const Center(child: Text('No reminders set.'));
          }
          return ListView.builder(
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(reminder.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(reminder.scheduledTime.toString()),
                  trailing: Switch(
                    value: reminder.isEnabled,
                    onChanged: (val) {
                      ref.read(reminderListProvider.notifier).toggleReminder(reminder.id);
                    },
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create_reminder'),
        icon: const Icon(Icons.add_alarm),
        label: const Text('New Reminder'),
      ),
    );
  }
}
