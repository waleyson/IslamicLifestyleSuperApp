import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:islamic_super_app/modules/study/azkar/presentation/providers/daily_target_provider.dart';

class FocusModeOverlay extends ConsumerStatefulWidget {
  const FocusModeOverlay({super.key});

  @override
  ConsumerState<FocusModeOverlay> createState() => _FocusModeOverlayState();
}

class _FocusModeOverlayState extends ConsumerState<FocusModeOverlay> {
  int _countdown = 5;
  Timer? _timer;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DailyTargetState>(dailyTargetProvider, (previous, next) {
      if (previous?.lastCheckedDate != next.lastCheckedDate) {
        setState(() {
          _isDismissed = false;
          _countdown = 5;
          _timer?.cancel();
          _startCountdown();
        });
      }
    });

    final targetState = ref.watch(dailyTargetProvider);

    // Hide overlay if goals are met or user skipped for this active session
    if (targetState.isTargetMet || _isDismissed) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: Colors.black.withValues(alpha: 0.88),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Lock Icon
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFFD4AF37),
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title
                    const Text(
                      "Daily Spiritual Focus",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Ayah Quotation
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        "\"Verily, in the remembrance of Allah do hearts find rest.\"\n(Surah Ar-Ra'd 13:28)",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Progress Cards Container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildProgressRow(
                            title: "Quran Reading",
                            current: targetState.quranPagesRead,
                            target: targetState.quranPagesTarget,
                            unit: "pages",
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 20),
                          Divider(color: Colors.white.withValues(alpha: 0.1)),
                          const SizedBox(height: 20),
                          _buildProgressRow(
                            title: "Azkar Recitations",
                            current: targetState.azkarCompletedCount,
                            target: targetState.azkarTarget,
                            unit: "sessions",
                            color: const Color(0xFFD4AF37),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Main Action Redirect Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isDismissed = true;
                              });
                              GoRouter.of(context).go('/study');
                            },
                            icon: const Icon(Icons.menu_book),
                            label: const Text("Read Quran"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isDismissed = true;
                              });
                              GoRouter.of(context).go('/azkar');
                            },
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text("Recite Azkar"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: const Color(0xFF0F2B1D),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Bypass Option
                    TextButton(
                      onPressed: _countdown == 0
                          ? () {
                              setState(() {
                                _isDismissed = true;
                              });
                            }
                          : null,
                      child: Text(
                        _countdown > 0
                            ? "Bypass in ${_countdown}s"
                            : "Skip for now",
                        style: TextStyle(
                          color: _countdown > 0
                              ? Colors.white38
                              : Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressRow({
    required String title,
    required int current,
    required int target,
    required String unit,
    required Color color,
  }) {
    final double percent = target > 0 ? (current / target).clamp(0.0, 1.0) : 1.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            Text(
              "$current / $target $unit",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: percent,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
