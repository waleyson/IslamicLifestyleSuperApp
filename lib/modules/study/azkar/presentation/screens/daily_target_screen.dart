import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:islamic_super_app/modules/study/azkar/presentation/providers/daily_target_provider.dart';
import 'package:islamic_super_app/shared/services/native_blocker_service.dart';

class DailyTargetScreen extends ConsumerStatefulWidget {
  const DailyTargetScreen({super.key});

  @override
  ConsumerState<DailyTargetScreen> createState() => _DailyTargetScreenState();
}

class _DailyTargetScreenState extends ConsumerState<DailyTargetScreen> {
  late double _quranTarget;
  late double _azkarTarget;
  bool _isNativeLockPermissionGranted = false;
  bool _isLoadingPermission = true;

  @override
  void initState() {
    super.initState();
    final targetState = ref.read(dailyTargetProvider);
    _quranTarget = targetState.quranPagesTarget.toDouble();
    _azkarTarget = targetState.azkarTarget.toDouble();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPermission = true;
    });
    final granted = await ref.read(nativeBlockerServiceProvider).isPermissionGranted();
    if (mounted) {
      setState(() {
        _isNativeLockPermissionGranted = granted;
        _isLoadingPermission = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    await ref.read(nativeBlockerServiceProvider).requestPermission();
    // After returning from setting intent, trigger a re-check
    await Future.delayed(const Duration(seconds: 1));
    _checkPermissionStatus();
  }

  void _saveTargets() {
    ref.read(dailyTargetProvider.notifier).updateTargets(
          quranTarget: _quranTarget.toInt(),
          azkarTarget: _azkarTarget.toInt(),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Daily spiritual targets saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Spiritual Wellbeing',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Check Permission Status',
            onPressed: _checkPermissionStatus,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [colorScheme.primary, const Color(0xFF0F2B1D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.spa_rounded,
                    color: Color(0xFFD4AF37),
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Set Your Spiritual Goals",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Balance your daily life by committing to Quran reading and Azkar supplications.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.75),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Goal Sliders Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily Quran Goal",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Pages to read:",
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                        Text(
                          "${_quranTarget.toInt()} Pages",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _quranTarget,
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: _quranTarget.toInt().toString(),
                      onChanged: (val) {
                        setState(() {
                          _quranTarget = val;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Daily Azkar Goal",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Recitation sessions:",
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                        Text(
                          "${_azkarTarget.toInt()} Sessions",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD4AF37),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _azkarTarget,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: _azkarTarget.toInt().toString(),
                      onChanged: (val) {
                        setState(() {
                          _azkarTarget = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveTargets,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Save Targets",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Native App Blocker Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.app_blocking_rounded,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            "OS-Level Social Media Lock",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Locks access to social media and messaging apps (WhatsApp, Instagram, Facebook, TikTok, Twitter, Telegram, Discord, YouTube, Snapchat, Reddit) until you have met your daily reading and Azkar goals.",
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: colorScheme.outlineVariant),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Lock Status:",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        _isLoadingPermission
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _isNativeLockPermissionGranted
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _isNativeLockPermissionGranted ? "Active" : "Inactive",
                                  style: TextStyle(
                                    color: _isNativeLockPermissionGranted ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (!_isNativeLockPermissionGranted)
                      ElevatedButton(
                        onPressed: _requestPermission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.secondaryContainer,
                          foregroundColor: colorScheme.onSecondaryContainer,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Grant Permission / Enable Lock",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      Text(
                        "✓ Lock status will automatically toggle when daily targets are completed.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
