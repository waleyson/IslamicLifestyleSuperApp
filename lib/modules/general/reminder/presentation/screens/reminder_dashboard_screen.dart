import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';

import 'package:islamic_super_app/modules/general/reminder/presentation/providers/reminder_provider.dart';
import 'package:islamic_super_app/modules/business/savings/presentation/providers/savings_provider.dart';
import 'package:islamic_super_app/modules/business/investment/presentation/providers/investment_provider.dart';
import 'package:islamic_super_app/core/widgets/exit_dialog.dart';
import 'package:islamic_super_app/modules/general/prayer_times/presentation/widgets/prayer_times_card.dart';

class ReminderDashboardScreen extends ConsumerWidget {
  const ReminderDashboardScreen({super.key});

  // Simulated Hijri Date Calculator
  String _getHijriDate(DateTime dt) {
    // 2026-06-01 is roughly 15 Dhū al-Ḥijjah 1447 AH
    // 1 Dhul-Hijjah 1447 is roughly May 17, 2026.
    final refDate = DateTime(2026, 5, 17);
    final diff = dt.difference(refDate).inDays;
    
    if (diff >= 0 && diff < 30) {
      return '${diff + 1} Dhū al-Ḥijjah 1447 AH';
    } else if (diff >= 30 && diff < 59) {
      return '${diff - 29} Muḥarram 1448 AH';
    } else if (diff < 0 && diff > -30) {
      return '${30 + diff} Dhū al-Qi\'dah 1447 AH';
    }
    return '15 Dhū al-Ḥijjah 1447 AH';
  }

  String _formatGregorianDate(DateTime dt) {
    final weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June', 
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final weekday = weekdays[dt.weekday % 7];
    final day = dt.day;
    final month = months[dt.month - 1];
    final year = dt.year;
    return '$weekday, $day $month $year';
  }

  // Selected Inspiring Quranic Verses for "Verse of the Day"
  Map<String, String> _getVerseOfTheDay() {
    final verses = [
      {
        'arabic': 'فَاذْكُرُونِي أَذْكُرْكُمْ',
        'english': 'So remember Me; I will remember you.',
        'reference': 'Surah Al-Baqarah 2:152'
      },
      {
        'arabic': 'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
        'english': 'Indeed, with hardship [will be] ease.',
        'reference': 'Surah Ash-Sharh 94:6'
      },
      {
        'arabic': 'وَالَّذِينَ جَاهَدُوا فِينَا لَنَهْدِيَنَّهُمْ سُبُلَنَا',
        'english': 'And those who strive for Us - We will surely guide them to Our ways.',
        'reference': 'Surah Al-Ankabut 29:69'
      },
      {
        'arabic': 'لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ',
        'english': 'If you are grateful, I will surely increase you [in favor].',
        'reference': 'Surah Ibrahim 14:7'
      },
      {
        'arabic': 'لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ',
        'english': 'Do not despair of the mercy of Allah.',
        'reference': 'Surah Az-Zumar 39:53'
      }
    ];

    // Pick a verse deterministically based on the current day of the month
    final index = DateTime.now().day % verses.length;
    return verses[index];
  }

