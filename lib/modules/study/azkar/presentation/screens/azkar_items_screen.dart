import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';
import 'package:islamic_super_app/modules/study/azkar/presentation/providers/azkar_provider.dart';
import 'package:islamic_super_app/modules/study/azkar/presentation/providers/daily_target_provider.dart';

class AzkarItemsScreen extends ConsumerStatefulWidget {
  final int chapterId;

  const AzkarItemsScreen({super.key, required this.chapterId});

  @override
  ConsumerState<AzkarItemsScreen> createState() => _AzkarItemsScreenState();
}

class _AzkarItemsScreenState extends ConsumerState<AzkarItemsScreen> {
  final Map<int, int> _counts = {};
  bool _chapterCompleted = false;

  /// Helper to parse repeat counts from supplication translations/references.
  int _getTargetCount(AzkarItem item) {
    final trans = item.translation.toLowerCase();
    final ref = item.reference.toLowerCase();
    if (trans.contains("three times") || ref.contains("three times") || trans.contains("3 times")) return 3;
    if (trans.contains("seven times") || ref.contains("seven times") || trans.contains("7 times")) return 7;
    if (trans.contains("four times") || ref.contains("four times") || trans.contains("4 times")) return 4;
    if (trans.contains("ten times") || ref.contains("ten times") || trans.contains("10 times")) return 10;
    if (trans.contains("one hundred times") || trans.contains("100 times") || ref.contains("100 times")) return 100;
    if (trans.contains("thirty three times") || trans.contains("33 times") || ref.contains("33 times")) return 33;
    if (trans.contains("thirty-three times")) return 33;
    return 1; // Default
  }

  void _onItemTapped(AzkarItem item, int target) {
    if (_chapterCompleted) return;

    final current = _counts[item.id] ?? 0;
    if (current < target) {
      setState(() {
        _counts[item.id] = current + 1;
      });
      // Check if this action completes the whole chapter
      _checkCompletion();
    }
  }

  void _checkCompletion() async {
    final itemsAsync = ref.read(azkarItemsProvider(widget.chapterId));
    itemsAsync.whenData((items) async {
      bool allFinished = true;
      for (final item in items) {
        final current = _counts[item.id] ?? 0;
        final target = _getTargetCount(item);
        if (current < target) {
          allFinished = false;
          break;
        }
      }

      if (allFinished && !_chapterCompleted) {
        setState(() {
          _chapterCompleted = true;
        });
        
        // Add to daily target provider
        await ref.read(dailyTargetProvider.notifier).incrementAzkar();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Masha'Allah! Category completed! Daily target updated!"),
              backgroundColor: Colors.teal,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(azkarItemsProvider(widget.chapterId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recitation',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_chapterCompleted)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Icon(Icons.check_circle, color: Colors.green, size: 28),
            )
        ],
      ),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No supplications found.'));
          }

          return Column(
            children: [
              if (_chapterCompleted)
                Container(
                  width: double.infinity,
                  color: Colors.green.withValues(alpha: 0.15),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stars, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        "Chapter Completed! +1 Daily Session Earned",
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final target = _getTargetCount(item);
                    final current = _counts[item.id] ?? 0;
                    final isDone = current >= target;

                    return Card(
                      elevation: isDone ? 0.5 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: isDone ? Colors.green.withValues(alpha: 0.3) : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Arabic Text
                            Text(
                              item.item,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontSize: 26,
                                height: 1.8,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Amiri',
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Translation
                            Text(
                              item.translation,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Reference
                            if (item.reference.isNotEmpty)
                              Text(
                                "Source: ${item.reference}",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                ),
                              ),
                            const SizedBox(height: 20),
                            // Counter Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Target: ×$target",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _onItemTapped(item, target),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isDone
                                          ? Colors.green.withValues(alpha: 0.15)
                                          : colorScheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: isDone ? Colors.green : colorScheme.primary,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isDone ? Icons.check : Icons.touch_app,
                                          size: 16,
                                          color: isDone ? Colors.green : colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isDone ? "Done" : "$current / $target",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDone ? Colors.green : colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading recitation: $err')),
      ),
    );
  }
}
