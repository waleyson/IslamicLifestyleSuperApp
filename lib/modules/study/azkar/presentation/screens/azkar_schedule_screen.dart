import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';
import 'package:islamic_super_app/modules/study/azkar/presentation/providers/azkar_provider.dart';
import 'package:islamic_super_app/modules/study/azkar/presentation/providers/azkar_schedule_provider.dart';

class AzkarScheduleScreen extends ConsumerStatefulWidget {
  const AzkarScheduleScreen({super.key});

  @override
  ConsumerState<AzkarScheduleScreen> createState() => _AzkarScheduleScreenState();
}

class _AzkarScheduleScreenState extends ConsumerState<AzkarScheduleScreen> {
  List<AzkarChapter> _allChapters = [];
  bool _loadingChapters = false;

  @override
  void initState() {
    super.initState();
    _loadAllChapters();
  }

  Future<void> _loadAllChapters() async {
    setState(() {
      _loadingChapters = true;
    });
    try {
      final repo = ref.read(azkarRepositoryProvider);
      final chapters = await repo.fetchChapters(-1); // Fetches all chapters
      setState(() {
        _allChapters = chapters;
        _loadingChapters = false;
      });
    } catch (e) {
      setState(() {
        _loadingChapters = false;
      });
    }
  }

  String _formatTime(int hour, int minute) {
    final TimeOfDay tod = TimeOfDay(hour: hour, minute: minute);
    final context = this.context;
    if (mounted) {
      return tod.format(context);
    }
    return "$hour:${minute.toString().padLeft(2, '0')}";
  }

  void _showAddScheduleBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return _AddScheduleBottomSheet(
          chapters: _allChapters,
          loading: _loadingChapters,
          onChapterSelected: (chapter, time) async {
            await ref.read(azkarScheduleProvider.notifier).addSchedule(
                  chapter.id,
                  chapter.name,
                  time,
                );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedules = ref.watch(azkarScheduleProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Azkar Auto-Play Schedules',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: schedules.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.alarm_off_rounded,
                      size: 64,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "No Schedules Found",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Schedule auto-plays for your favorite supplications to automatically trigger background recitations and alerts.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showAddScheduleBottomSheet,
                      icon: const Icon(Icons.add),
                      label: const Text("Create Schedule"),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: schedules.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final schedule = schedules[index];

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Clock time display
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.access_time_filled_rounded,
                            color: colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatTime(schedule.hour, schedule.minute),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                schedule.chapterName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Action switches
                        Switch.adaptive(
                          value: schedule.isEnabled,
                          activeThumbColor: colorScheme.primary,
                          onChanged: (val) {
                            ref.read(azkarScheduleProvider.notifier).toggleSchedule(schedule.id);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          onPressed: () {
                            ref.read(azkarScheduleProvider.notifier).deleteSchedule(schedule.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddScheduleBottomSheet,
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Add Schedule"),
      ),
    );
  }
}

class _AddScheduleBottomSheet extends StatefulWidget {
  final List<AzkarChapter> chapters;
  final bool loading;
  final Function(AzkarChapter, TimeOfDay) onChapterSelected;

  const _AddScheduleBottomSheet({
    required this.chapters,
    required this.loading,
    required this.onChapterSelected,
  });

  @override
  State<_AddScheduleBottomSheet> createState() => _AddScheduleBottomSheetState();
}

class _AddScheduleBottomSheetState extends State<_AddScheduleBottomSheet> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredChapters = widget.chapters
        .where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Select Supplication Chapter",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search supplications...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = "";
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: widget.loading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredChapters.isEmpty
                      ? const Center(child: Text("No supplications match search query."))
                      : ListView.separated(
                          itemCount: filteredChapters.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final chapter = filteredChapters[index];

                            return ListTile(
                              title: Text(
                                chapter.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                              onTap: () async {
                                final TimeOfDay? pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                  barrierLabel: 'Select reciter trigger time',
                                  helpText: 'Select reciter trigger time',
                                );

                                if (pickedTime != null) {
                                  widget.onChapterSelected(chapter, pickedTime);
                                  if (context.mounted) Navigator.pop(context);
                                }
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
