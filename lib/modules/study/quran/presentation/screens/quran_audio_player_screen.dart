import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran/quran.dart' as quran;
import 'package:islamic_super_app/modules/study/quran/presentation/providers/quran_audio_provider.dart';
import 'package:islamic_super_app/shared/services/media_playback_service.dart';

class QuranAudioPlayerScreen extends ConsumerStatefulWidget {
  const QuranAudioPlayerScreen({super.key});

  @override
  ConsumerState<QuranAudioPlayerScreen> createState() => _QuranAudioPlayerScreenState();
}

class _QuranAudioPlayerScreenState extends ConsumerState<QuranAudioPlayerScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = {};
  bool _autoScrollEnabled = true;
  int _lastActiveIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _estimateVerseHeight(int index, int surahNumber) {
    final arabicText = quran.getVerse(surahNumber, index + 1);
    final translationText = quran.getVerseTranslation(surahNumber, index + 1);
    final arabicLines = (arabicText.length / 30).ceil();
    final translationLines = (translationText.length / 45).ceil();
    return 60.0 + (arabicLines * 32.0) + (translationLines * 18.0) + 24.0;
  }

  void _scrollToActiveVerse(int index, int surahNumber) {
    if (!_autoScrollEnabled || index < 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _verseKeys[index];
      final context = key?.currentContext;

      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.2,
        );
      } else {
        double offset = 0;
        offset += 240.0; // Estimated height of header card with margins

        final hasBasmala = surahNumber != 1 && surahNumber != 9;
        if (hasBasmala) {
          offset += 90.0; // Estimated height of Basmala card with margins
        }

        for (int i = 0; i < index; i++) {
          offset += _estimateVerseHeight(i, surahNumber);
        }

        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            offset.clamp(0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final surah = ref.watch(currentSurahProvider);
    final mediaService = ref.watch(mediaPlaybackServiceProvider);
    final audioNotifier = ref.read(quranAudioProvider);

    if (surah == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player')),
        body: const Center(child: Text('No Surah selected')),
      );
    }

    final totalVerses = quran.getVerseCount(surah.number);
    final hasBasmala = surah.number != 1 && surah.number != 9;
    final totalListItems = 1 + (hasBasmala ? 1 : 0) + totalVerses;

    return StreamBuilder<int?>(
      stream: mediaService.currentIndexStream,
      builder: (context, indexSnapshot) {
        final activeIndex = indexSnapshot.data ?? 0;

        if (activeIndex != _lastActiveIndex) {
          _lastActiveIndex = activeIndex;
          _scrollToActiveVerse(activeIndex, surah.number);
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, size: 32, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _autoScrollEnabled ? Icons.sync : Icons.sync_disabled,
                  color: _autoScrollEnabled ? const Color(0xFFD4AF37) : Colors.white54,
                ),
                tooltip: 'Toggle Auto-Scroll',
                onPressed: () {
                  setState(() {
                    _autoScrollEnabled = !_autoScrollEnabled;
                  });
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0A1E14),
                  Theme.of(context).colorScheme.primary,
                  Colors.black,
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  // Verse List
                  Positioned.fill(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(
                        top: 8,
                        left: 8,
                        right: 8,
                        bottom: 220, // Leave enough space for bottom panel
                      ),
                      itemCount: totalListItems,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildSurahHeaderCard(surah, context);
                        }

                        if (hasBasmala && index == 1) {
                          return _buildBasmalaCard();
                        }

                        // It's a verse
                        final verseIndex = hasBasmala ? index - 2 : index - 1;
                        final verseNumber = verseIndex + 1;
                        final isActive = verseIndex == activeIndex;
                        final key = _verseKeys.putIfAbsent(verseIndex, () => GlobalKey());

                        final arabicText = quran.getVerse(surah.number, verseNumber);
                        final translationText = quran.getVerseTranslation(surah.number, verseNumber);

                        return StreamBuilder<bool>(
                          stream: mediaService.playingStream,
                          builder: (context, playingSnapshot) {
                            final isPlaying = playingSnapshot.data ?? false;

                            return Container(
                              key: key,
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF0F2B1D).withValues(alpha: 0.4)
                                    : Colors.white.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(16),
                                border: Border(
                                  left: BorderSide(
                                    color: isActive ? const Color(0xFFD4AF37) : Colors.transparent,
                                    width: 4,
                                  ),
                                  right: BorderSide(
                                    color: isActive ? const Color(0xFFD4AF37).withValues(alpha: 0.2) : Colors.transparent,
                                    width: 1,
                                  ),
                                  top: BorderSide(
                                    color: isActive ? const Color(0xFFD4AF37).withValues(alpha: 0.2) : Colors.transparent,
                                    width: 1,
                                  ),
                                  bottom: BorderSide(
                                    color: isActive ? const Color(0xFFD4AF37).withValues(alpha: 0.2) : Colors.transparent,
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
                                  onTap: () {
                                    audioNotifier.playVerse(verseIndex);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            _buildVerseNumber(verseNumber, context),
                                            Icon(
                                              isActive
                                                  ? (isPlaying ? Icons.volume_up : Icons.play_arrow_rounded)
                                                  : Icons.play_arrow_outlined,
                                              color: isActive ? const Color(0xFFD4AF37) : Colors.white24,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          arabicText,
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
                                        const SizedBox(height: 12),
                                        Text(
                                          translationText,
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            fontSize: 14,
                                            height: 1.4,
                                            color: Colors.white.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // Floating bottom player panel
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildPlayerPanel(
                      context,
                      activeIndex,
                      totalVerses,
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

  Widget _buildSurahHeaderCard(dynamic surah, BuildContext context) {
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
              Icon(Icons.location_on_outlined, size: 14, color: const Color(0xFFD4AF37).withValues(alpha: 0.8)),
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
              Icon(Icons.format_list_numbered, size: 14, color: const Color(0xFFD4AF37).withValues(alpha: 0.8)),
              const SizedBox(width: 4),
              Text(
                "${surah.numberOfAyahs} VERSES",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
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
          quran.basmala,
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
        Transform.rotate(
          angle: 0,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.8), width: 1.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Transform.rotate(
          angle: 0.785398, // 45 degrees
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.8), width: 1.2),
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

  Widget _buildPlayerPanel(
    BuildContext context,
    int activeIndex,
    int totalVerses,
    MediaPlaybackService mediaService,
    QuranAudioNotifier audioNotifier,
  ) {
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
                    Text(
                      "Verse ${activeIndex + 1} of $totalVerses",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.sync,
                          size: 14,
                          color: _autoScrollEnabled ? const Color(0xFFD4AF37) : Colors.white30,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _autoScrollEnabled ? "Auto-Scroll On" : "Auto-Scroll Off",
                          style: TextStyle(
                            color: _autoScrollEnabled ? const Color(0xFFD4AF37) : Colors.white30,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StreamBuilder<Duration>(
                  stream: mediaService.positionStream,
                  builder: (context, positionSnapshot) {
                    final position = positionSnapshot.data ?? Duration.zero;
                    return StreamBuilder<Duration?>(
                      stream: mediaService.durationStream,
                      builder: (context, durationSnapshot) {
                        final duration = durationSnapshot.data ?? Duration.zero;
                        final maxVal = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
                        final sliderValue = position.inMilliseconds.toDouble().clamp(0.0, maxVal);
                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                activeTrackColor: const Color(0xFFD4AF37),
                                inactiveTrackColor: Colors.white12,
                                thumbColor: const Color(0xFFD4AF37),
                                overlayColor: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                              ),
                              child: Slider(
                                value: sliderValue,
                                min: 0.0,
                                max: maxVal,
                                onChanged: (value) {
                                  audioNotifier.seek(Duration(milliseconds: value.toInt()));
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                                  ),
                                  Text(
                                    _formatDuration(duration),
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
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
                  builder: (context, playingSnapshot) {
                    final isPlaying = playingSnapshot.data ?? false;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            _autoScrollEnabled ? Icons.unfold_more : Icons.unfold_less,
                            color: _autoScrollEnabled ? const Color(0xFFD4AF37) : Colors.white54,
                          ),
                          tooltip: 'Toggle Auto-Scroll',
                          onPressed: () {
                            setState(() {
                              _autoScrollEnabled = !_autoScrollEnabled;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_previous, size: 36, color: Colors.white),
                          onPressed: activeIndex > 0 ? () => audioNotifier.previousVerse() : null,
                          color: activeIndex > 0 ? Colors.white : Colors.white24,
                        ),
                        GestureDetector(
                          onTap: () => audioNotifier.togglePlayPause(isPlaying),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFD4AF37)],
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
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 36,
                              color: const Color(0xFF0F2B1D),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next, size: 36, color: Colors.white),
                          onPressed: activeIndex < totalVerses - 1 ? () => audioNotifier.nextVerse() : null,
                          color: activeIndex < totalVerses - 1 ? Colors.white : Colors.white24,
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline, color: Colors.white54),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Audio stream is recited by Mishary Rashid Alafasy'),
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
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
