import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:islamic_super_app/shared/services/media_playback_service.dart';
import 'package:islamic_super_app/modules/study/quran/data/models/surah_model.dart';
import 'package:islamic_super_app/modules/study/quran/data/services/quran_download_service.dart';
import 'package:islamic_super_app/modules/study/quran/presentation/providers/quran_list_provider.dart';

// ─── Current Surah State ──────────────────────────────────────────────────────

class CurrentSurahNotifier extends Notifier<SurahModel?> {
  @override
  SurahModel? build() => null;

  void setSurah(SurahModel surah) => state = surah;
}

final currentSurahProvider =
    NotifierProvider<CurrentSurahNotifier, SurahModel?>(
        CurrentSurahNotifier.new);

// ─── Audio Download Progress State ───────────────────────────────────────────

/// Tracks the current audio download progress (null when not downloading).
class AudioDownloadProgressNotifier extends Notifier<DownloadProgress?> {
  @override
  DownloadProgress? build() => null;

  void update(DownloadProgress? progress) => state = progress;
}

final audioDownloadProgressProvider =
    NotifierProvider<AudioDownloadProgressNotifier, DownloadProgress?>(
        AudioDownloadProgressNotifier.new);

// ─── Audio Provider ───────────────────────────────────────────────────────────

final quranAudioProvider = Provider<QuranAudioNotifier>((ref) {
  final mediaService = ref.watch(mediaPlaybackServiceProvider);
  return QuranAudioNotifier(mediaService, ref);
});

class QuranAudioNotifier {
  final MediaPlaybackService _mediaService;
  final Ref _ref;

  QuranAudioNotifier(this._mediaService, this._ref);

  /// Plays a surah using the selected reciter. Downloads audio files to local
  /// storage before playback so subsequent plays are fully offline.
  Future<void> playSurah(SurahModel surah, {int startVerseIndex = 0}) async {
    _ref.read(currentSurahProvider.notifier).setSurah(surah);

    final downloadService = _ref.read(quranDownloadServiceProvider);
    final reciter = _ref.read(selectedReciterProvider);

    // Resolve subfolder — fall back to Alafasy if reciter list not loaded yet
    final subfolder =
        reciter?.subfolder.isNotEmpty == true ? reciter!.subfolder : 'Alafasy_128kbps';

    final verseCount = surah.numberOfAyahs;
    final progressNotifier =
        _ref.read(audioDownloadProgressProvider.notifier);

    // Build playlist — downloading each file if needed
    final audioSources = <AudioSource>[];

    for (int i = 1; i <= verseCount; i++) {
      progressNotifier.update(DownloadProgress(
        completed: i - 1,
        total: verseCount,
        label: 'Preparing ${surah.englishName} — $i/$verseCount',
      ));

      final localPath = await downloadService.ensureAudioFile(
        subfolder,
        surah.number,
        i,
      );

      final source = localPath.startsWith('http')
          ? AudioSource.uri(Uri.parse(localPath))
          : AudioSource.file(localPath);

      audioSources.add(source);
    }

    progressNotifier.update(null); // Clear progress banner

    final playlist = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: audioSources,
    );

    try {
      await _mediaService.player
          .setAudioSource(playlist, initialIndex: startVerseIndex);
      await _mediaService.player.play();
    } catch (e) {
      debugPrint('QuranAudio: playback error — $e');
    }
  }

  Future<void> togglePlayPause(bool isPlaying) async {
    if (isPlaying) {
      await _mediaService.pause();
    } else {
      await _mediaService.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _mediaService.seek(position);
  }

  Future<void> playVerse(int verseIndex) async {
    await _mediaService.seekToIndex(verseIndex);
  }

  Future<void> nextVerse() async {
    await _mediaService.next();
  }

  Future<void> previousVerse() async {
    await _mediaService.previous();
  }
}
