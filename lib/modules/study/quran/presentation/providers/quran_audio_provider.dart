import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/services/media_playback_service.dart';
import '../../data/models/surah_model.dart';

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

  Future<void> playSurah(SurahModel surah) async {
    _ref.read(currentSurahProvider.notifier).setSurah(surah);
    await _mediaService.playAudioFromUrl(surah.audioUrl);
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

  Future<void> skipForward() async {
    // Skipping 10 seconds logic requires knowing current position, handled in UI or here
  }
}
