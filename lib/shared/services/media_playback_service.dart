import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mediaPlaybackServiceProvider = Provider<MediaPlaybackService>((ref) {
  return MediaPlaybackService();
});

class MediaPlaybackService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  AudioPlayer get player => _audioPlayer;

  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<bool> get playingStream => _audioPlayer.playingStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<int?> get currentIndexStream => _audioPlayer.currentIndexStream;

  Future<void> playAudioFromUrl(String url) async {
    try {
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  Future<void> playPlaylist(List<String> urls, {int initialIndex = 0}) async {
    try {
      // ignore: deprecated_member_use
      final playlist = ConcatenatingAudioSource(
        useLazyPreparation: true,
        children: urls.map((url) => AudioSource.uri(Uri.parse(url))).toList(),
      );
      await _audioPlayer.setAudioSource(playlist, initialIndex: initialIndex);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint("Error playing playlist: $e");
    }
  }

  Future<void> playAudioFromAsset(String assetPath) async {
    try {
      await _audioPlayer.setAsset(assetPath);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint("Error playing asset: $e");
    }
  }

  Future<void> play() async {
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }
  
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> seekToIndex(int index, {Duration position = Duration.zero}) async {
    try {
      await _audioPlayer.seek(position, index: index);
    } catch (e) {
      debugPrint("Error seeking to index: $e");
    }
  }

  Future<void> next() async {
    if (_audioPlayer.hasNext) {
      await _audioPlayer.seekToNext();
    }
  }

  Future<void> previous() async {
    if (_audioPlayer.hasPrevious) {
      await _audioPlayer.seekToPrevious();
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
