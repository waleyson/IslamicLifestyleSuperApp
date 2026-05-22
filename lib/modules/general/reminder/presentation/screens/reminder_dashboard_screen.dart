import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/reminder_provider.dart';
import '../../../../shared/services/media_playback_service.dart';

class ReminderDashboardScreen extends ConsumerWidget {
  const ReminderDashboardScreen({super.key});

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$hour:$minute  •  $day/$month/${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderState = ref.watch(reminderListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Islamic Reminders')),
      body: reminderState.when(
        data: (reminders) {
          if (reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 64, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No reminders set.',
                    style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return Dismissible(
                key: Key(reminder.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  ref.read(reminderListProvider.notifier).deleteReminder(reminder.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${reminder.title}" deleted'),
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          ref.read(reminderListProvider.notifier).addReminder(reminder);
                        },
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: reminder.isQuranReminder
                              ? colorScheme.primary.withValues(alpha: 0.1)
                              : colorScheme.secondary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          reminder.isQuranReminder
                              ? Icons.menu_book
                              : Icons.notifications_active_outlined,
                          color: reminder.isQuranReminder
                              ? colorScheme.primary
                              : colorScheme.secondary,
                        ),
                      ),
                      title: Text(
                        reminder.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            _formatDateTime(reminder.scheduledTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                          if (reminder.isQuranReminder && reminder.ayahText != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              reminder.ayahText!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: colorScheme.primary.withValues(alpha: 0.8),
                                fontFamily: 'Amiri',
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (reminder.isQuranReminder && reminder.audioUrl != null)
                            StreamBuilder<bool>(
                              stream: ref.watch(mediaPlaybackServiceProvider).playingStream,
                              builder: (context, snapshot) {
                                final isPlaying = snapshot.data ?? false;
                                return IconButton(
                                  icon: Icon(
                                    isPlaying ? Icons.stop_circle : Icons.play_circle_filled,
                                    size: 32,
                                  ),
                                  color: colorScheme.primary,
                                  onPressed: () async {
                                    final mediaService = ref.read(mediaPlaybackServiceProvider);
                                    if (isPlaying) {
                                      await mediaService.stop();
                                    } else {
                                      await mediaService.playAudioFromUrl(reminder.audioUrl!);
                                    }
                                  },
                                );
                              },
                            ),
                          const SizedBox(width: 4),
                          Switch(
                            value: reminder.isEnabled,
                            onChanged: (val) {
                              ref.read(reminderListProvider.notifier).toggleReminder(reminder.id);
                            },
                            activeThumbColor: colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
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
