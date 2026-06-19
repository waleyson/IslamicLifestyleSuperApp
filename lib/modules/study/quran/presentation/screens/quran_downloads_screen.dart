import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:islamic_super_app/modules/study/quran/data/models/surah_model.dart';
import 'package:islamic_super_app/modules/study/quran/presentation/providers/quran_list_provider.dart';

class QuranDownloadsScreen extends ConsumerStatefulWidget {
  const QuranDownloadsScreen({super.key});

  @override
  ConsumerState<QuranDownloadsScreen> createState() =>
      _QuranDownloadsScreenState();
}

class _QuranDownloadsScreenState
    extends ConsumerState<QuranDownloadsScreen> {
  // surahNumber → size in bytes (loaded asynchronously)
  final Map<int, int> _sizes = {};
  Set<int> _downloadedSurahs = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadedInfo();
  }

  Future<void> _loadDownloadedInfo() async {
    setState(() => _isLoading = true);
    final downloadService = ref.read(quranDownloadServiceProvider);
    final reciter = ref.read(selectedReciterProvider);
    final subfolder =
        reciter?.subfolder.isNotEmpty == true ? reciter!.subfolder : 'Alafasy_128kbps';

    final downloaded = await downloadService.downloadedSurahs(subfolder);
    final sizes = <int, int>{};
    for (final surahNum in downloaded) {
      sizes[surahNum] =
          await downloadService.audioSizeBytes(subfolder, surahNum);
    }

    if (mounted) {
      setState(() {
        _downloadedSurahs = downloaded;
        _sizes.addAll(sizes);
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSurah(SurahModel surah) async {
    final downloadService = ref.read(quranDownloadServiceProvider);
    final reciter = ref.read(selectedReciterProvider);
    final subfolder =
        reciter?.subfolder.isNotEmpty == true ? reciter!.subfolder : 'Alafasy_128kbps';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Download'),
        content:
            Text('Remove downloaded audio for ${surah.englishName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await downloadService.deleteAudioForSurah(subfolder, surah.number);
      await _loadDownloadedInfo();
    }
  }

  Future<void> _deleteAll() async {
    final downloadService = ref.read(quranDownloadServiceProvider);
    final reciter = ref.read(selectedReciterProvider);
    final subfolder =
        reciter?.subfolder.isNotEmpty == true ? reciter!.subfolder : 'Alafasy_128kbps';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Downloads'),
        content: const Text(
            'This will remove all downloaded Quran audio files. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await downloadService.deleteAllAudio(subfolder);
      await _loadDownloadedInfo();
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  int get _totalBytes => _sizes.values.fold(0, (s, v) => s + v);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final surahsAsync = ref.watch(quranListProvider);
    final reciter = ref.watch(selectedReciterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          if (_downloadedSurahs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Delete All',
              onPressed: _deleteAll,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadDownloadedInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Info Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.storage_rounded, color: colorScheme.primary),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_downloadedSurahs.length} Surahs Downloaded',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_formatSize(_totalBytes)} used',
                      style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
                const Spacer(),
                if (reciter != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Reciter',
                          style: TextStyle(fontSize: 11)),
                      Text(
                        reciter.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _downloadedSurahs.isEmpty
                    ? _buildEmptyState(colorScheme)
                    : surahsAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) =>
                            Center(child: Text('Error: $e')),
                        data: (surahs) {
                          final downloaded = surahs
                              .where((s) =>
                                  _downloadedSurahs.contains(s.number))
                              .toList();
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: downloaded.length,
                            itemBuilder: (ctx, i) {
                              final surah = downloaded[i];
                              final size = _sizes[surah.number] ?? 0;
                              return _DownloadedSurahTile(
                                surah: surah,
                                sizeLabel: _formatSize(size),
                                onDelete: () => _deleteSurah(surah),
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

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.download_for_offline_outlined,
              size: 72, color: colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No Downloads Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Download surahs from the Quran list\nto listen offline.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Downloaded Surah Tile ────────────────────────────────────────────────────

class _DownloadedSurahTile extends StatelessWidget {
  final SurahModel surah;
  final String sizeLabel;
  final VoidCallback onDelete;

  const _DownloadedSurahTile({
    required this.surah,
    required this.sizeLabel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: Key('surah_${surah.number}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.red),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: ListTile(
          leading: Container(
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
                ),
              ),
            ),
          ),
          title: Text(surah.englishName,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${surah.name}  •  $sizeLabel',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
              fontFamily: 'Amiri',
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.download_done_rounded,
                  color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
