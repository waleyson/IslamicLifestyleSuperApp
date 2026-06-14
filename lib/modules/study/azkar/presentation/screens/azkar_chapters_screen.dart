import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:islamic_super_app/modules/study/azkar/presentation/providers/azkar_provider.dart';
import 'package:islamic_super_app/modules/study/azkar/presentation/providers/azkar_schedule_provider.dart';

class AzkarChaptersScreen extends ConsumerWidget {
  final int categoryId;

  const AzkarChaptersScreen({super.key, required this.categoryId});

  Future<void> _scheduleChapter(
    BuildContext context,
    WidgetRef ref,
    int chapterId,
    String chapterName,
  ) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      barrierLabel: 'Select Auto-Play Time',
      helpText: 'Select Auto-Play Time for $chapterName',
    );

    if (pickedTime != null) {
      await ref.read(azkarScheduleProvider.notifier).addSchedule(
            chapterId,
            chapterName,
            pickedTime,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Scheduled auto-play for $chapterName at ${pickedTime.format(context)}',
            ),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.yellow,
              onPressed: () {
                GoRouter.of(context).push('/azkar_schedule');
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(azkarChaptersProvider(categoryId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Supplications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: chaptersAsync.when(
        data: (chapters) {
          if (chapters.isEmpty) {
            return const Center(child: Text('No supplications found in this category.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chapters.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final chapter = chapters[index];

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.star_outline_rounded, color: colorScheme.primary, size: 40),
                      Text(
                        "${index + 1}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    chapter.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notification_add_outlined),
                        color: const Color(0xFFD4AF37),
                        tooltip: 'Schedule Auto-Play',
                        onPressed: () => _scheduleChapter(context, ref, chapter.id, chapter.name),
                      ),
                      Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                    ],
                  ),
                  onTap: () {
                    GoRouter.of(context).push('/azkar_items/${chapter.id}');
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading chapters: $err')),
      ),
    );
  }
}
