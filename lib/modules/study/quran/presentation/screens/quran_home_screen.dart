import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:islamic_super_app/modules/study/quran/data/models/surah_model.dart';
import 'package:islamic_super_app/modules/study/quran/data/models/reciter_model.dart';
import 'package:islamic_super_app/modules/study/quran/data/models/translation_model.dart';
import 'package:islamic_super_app/modules/study/quran/presentation/providers/quran_audio_provider.dart';
import 'package:islamic_super_app/modules/study/quran/presentation/providers/quran_list_provider.dart';
import 'package:islamic_super_app/core/widgets/exit_dialog.dart';

class QuranHomeScreen extends ConsumerStatefulWidget {
  const QuranHomeScreen({super.key});

  @override
  ConsumerState<QuranHomeScreen> createState() => _QuranHomeScreenState();
}

class _QuranHomeScreenState extends ConsumerState<QuranHomeScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  // Tracks per-surah download progress (surahNumber → progress stream sub)
  final Map<int, double> _downloadProgress = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Settings Bottom Sheet ─────────────────────────────────────────────────

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _QuranSettingsSheet(),
    );
  }

  // ─── Download Logic ────────────────────────────────────────────────────────

  Future<void> _downloadSurah(SurahModel surah) async {
    final reciter = ref.read(selectedReciterProvider);
    final subfolder = reciter?.subfolder.isNotEmpty == true
        ? reciter!.subfolder
        : 'Alafasy_128kbps';
    final downloadService = ref.read(quranDownloadServiceProvider);

    final stream = downloadService.downloadSurah(
        subfolder, surah.number, surah.numberOfAyahs);

    await for (final progress in stream) {
      if (mounted) {
        setState(() {
          _downloadProgress[surah.number] = progress.fraction;
        });
      }
      if (progress.isDone) {
        if (mounted) {
          setState(() => _downloadProgress.remove(surah.number));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${surah.englishName} downloaded ✓'),
              backgroundColor: const Color(0xFF1B4D36),
            ),
          );
        }
      }
    }
  }

  Future<void> _downloadFullQuran(List<SurahModel> surahs) async {
    final reciter = ref.read(selectedReciterProvider);
    final subfolder = reciter?.subfolder.isNotEmpty == true
        ? reciter!.subfolder
        : 'Alafasy_128kbps';
    final downloadService = ref.read(quranDownloadServiceProvider);
    final counts = {for (final s in surahs) s.number: s.numberOfAyahs};

    final stream =
        downloadService.downloadFullQuran(subfolder, counts);

    await for (final progress in stream) {
      if (!mounted) break;
      // Show overall progress on verse 1 of each surah
      if (progress.isDone && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Full Quran downloaded ✓'),
            backgroundColor: Color(0xFF1B4D36),
          ),
        );
      }
    }
  }

  void _showDownloadOptions(BuildContext context, SurahModel surah,
      List<SurahModel> allSurahs) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Download Audio',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _DownloadOption(
              icon: Icons.menu_book_rounded,
              title: surah.englishName,
              subtitle: '${surah.numberOfAyahs} verses',
              onTap: () {
                Navigator.pop(ctx);
                _downloadSurah(surah);
              },
            ),
            _DownloadOption(
              icon: Icons.library_books_rounded,
              title: 'Entire Quran',
              subtitle: '6,236 verses',
              onTap: () {
                Navigator.pop(ctx);
                _downloadFullQuran(allSurahs);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(quranListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('القرآن الكريم'),
        leading: IconButton(
          icon: const Icon(Icons.exit_to_app_outlined),
          tooltip: 'Exit App',
          onPressed: () => showExitConfirmationDialog(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined),
            tooltip: 'Manage Downloads',
            onPressed: () => context.push('/quran_downloads'),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Settings',
            onPressed: () => _showSettingsSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(quranListProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search surahs...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Selected Reciter/Translation chip bar
          _ReciterTranslationBar(),

          // Surah List
          Expanded(
            child: surahsAsync.when(
              loading: () => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading Surahs...'),
                  ],
                ),
              ),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, size: 56, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not load surahs.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(quranListProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (surahs) {
                final filtered = _query.isEmpty
                    ? surahs
                    : surahs
                        .where((s) =>
                            s.englishName.toLowerCase().contains(_query) ||
                            s.englishNameTranslation
                                .toLowerCase()
                                .contains(_query) ||
                            s.number.toString().contains(_query))
                        .toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No results found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final surah = filtered[index];
                    final progress = _downloadProgress[surah.number];

                    return _SurahTile(
                      surah: surah,
                      downloadProgress: progress,
                      onTap: () {
                        ref.read(quranAudioProvider).playSurah(surah);
                        context.push('/quran_player');
                      },
                      onDownload: () =>
                          _showDownloadOptions(context, surah, surahs),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reciter / Translation Info Bar ──────────────────────────────────────────

class _ReciterTranslationBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reciter = ref.watch(selectedReciterProvider);
    final translationId = ref.watch(selectedTranslationIdProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final reciterName = reciter?.name ?? 'Loading...';
    final translationLabel = translationId == 203
        ? 'Al-Hilali & Khan'
        : translationId == 20
            ? 'Saheeh International'
            : 'Translation #$translationId';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.record_voice_over_rounded,
              size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              reciterName,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.translate_rounded,
              size: 14, color: colorScheme.secondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              translationLabel,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Surah Tile ───────────────────────────────────────────────────────────────

class _SurahTile extends StatelessWidget {
  final SurahModel surah;
  final double? downloadProgress;
  final VoidCallback onTap;
  final VoidCallback onDownload;

  const _SurahTile({
    required this.surah,
    required this.onTap,
    required this.onDownload,
    this.downloadProgress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDownloading =
        downloadProgress != null && downloadProgress! < 1.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Surah Number Badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        surah.number.toString(),
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // English Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          surah.englishName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${surah.englishNameTranslation}  •  ${surah.revelationType}  •  ${surah.numberOfAyahs} verses',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arabic Name
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      surah.name,
                      style: TextStyle(
                        fontSize: 22,
                        color: colorScheme.primary,
                        fontFamily: 'Amiri',
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Download Button
                  IconButton(
                    icon: isDownloading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              value: downloadProgress,
                              strokeWidth: 2,
                              color: colorScheme.secondary,
                            ),
                          )
                        : Icon(
                            Icons.download_rounded,
                            color: colorScheme.secondary,
                            size: 22,
                          ),
                    tooltip: 'Download',
                    onPressed: isDownloading ? null : onDownload,
                  ),
                  Icon(Icons.play_circle_outline,
                      color: colorScheme.secondary, size: 28),
                ],
              ),
            ),
            // Download progress bar
            if (isDownloading)
              LinearProgressIndicator(
                value: downloadProgress,
                minHeight: 2,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Download Option Row ──────────────────────────────────────────────────────

class _DownloadOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DownloadOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading:
          Icon(icon, color: colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: onTap,
    );
  }
}

// ─── Settings Bottom Sheet ────────────────────────────────────────────────────

class _QuranSettingsSheet extends ConsumerStatefulWidget {
  const _QuranSettingsSheet();

  @override
  ConsumerState<_QuranSettingsSheet> createState() =>
      _QuranSettingsSheetState();
}

class _QuranSettingsSheetState extends ConsumerState<_QuranSettingsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final recitersAsync = ref.watch(reciterListProvider);
    final translationsAsync = ref.watch(translationListProvider);
    final selectedReciterId = ref.watch(selectedReciterIdProvider);
    final selectedTranslationId = ref.watch(selectedTranslationIdProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Quran Settings',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.record_voice_over_rounded), text: 'Reciter'),
                Tab(icon: Icon(Icons.translate_rounded), text: 'Translation'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── Reciter Tab ──
                  recitersAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (reciters) => ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      itemCount: reciters.length,
                      itemBuilder: (ctx, i) {
                        final r = reciters[i];
                        final isSelected = r.id == selectedReciterId;
                        return _ReciterTile(
                          reciter: r,
                          isSelected: isSelected,
                          onTap: () {
                            ref
                                .read(selectedReciterIdProvider.notifier)
                                .state = r.id;
                          },
                        );
                      },
                    ),
                  ),
                  // ── Translation Tab ──
                  translationsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (translations) {
                      // Group by language
                      final grouped = <String, List<TranslationModel>>{};
                      for (final t in translations) {
                        grouped
                            .putIfAbsent(t.languageName, () => [])
                            .add(t);
                      }
                      final languages = grouped.keys.toList()..sort();
                      // Pin English first
                      if (languages.remove('english')) {
                        languages.insert(0, 'english');
                      }

                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemCount: languages.length,
                        itemBuilder: (ctx, i) {
                          final lang = languages[i];
                          final items = grouped[lang]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    12, 12, 12, 4),
                                child: Text(
                                  lang.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                              ...items.map((t) => _TranslationTile(
                                    translation: t,
                                    isSelected:
                                        t.id == selectedTranslationId,
                                    onTap: () {
                                      ref
                                          .read(selectedTranslationIdProvider
                                              .notifier)
                                          .state = t.id;
                                    },
                                  )),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReciterTile extends StatelessWidget {
  final ReciterModel reciter;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReciterTile({
    required this.reciter,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isSelected
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.record_voice_over_rounded,
          size: 18,
          color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
        ),
      ),
      title: Text(reciter.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          )),
      subtitle: reciter.style != null
          ? Container(
              margin: const EdgeInsets.only(top: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                reciter.style!,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            )
          : null,
      trailing: isSelected
          ? Icon(Icons.check_circle, color: colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}

class _TranslationTile extends StatelessWidget {
  final TranslationModel translation;
  final bool isSelected;
  final VoidCallback onTap;

  const _TranslationTile({
    required this.translation,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(translation.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          )),
      subtitle: Text(translation.authorName,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: colorScheme.primary)
          : null,
      selected: isSelected,
      selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}
