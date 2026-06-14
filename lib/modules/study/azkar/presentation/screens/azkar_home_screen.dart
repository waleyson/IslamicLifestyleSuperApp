import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:islamic_super_app/modules/study/azkar/presentation/providers/azkar_provider.dart';
import 'package:islamic_super_app/modules/study/azkar/presentation/providers/daily_target_provider.dart';

class AzkarHomeScreen extends ConsumerWidget {
  const AzkarHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(azkarCategoriesProvider);
    final targetState = ref.watch(dailyTargetProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hisnul Muslim',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.alarm_add_rounded),
            tooltip: 'Scheduled Auto-Plays',
            onPressed: () => GoRouter.of(context).push('/azkar_schedule'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_suggest_rounded),
            tooltip: 'Configure Goals',
            onPressed: () => GoRouter.of(context).push('/daily_target'),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Progress Header Card
              _buildProgressCard(context, targetState, colorScheme),
              const SizedBox(height: 24),

              Text(
                "Azkar Categories",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              // Categories Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  // Assign some beautiful gradients based on index
                  final List<Color> gradientColors = _getGradientColors(index);

                  return _buildCategoryCard(context, category, gradientColors);
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading Azkar: $err')),
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    DailyTargetState state,
    ColorScheme colorScheme,
  ) {
    final double percent = state.azkarTarget > 0
        ? (state.azkarCompletedCount / state.azkarTarget).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2B1D), Color(0xFF1B4D36)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Spiritual Completion",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white70, size: 20),
                onPressed: () => GoRouter.of(context).push('/daily_target'),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Daily Azkar Progress",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
              Text(
                "${state.azkarCompletedCount} / ${state.azkarTarget} Sessions",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4AF37),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: percent,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            state.isTargetMet
                ? "🎉 You have completed your spiritual goals for today!"
                : "Complete your targets to release the social media lock.",
            style: TextStyle(
              fontSize: 11,
              color: state.isTargetMet ? const Color(0xFFD4AF37) : Colors.white60,
              fontWeight: FontWeight.w500,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    dynamic category,
    List<Color> gradient,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[1].withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            GoRouter.of(context).push('/azkar_chapters/${category.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.spa_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientColors(int index) {
    final List<List<Color>> gradients = [
      [const Color(0xFF1E3A2F), const Color(0xFF0F2B1D)], // Dark Green
      [const Color(0xFF7A6030), const Color(0xFF4A3B18)], // Gold / Brown
      [const Color(0xFF1F3C4D), const Color(0xFF0F1B24)], // Navy
      [const Color(0xFF5A1E30), const Color(0xFF300F18)], // Maroon
      [const Color(0xFF4A1E5A), const Color(0xFF2B0F3A)], // Purple
      [const Color(0xFF1E4A5A), const Color(0xFF0F2B3A)], // Teal
    ];
    return gradients[index % gradients.length];
  }
}
