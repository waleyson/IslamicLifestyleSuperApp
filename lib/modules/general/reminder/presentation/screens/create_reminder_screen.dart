import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:islamic_super_app/modules/general/reminder/data/models/reminder_model.dart';
import 'package:islamic_super_app/modules/general/reminder/presentation/providers/reminder_provider.dart';
import 'package:islamic_super_app/modules/study/quran/data/models/surah_model.dart';
import 'package:islamic_super_app/modules/study/quran/presentation/providers/quran_list_provider.dart';
import 'package:islamic_super_app/shared/services/media_playback_service.dart';

class CreateReminderScreen extends ConsumerStatefulWidget {
  const CreateReminderScreen({super.key});

  @override
  ConsumerState<CreateReminderScreen> createState() =>
      _CreateReminderScreenState();
}

class _CreateReminderScreenState extends ConsumerState<CreateReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSaving = false;

  bool _isQuranReminder = false;
  SurahModel? _selectedSurah;
  int _selectedAyahNumber = 1;
  int? _endAyahNumber;
  String _selectedRecurrence = 'once';
  bool _isLoadingAyah = false;
  String? _fetchedAyahText;
  String? _fetchedAudioUrl;
  String? _fetchError;

  @override
  void dispose() {
    _titleController.dispose();
    ref.read(mediaPlaybackServiceProvider).stop();
    super.dispose();
  }

  Future<void> _fetchAyahDetails() async {
    if (_selectedSurah == null) return;
    setState(() {
      _isLoadingAyah = true;
      _fetchError = null;
    });
    try {
      final repo = ref.read(quranRepositoryProvider);
      final data = await repo.fetchAyah(_selectedSurah!.number, _selectedAyahNumber);
      if (mounted) {
        setState(() {
          _fetchedAyahText = data['text'] as String?;
          _fetchedAudioUrl = data['audio'] as String?;
          _isLoadingAyah = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fetchError = "Failed to load ayah. Please check your internet connection.";
          _isLoadingAyah = false;
        });
      }
    }
  }

  void _onSurahChanged(SurahModel? surah) {
    if (surah == null) return;
    setState(() {
      _selectedSurah = surah;
      _selectedAyahNumber = 1;
      _endAyahNumber = 1;
      _fetchedAyahText = null;
      _fetchedAudioUrl = null;
    });
    ref.read(mediaPlaybackServiceProvider).stop();
    _fetchAyahDetails();
  }

  void _onAyahChanged(int ayahNum) {
    setState(() {
      _selectedAyahNumber = ayahNum;
      if (_endAyahNumber == null || _endAyahNumber! < ayahNum) {
        _endAyahNumber = ayahNum;
      }
      _fetchedAyahText = null;
      _fetchedAudioUrl = null;
    });
    ref.read(mediaPlaybackServiceProvider).stop();
    _fetchAyahDetails();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  DateTime get _scheduledDateTime => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isQuranReminder && _fetchedAyahText == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for the Quran verse to finish loading.')),
      );
      return;
    }
    setState(() => _isSaving = true);

    final titleText = _titleController.text.trim();
    final reminderTitle = _isQuranReminder
        ? (_endAyahNumber != null && _endAyahNumber! > _selectedAyahNumber
            ? 'Quran: Surah ${_selectedSurah?.englishName}, Ayahs $_selectedAyahNumber-$_endAyahNumber'
            : 'Quran: Surah ${_selectedSurah?.englishName}, Ayah $_selectedAyahNumber')
        : titleText;

    final reminder = ReminderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: reminderTitle,
      scheduledTime: _scheduledDateTime,
      isQuranReminder: _isQuranReminder,
      surahNumber: _selectedSurah?.number,
      surahName: _selectedSurah?.englishName,
      ayahNumber: _selectedAyahNumber,
      ayahText: _fetchedAyahText,
      audioUrl: _fetchedAudioUrl,
      endAyahNumber: _isQuranReminder ? _endAyahNumber : null,
      recurrence: _selectedRecurrence,
    );
    await ref.read(reminderListProvider.notifier).addReminder(reminder);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('New Reminder')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title Field
            TextFormField(
              controller: _titleController,
              autofocus: true,
              enabled: !_isQuranReminder,
              decoration: InputDecoration(
                labelText: _isQuranReminder ? 'Reminder title (Auto-generated)' : 'Reminder title',
                hintText: _isQuranReminder ? 'Title will be Surah name & Ayah number' : 'e.g. Fajr Prayer, Read Quran...',
                prefixIcon: const Icon(Icons.edit_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
              ),
              validator: (v) {
                if (_isQuranReminder) return null;
                return (v == null || v.trim().isEmpty) ? 'Title is required' : null;
              },
            ),
            const SizedBox(height: 20),

            // Play Quran Verse Switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Play Quran Verse', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Play a specific Quran verse audio when this reminder is triggered'),
              value: _isQuranReminder,
              onChanged: (val) {
                setState(() {
                  _isQuranReminder = val;
                });
                if (!val) {
                  ref.read(mediaPlaybackServiceProvider).stop();
                }
              },
              secondary: Icon(Icons.menu_book, color: colorScheme.primary),
            ),

            if (_isQuranReminder) ...[
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
                ),
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Surah Dropdown
                      ref.watch(quranListProvider).when(
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (err, stack) => Center(
                              child: Text('Error loading Surahs: $err'),
                            ),
                            data: (surahs) {
                              if (_selectedSurah == null && surahs.isNotEmpty) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _onSurahChanged(surahs.first);
                                });
                              }
                              return DropdownButtonFormField<SurahModel>(
                                decoration: InputDecoration(
                                  labelText: 'Select Surah',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.chrome_reader_mode),
                                ),
                                value: _selectedSurah,
                                items: surahs.map((surah) {
                                  return DropdownMenuItem<SurahModel>(
                                    value: surah,
                                    child: Text(
                                      '${surah.number}. ${surah.englishName} (${surah.name})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: _onSurahChanged,
                              );
                            },
                          ),
                      const SizedBox(height: 16),

                      // Start & End Ayah Dropdowns Side-by-Side
                      if (_selectedSurah != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                decoration: InputDecoration(
                                  labelText: 'Start Ayah',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                value: _selectedAyahNumber,
                                items: List.generate(
                                  _selectedSurah!.numberOfAyahs,
                                  (i) => i + 1,
                                ).map((ayahNum) {
                                  return DropdownMenuItem<int>(
                                    value: ayahNum,
                                    child: Text('Ayah $ayahNum'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) _onAyahChanged(val);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                decoration: InputDecoration(
                                  labelText: 'End Ayah',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                value: _endAyahNumber ?? _selectedAyahNumber,
                                items: List.generate(
                                  _selectedSurah!.numberOfAyahs - _selectedAyahNumber + 1,
                                  (i) => _selectedAyahNumber + i,
                                ).map((ayahNum) {
                                  return DropdownMenuItem<int>(
                                    value: ayahNum,
                                    child: Text('Ayah $ayahNum'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _endAyahNumber = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Ayah Preview Section
                        if (_isLoadingAyah)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.0),
                              child: Column(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 10),
                                  Text('Fetching verse text & audio...', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          )
                        else if (_fetchError != null)
                          Center(
                            child: Column(
                              children: [
                                Text(_fetchError!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
                                TextButton.icon(
                                  onPressed: _fetchAyahDetails,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                )
                              ],
                            ),
                          )
                        else if (_fetchedAyahText != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              _fetchedAyahText!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                height: 1.6,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Amiri',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_fetchedAudioUrl != null)
                            Center(
                              child: StreamBuilder<bool>(
                                  stream: ref.watch(mediaPlaybackServiceProvider).playingStream,
                                  builder: (context, snapshot) {
                                    final isPlaying = snapshot.data ?? false;
                                    return ElevatedButton.icon(
                                      onPressed: () async {
                                        final mediaService = ref.read(mediaPlaybackServiceProvider);
                                        if (isPlaying) {
                                          await mediaService.pause();
                                        } else {
                                          await mediaService.playAudioFromUrl(_fetchedAudioUrl!);
                                        }
                                      },
                                      icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                                      label: Text(isPlaying ? 'Stop Preview' : 'Listen Preview'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.secondaryContainer,
                                        foregroundColor: colorScheme.onSecondaryContainer,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                  }),
                            ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Date & Time Selection
            Text('Date & Time',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value: _formatDate(_selectedDate),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.access_time,
                    label: 'Time',
                    value: _selectedTime.format(context),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recurrence Configuration
            Text('Recurrence',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.repeat),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              value: _selectedRecurrence,
              items: const [
                DropdownMenuItem(value: 'once', child: Text('Once')),
                DropdownMenuItem(value: 'hourly', child: Text('Hourly')),
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedRecurrence = val;
                  });
                }
              },
            ),
            const SizedBox(height: 32),

            // Quick Presets
            if (!_isQuranReminder) ...[
              Text('Quick Presets',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Fajr Prayer 🌙',
                  'Dhuhr Prayer ☀️',
                  'Asr Prayer 🌤️',
                  'Maghrib Prayer 🌅',
                  'Isha Prayer 🌙',
                  'Read Quran 📖',
                  'Morning Dhikr 🤲',
                  'Tahajjud ✨',
                ]
                    .map(
                      (preset) => ActionChip(
                        label: Text(preset, style: const TextStyle(fontSize: 12)),
                        onPressed: () => setState(
                            () => _titleController.text = preset),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 32),
            ],

            // Save Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check),
                label: Text(_isSaving ? 'Saving...' : 'Save Reminder'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.55))),
                  Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
