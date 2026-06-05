import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran/quran.dart' as quran;
import 'package:islamic_super_app/shared/services/media_playback_service.dart';
import 'package:islamic_super_app/modules/study/quran/data/models/surah_model.dart';

class CurrentSurahNotifier extends Notifier<SurahModel?> {
  @override
  SurahModel? build() => null;

  void setSurah(SurahModel surah) => state = surah;
}

final currentSurahProvider = NotifierProvider<CurrentSurahNotifier, SurahModel?>(CurrentSurahNotifier.new);

final quranAudioProvider = Provider<QuranAudioNotifier>((ref) {
  final mediaService = ref.watch(mediaPlaybackServiceProvider);
  return QuranAudioNotifier(mediaService, ref);
});

class QuranAudioNotifier {
  final MediaPlaybackService _mediaService;
  final Ref _ref;

  QuranAudioNotifier(this._mediaService, this._ref);

  Future<void> playSurah(SurahModel surah, {int startVerseIndex = 0}) async {
    _ref.read(currentSurahProvider.notifier).setSurah(surah);
    final totalVerses = quran.getVerseCount(surah.number);
    final urls = List.generate(
      totalVerses,
      (index) => quran.getAudioURLByVerse(surah.number, index + 1),
    );
    await _mediaService.playPlaylist(urls, initialIndex: startVerseIndex);
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
