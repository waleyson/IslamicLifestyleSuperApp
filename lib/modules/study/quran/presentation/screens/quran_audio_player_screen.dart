import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:islamic_super_app/modules/study/quran/data/models/quran_verse_model.dart';
import 'package:islamic_super_app/modules/study/quran/presentation/providers/quran_audio_provider.dart';
import 'package:islamic_super_app/modules/study/quran/presentation/providers/quran_list_provider.dart';
import 'package:islamic_super_app/shared/services/media_playback_service.dart';
import 'package:islamic_super_app/modules/study/azkar/presentation/providers/daily_target_provider.dart';

// Hardcoded Basmala (no longer depends on quran package)
const _kBasmala =
    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

class QuranAudioPlayerScreen extends ConsumerStatefulWidget {
  const QuranAudioPlayerScreen({super.key});

  @override
  ConsumerState<QuranAudioPlayerScreen> createState() =>
      _QuranAudioPlayerScreenState();
}

class _QuranAudioPlayerScreenState
    extends ConsumerState<QuranAudioPlayerScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = {};
  bool _autoScrollEnabled = true;
  int _lastActiveIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Auto-scroll ──────────────────────────────────────────────────────────

  void _scrollToActiveVerse(int index) {
    if (!_autoScrollEnabled || index < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _verseKeys[index];
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.2,
        );
      } else if (_scrollController.hasClients) {
        final offset = (240.0 + 90.0 + index * 160.0)
            .clamp(0.0, _scrollController.position.maxScrollExtent);
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // ─── Tafseer Bottom Sheet ─────────────────────────────────────────────────

  void _showTafseerSheet(String verseKey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TafseerSheet(verseKey: verseKey),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final surah = ref.watch(currentSurahProvider);
    final mediaService = ref.watch(mediaPlaybackServiceProvider);
    final audioNotifier = ref.read(quranAudioProvider);
    final downloadProgress = ref.watch(audioDownloadProgressProvider);
    final showTranslation = ref.watch(showTranslationProvider);

    if (surah == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player')),
        body: const Center(child: Text('No Surah selected')),
      );
    }

    final versesAsync = ref.watch(quranVersesProvider(surah.number));
    final hasBasmala = surah.number != 1 && surah.number != 9;

    return StreamBuilder<int?>(
      stream: mediaService.currentIndexStream,
      builder: (context, indexSnapshot) {
        final activeIndex = indexSnapshot.data ?? 0;

        if (activeIndex != _lastActiveIndex) {
          _lastActiveIndex = activeIndex;
          _scrollToActiveVerse(activeIndex);
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down,
                  size: 32, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  showTranslation ? Icons.translate : Icons.g_translate_outlined,
                  color: showTranslation
                      ? const Color(0xFFD4AF37)
                      : Colors.white54,
                ),
                tooltip: 'Toggle Translation',
                onPressed: () {
                  ref.read(showTranslationProvider.notifier).toggle(!showTranslation);
                },
              ),
              IconButton(
                icon: Icon(
                  _autoScrollEnabled ? Icons.sync : Icons.sync_disabled,
                  color: _autoScrollEnabled
                      ? const Color(0xFFD4AF37)
                      : Colors.white54,
                ),
                tooltip: 'Toggle Auto-Scroll',
                onPressed: () {
                  setState(() => _autoScrollEnabled = !_autoScrollEnabled);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0A1E14),
                  Color(0xFF1B3A28),
                  Colors.black,
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  // ── Verse List ──
                  Positioned.fill(
                    child: versesAsync.when(
                      loading: () => _buildLoadingList(surah.numberOfAyahs),
                      error: (err, _) => Center(
                        child: Text(
                          'Failed to load verses.\n$err',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      data: (verses) {
                        final totalListItems =
                            1 + (hasBasmala ? 1 : 0) + verses.length;
                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(
                            top: 8,
                            left: 8,
                            right: 8,
                            bottom: 240,
                          ),
                          itemCount: totalListItems,
                          itemBuilder: (ctx, index) {
                            if (index == 0) {
                              return _buildSurahHeaderCard(surah, context);
                            }
                            if (hasBasmala && index == 1) {
                              return _buildBasmalaCard();
                            }
                            final verseIndex =
                                hasBasmala ? index - 2 : index - 1;
                            final verse = verses[verseIndex];
                            final isActive = verseIndex == activeIndex;
                            final key = _verseKeys.putIfAbsent(
                                verseIndex, () => GlobalKey());

                            return StreamBuilder<bool>(
                              stream: mediaService.playingStream,
                              builder: (ctx, playingSnapshot) {
                                final isPlaying =
                                    playingSnapshot.data ?? false;
                                return _buildVerseCard(
                                  key: key,
                                  verse: verse,
                                  verseIndex: verseIndex,
                                  isActive: isActive,
                                  isPlaying: isPlaying,
                                  audioNotifier: audioNotifier,
                                  showTranslation: showTranslation,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // ── Download Progress Banner ──
                  if (downloadProgress != null)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _buildDownloadBanner(downloadProgress),
                    ),

                  // ── Floating Bottom Player ──
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildPlayerPanel(
                      context,
                      activeIndex,
                      surah.numberOfAyahs,
                      mediaService,
                      audioNotifier,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Loading Skeleton ─────────────────────────────────────────────────────

  Widget _buildLoadingList(int verseCount) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
      itemBuilder: (ctx, i) => Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFD4AF37),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  // ─── Download Banner ──────────────────────────────────────────────────────

  Widget _buildDownloadBanner(dynamic progress) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: const Color(0xFF0F2B1D).withValues(alpha: 0.85),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.download_rounded,
                        color: Color(0xFFD4AF37), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        progress.label as String? ?? 'Preparing audio...',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${((progress.fraction as double) * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress.fraction as double?,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFD4AF37)),
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Verse Card ───────────────────────────────────────────────────────────

  Widget _buildVerseCard({
    required GlobalKey key,
    required QuranVerseModel verse,
    required int verseIndex,
    required bool isActive,
    required bool isPlaying,
    required QuranAudioNotifier audioNotifier,
    required bool showTranslation,
  }) {
    return GestureDetector(
      onLongPress: () => _showTafseerSheet(verse.verseKey),
      child: Container(
        key: key,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF0F2B1D).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: isActive
                  ? const Color(0xFFD4AF37)
                  : Colors.transparent,
              width: 4,
            ),
            right: BorderSide(
              color: isActive
                  ? const Color(0xFFD4AF37).withValues(alpha: 0.2)
                  : Colors.transparent,
              width: 1,
            ),
            top: BorderSide(
              color: isActive
                  ? const Color(0xFFD4AF37).withValues(alpha: 0.2)
                  : Colors.transparent,
              width: 1,
            ),
            bottom: BorderSide(
              color: isActive
                  ? const Color(0xFFD4AF37).withValues(alpha: 0.2)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.08),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => audioNotifier.playVerse(verseIndex),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildVerseNumber(verse.verseNumber, context),
                      Row(
                        children: [
                          // Long-press hint
                          if (!isActive)
                            const Icon(Icons.info_outline,
                                color: Colors.white12, size: 14),
                          const SizedBox(width: 4),
                          Icon(
                            isActive
                                ? (isPlaying
                                    ? Icons.volume_up
                                    : Icons.play_arrow_rounded)
                                : Icons.play_arrow_outlined,
                            color: isActive
                                ? const Color(0xFFD4AF37)
                                : Colors.white24,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Arabic (Uthmani)
                  Text(
                    verse.textUthmani,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 24,
                      height: 1.8,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Amiri',
                      color: Colors.white,
                    ),
                  ),
                  if (showTranslation) ...[
                    const SizedBox(height: 12),
                    // Translation
                    Text(
                      verse.translationText,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  // Tafseer hint
                  Text(
                    'Long-press for tafseer',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.25),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Surah Header Card ────────────────────────────────────────────────────

  Widget _buildSurahHeaderCard(dynamic surah, BuildContext context) {
    final reciter = ref.watch(selectedReciterProvider);
    final reciterName = reciter?.name ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2B1D), Color(0xFF1B4D36)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            surah.name,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD4AF37),
              fontFamily: 'Amiri',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            surah.englishName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            surah.englishNameTranslation,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            width: 100,
            color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on_outlined,
                  size: 14,
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.8)),
              const SizedBox(width: 4),
              Text(
                surah.revelationType.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.format_list_numbered,
                  size: 14,
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.8)),
              const SizedBox(width: 4),
              Text(
                '${surah.numberOfAyahs} VERSES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          if (reciterName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.record_voice_over_rounded,
                    size: 14,
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                Text(
                  reciterName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBasmalaCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: const Center(
        child: Text(
          _kBasmala,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontSize: 24,
            fontFamily: 'Amiri',
            fontWeight: FontWeight.bold,
            color: Color(0xFFD4AF37),
          ),
        ),
      ),
    );
  }

  Widget _buildVerseNumber(int number, BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
                width: 1.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
                  width: 1.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Text(
          number.toString(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD4AF37),
          ),
        ),
      ],
    );
  }

  // ─── Player Panel ─────────────────────────────────────────────────────────

  Widget _buildPlayerPanel(
    BuildContext context,
    int activeIndex,
    int totalVerses,
    MediaPlaybackService mediaService,
    QuranAudioNotifier audioNotifier,
  ) {
    final reciter = ref.watch(selectedReciterProvider);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF071B11).withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verse ${activeIndex + 1} of $totalVerses',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (reciter != null)
                          Text(
                            reciter.name,
                            style: TextStyle(
                              color:
                                  const Color(0xFFD4AF37).withValues(alpha: 0.85),
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref
                            .read(dailyTargetProvider.notifier)
                            .incrementQuranPages(1);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text("Masha'Allah! Logged 1 page read."),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.menu_book, size: 14),
                      label: const Text('+1 Page',
                          style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: const Color(0xFF071B11),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StreamBuilder<Duration>(
                  stream: mediaService.positionStream,
                  builder: (ctx, positionSnapshot) {
                    final position = positionSnapshot.data ?? Duration.zero;
                    return StreamBuilder<Duration?>(
                      stream: mediaService.durationStream,
                      builder: (ctx, durationSnapshot) {
                        final duration =
                            durationSnapshot.data ?? Duration.zero;
                        final maxVal = duration.inMilliseconds > 0
                            ? duration.inMilliseconds.toDouble()
                            : 1.0;
                        final sliderValue = position.inMilliseconds
                            .toDouble()
                            .clamp(0.0, maxVal);
                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 5),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12),
                                activeTrackColor: const Color(0xFFD4AF37),
                                inactiveTrackColor: Colors.white12,
                                thumbColor: const Color(0xFFD4AF37),
                                overlayColor: const Color(0xFFD4AF37)
                                    .withValues(alpha: 0.2),
                              ),
                              child: Slider(
                                value: sliderValue,
                                min: 0.0,
                                max: maxVal,
                                onChanged: (value) {
                                  audioNotifier.seek(
                                      Duration(milliseconds: value.toInt()));
                                },
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: TextStyle(
                                        color: Colors.white.withValues(
                                            alpha: 0.5),
                                        fontSize: 11),
                                  ),
                                  Text(
                                    _formatDuration(duration),
                                    style: TextStyle(
                                        color: Colors.white.withValues(
                                            alpha: 0.5),
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                StreamBuilder<bool>(
                  stream: mediaService.playingStream,
                  builder: (ctx, playingSnapshot) {
                    final isPlaying = playingSnapshot.data ?? false;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            _autoScrollEnabled
                                ? Icons.unfold_more
                                : Icons.unfold_less,
                            color: _autoScrollEnabled
                                ? const Color(0xFFD4AF37)
                                : Colors.white54,
                          ),
                          tooltip: 'Toggle Auto-Scroll',
                          onPressed: () {
                            setState(() {
                              _autoScrollEnabled = !_autoScrollEnabled;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_previous,
                              size: 36, color: Colors.white),
                          onPressed: activeIndex > 0
                              ? () => audioNotifier.previousVerse()
                              : null,
                          color:
                              activeIndex > 0 ? Colors.white : Colors.white24,
                        ),
                        GestureDetector(
                          onTap: () =>
                              audioNotifier.togglePlayPause(isPlaying),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFFFD700),
                                  Color(0xFFD4AF37)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x44D4AF37),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                  offset: Offset(0, 3),
                                )
                              ],
                            ),
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 36,
                              color: const Color(0xFF0F2B1D),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next,
                              size: 36, color: Colors.white),
                          onPressed: activeIndex < totalVerses - 1
                              ? () => audioNotifier.nextVerse()
                              : null,
                          color: activeIndex < totalVerses - 1
                              ? Colors.white
                              : Colors.white24,
                        ),
                        IconButton(
                          icon: const Icon(Icons.book_outlined,
                              color: Colors.white54),
                          tooltip: 'Tafseer (long-press a verse)',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Long-press any verse to view tafseer'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}';
  }
}

// ─── Tafseer Bottom Sheet ─────────────────────────────────────────────────────

class _TafseerSheet extends ConsumerStatefulWidget {
  final String verseKey;
  const _TafseerSheet({required this.verseKey});

  @override
  ConsumerState<_TafseerSheet> createState() => _TafseerSheetState();
}

class _TafseerSheetState extends ConsumerState<_TafseerSheet> {
  String? _tafseerText;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTafseer();
  }

  Future<void> _loadTafseer() async {
    try {
      final tafsirId = ref.read(selectedTafsirIdProvider);
      final repo = ref.read(quranRepositoryProvider);
      final text = await repo.fetchTafsirForAyah(tafsirId, widget.verseKey);
      if (mounted) {
        setState(() {
          _tafseerText = text;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tafsirsAsync = ref.watch(tafsirListProvider);
    final selectedTafsirId = ref.watch(selectedTafsirIdProvider);

    final tafsirName = tafsirsAsync.whenOrNull(
          data: (tafsirs) {
            try {
              return tafsirs.firstWhere((t) => t.id == selectedTafsirId).name;
            } catch (_) {
              return 'Tafseer';
            }
          },
        ) ??
        'Tafseer';

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F2B1D),
              colorScheme.surface,
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.auto_stories_rounded,
                      color: Color(0xFFD4AF37), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tafsirName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                        Text(
                          'Verse ${widget.verseKey}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Change tafsir
                  TextButton(
                    onPressed: () =>
                        _showTafsirPicker(context, selectedTafsirId),
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFD4AF37)))
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 40),
                                const SizedBox(height: 12),
                                Text('Failed to load tafseer',
                                    style: TextStyle(
                                        color: colorScheme.onSurface)),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isLoading = true;
                                      _error = null;
                                    });
                                    _loadTafseer();
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            _tafseerText ?? '',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.7,
                              color: colorScheme.onSurface.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTafsirPicker(BuildContext context, int currentId) {
    final tafsirsAsync = ref.read(tafsirListProvider);
    tafsirsAsync.whenData((tafsirs) {
      showModalBottomSheet(
        context: context,
        builder: (ctx) => ListView.builder(
          itemCount: tafsirs.length,
          itemBuilder: (ctx, i) {
            final t = tafsirs[i];
            return ListTile(
              title: Text(t.name),
              subtitle: Text(t.authorName),
              trailing: t.id == currentId
                  ? const Icon(Icons.check_circle,
                      color: Color(0xFF1B4D36))
                  : null,
              onTap: () {
                ref.read(selectedTafsirIdProvider.notifier).state = t.id;
                Navigator.pop(ctx);
                // Reload tafseer with new selection
                setState(() {
                  _isLoading = true;
                  _tafseerText = null;
                  _error = null;
                });
                _loadTafseer();
              },
            );
          },
        ),
      );
    });
  }
}