  String _formatTimeOnly(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderState = ref.watch(reminderListProvider);
    final savingsAsync = ref.watch(savingsProvider);
    final investmentsAsync = ref.watch(investmentProvider);
    
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final verse = _getVerseOfTheDay();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Islamic Lifestyle'),
        leading: IconButton(
          icon: const Icon(Icons.exit_to_app_outlined),
          tooltip: 'Exit App',
          onPressed: () => showExitConfirmationDialog(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'All Reminders',
            onPressed: () => context.push('/all_reminders'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Premium Glassmorphic Welcome Card
            _buildWelcomeCard(context, colorScheme, now),
            
            const SizedBox(height: 20),

            // Salah/Prayer Times Card
            const PrayerTimesCard(),

            const SizedBox(height: 20),

            // 2. Verse of the Day Card (Visual & Clean)
            _buildVerseCard(colorScheme, verse),
            
            const SizedBox(height: 24),

            // 3. Quick Actions Header & Grid
            Text(
              'Quick Services',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildQuickActions(context, colorScheme),

            const SizedBox(height: 24),

            // 4. Financial Health Snapshot
            _buildFinancialSnapshot(context, colorScheme, savingsAsync, investmentsAsync),

            const SizedBox(height: 24),

            // 5. Spiritual Timeline Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Reminders',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () => context.push('/all_reminders'),
                  child: Row(
                    children: [
                      Text(
                        'Manage',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: colorScheme.primary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 6. Timeline List
            _buildUpcomingTimeline(context, colorScheme, reminderState, ref),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ==================== WIDGET BUILDERS ====================

  Widget _buildWelcomeCard(BuildContext context, ColorScheme colorScheme, DateTime now) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assalamu Alaikum,',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Spiritual Companion',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Text('🕌', style: TextStyle(fontSize: 24)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getHijriDate(now),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatGregorianDate(now),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.5), width: 1),
                ),
                child: Text(
                  'ACTIVE',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerseCard(ColorScheme colorScheme, Map<String, String> verse) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('✨', style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'VERSE OF THE DAY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            verse['arabic']!,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
              fontFamily: 'Amiri',
              height: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '"${verse['english']!}"',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: colorScheme.onSurface.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            verse['reference']!,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ColorScheme colorScheme) {
    final actions = [
      {
        'icon': Icons.add_alarm,
        'label': 'New Alarm',
        'color': colorScheme.primary,
        'onTap': () => context.push('/create_reminder'),
      },
      {
        'icon': Icons.menu_book,
        'label': 'Read Quran',
        'color': colorScheme.tertiary,
        'onTap': () => context.go('/study'),
      },
      {
        'icon': Icons.savings_outlined,
        'label': 'Halal Savings',
        'color': colorScheme.secondary,
        'onTap': () => context.go('/business'),
      },
      {
        'icon': Icons.trending_up,
        'label': 'Investments',
        'color': colorScheme.primary,
        'onTap': () => context.go('/business'),
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((act) {
        return Expanded(
          child: Column(
            children: [
              GestureDetector(
                onTap: act['onTap'] as VoidCallback,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: (act['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (act['color'] as Color).withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    act['icon'] as IconData,
                    color: act['color'] as Color,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                act['label'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFinancialSnapshot(
    BuildContext context,
    ColorScheme colorScheme,
    AsyncValue<List<dynamic>> savingsAsync,
    AsyncValue<List<dynamic>> investmentsAsync,
  ) {
    double totalSaved = 0;
    double totalInvested = 0;

    savingsAsync.whenData((goals) {
      if (goals.isNotEmpty) {
        totalSaved = goals.fold(0.0, (s, g) => s + g.currentAmount);
      }
    });

    investmentsAsync.whenData((assets) {
      if (assets.isNotEmpty) {
        totalInvested = assets.fold(0.0, (s, a) => s + a.currentValue);
      }
    });

    return GestureDetector(
      onTap: () => context.go('/business'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08), width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 20, color: Colors.teal),
                    const SizedBox(width: 8),
                    const Text(
                      'Halal Finance Snapshot',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward_ios, size: 12, color: colorScheme.onSurface.withValues(alpha: 0.3)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Halal Savings',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${totalSaved.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: colorScheme.outline.withValues(alpha: 0.15),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ethical Portfolio Value',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${totalInvested.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTimeline(
    BuildContext context,
    ColorScheme colorScheme,
    AsyncValue<List<dynamic>> reminderState,
    WidgetRef ref,
  ) {
    return reminderState.when(
      data: (reminders) {
        // Filter only active/upcoming reminders if possible, otherwise show first 3
        final activeReminders = reminders.where((r) => r.isEnabled).toList();
        final listToDisplay = activeReminders.isNotEmpty ? activeReminders : reminders;
        
        if (listToDisplay.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 40,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No reminders active.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => context.push('/create_reminder'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Alarm'),
                  ),
                ],
              ),
            ),
          );
        }

        // Show maximum of 3 items
        final limitList = listToDisplay.sublist(0, min(3, listToDisplay.length));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: limitList.length,
          itemBuilder: (context, index) {
            final reminder = limitList[index];
            final isLast = index == limitList.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Timeline visual indicators
                  Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: reminder.isEnabled ? colorScheme.primary : Colors.grey.shade400,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (reminder.isEnabled ? colorScheme.primary : Colors.grey).withValues(alpha: 0.4),
                              blurRadius: 4,
                            )
                          ],
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: colorScheme.outline.withValues(alpha: 0.15),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Reminder item details
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.05),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: reminder.isQuranReminder
                                    ? colorScheme.primary.withValues(alpha: 0.08)
                                    : colorScheme.secondary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                reminder.isQuranReminder ? Icons.menu_book : Icons.notifications_active_outlined,
                                size: 18,
                                color: reminder.isQuranReminder ? colorScheme.primary : colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reminder.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_formatTimeOnly(reminder.scheduledTime)}  •  ${reminder.recurrence.toUpperCase()}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
