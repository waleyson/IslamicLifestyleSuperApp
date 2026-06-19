import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/quran_verse_model.dart';

/// Granularity options for what a user wishes to download.
enum DownloadScope { surah, juz, fullQuran }

/// Reported during a batch download operation.
class DownloadProgress {
  final int completed;
  final int total;
  final String label;
  final bool isDone;
  final String? error;

  const DownloadProgress({
    required this.completed,
    required this.total,
    required this.label,
    this.isDone = false,
    this.error,
  });

  double get fraction => total == 0 ? 0.0 : completed / total;
}

/// Mapping of Juz number (1–30) to the list of (surahNumber, startAyah, endAyah) triplets.
/// Source: standard Quran juz division.
const Map<int, List<List<int>>> kJuzSurahRanges = {
  1: [[1, 1, 7], [2, 1, 141]],
  2: [[2, 142, 252]],
  3: [[2, 253, 286], [3, 1, 92]],
  4: [[3, 93, 200], [4, 1, 23]],
  5: [[4, 24, 147]],
  6: [[4, 148, 176], [5, 1, 81]],
  7: [[5, 82, 120], [6, 1, 110]],
  8: [[6, 111, 165], [7, 1, 87]],
  9: [[7, 88, 206], [8, 1, 40]],
  10: [[8, 41, 75], [9, 1, 92]],
  11: [[9, 93, 129], [10, 1, 109], [11, 1, 5]],
  12: [[11, 6, 123], [12, 1, 52]],
  13: [[12, 53, 111], [13, 1, 43], [14, 1, 52], [15, 1, 1]],
  14: [[15, 1, 99], [16, 1, 128]],
  15: [[17, 1, 111], [18, 1, 74]],
  16: [[18, 75, 110], [19, 1, 98], [20, 1, 135], [21, 1, 112]],
  17: [[21, 1, 112], [22, 1, 78]],
  18: [[23, 1, 118], [24, 1, 64]],
  19: [[25, 1, 77], [26, 1, 227], [27, 1, 55]],
  20: [[27, 56, 93], [28, 1, 85]],
  21: [[29, 1, 69], [30, 1, 60]],
  22: [[31, 1, 34], [32, 1, 30], [33, 1, 73]],
  23: [[36, 1, 83], [37, 1, 182], [38, 1, 88]],
  24: [[39, 1, 75], [40, 1, 85]],
  25: [[41, 1, 54], [42, 1, 53], [43, 1, 89], [44, 1, 59], [45, 1, 37]],
  26: [[46, 1, 35], [47, 1, 38], [48, 1, 29], [49, 1, 18], [50, 1, 45], [51, 1, 30]],
  27: [[51, 31, 60], [52, 1, 49], [53, 1, 62], [54, 1, 55], [55, 1, 78], [56, 1, 96], [57, 1, 29]],
  28: [[58, 1, 22], [59, 1, 24], [60, 1, 13], [61, 1, 14], [62, 1, 11], [63, 1, 11], [64, 1, 18], [65, 1, 12], [66, 1, 12]],
  29: [[67, 1, 30], [68, 1, 52], [69, 1, 52], [70, 1, 44], [71, 1, 28], [72, 1, 28], [73, 1, 20], [74, 1, 56], [75, 1, 40], [76, 1, 31]],
  30: [[78, 1, 40], [79, 1, 46], [80, 1, 42], [81, 1, 29], [82, 1, 19], [83, 1, 36], [84, 1, 25], [85, 1, 22], [86, 1, 17], [87, 1, 19], [88, 1, 26], [89, 1, 30], [90, 1, 20], [91, 1, 15], [92, 1, 21], [93, 1, 11], [94, 1, 8], [95, 1, 8], [96, 1, 19], [97, 1, 5], [98, 1, 8], [99, 1, 8], [100, 1, 11], [101, 1, 11], [102, 1, 8], [103, 1, 3], [104, 1, 9], [105, 1, 5], [106, 1, 4], [107, 1, 7], [108, 1, 3], [109, 1, 6], [110, 1, 3], [111, 1, 5], [112, 1, 4], [113, 1, 5], [114, 1, 6]],
};

class QuranDownloadService {
  static const _cacheBoxName = 'quran_cache_box';
  static const _audioSubdir = 'quran_audio';

  final Dio _dio;

  QuranDownloadService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 60),
              ),
            );

  // ─── Text / Verse Cache (Hive) ─────────────────────────────────────────────

  Box<String> get _box => Hive.box<String>(_cacheBoxName);

  String _versesCacheKey(int surahNum, int translationId) =>
      'verses_${surahNum}_$translationId';

  /// Persists a list of verses to Hive for the given surah + translation.
  Future<void> cacheVerses(
      int surahNum, int translationId, List<QuranVerseModel> verses) async {
    final key = _versesCacheKey(surahNum, translationId);
    final encoded = jsonEncode(verses.map((v) => v.toJson()).toList());
    await _box.put(key, encoded);
  }

  /// Returns cached verses or null if not yet stored.
  List<QuranVerseModel>? getCachedVerses(int surahNum, int translationId) {
    final key = _versesCacheKey(surahNum, translationId);
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) =>
              QuranVerseModel.fromCacheJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // ─── Audio File Management ─────────────────────────────────────────────────

  Future<Directory> _audioDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_audioSubdir');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  String _audioFilename(String subfolder, int surahNum, int ayahNum) {
    final s = surahNum.toString().padLeft(3, '0');
    final a = ayahNum.toString().padLeft(3, '0');
    return '$subfolder/$s/$a.mp3';
  }

  Future<String> _localAudioPath(
      String subfolder, int surahNum, int ayahNum) async {
    final base = await _audioDir();
    return '${base.path}/${_audioFilename(subfolder, surahNum, ayahNum)}';
  }

  /// Returns true if the audio file for this verse is already on disk.
  Future<bool> isAudioCached(
      String subfolder, int surahNum, int ayahNum) async {
    final path = await _localAudioPath(subfolder, surahNum, ayahNum);
    return File(path).existsSync();
  }

  /// Builds the CDN URL for a given reciter subfolder + verse.
  String cdnUrl(String subfolder, int surahNum, int ayahNum) {
    final s = surahNum.toString().padLeft(3, '0');
    final a = ayahNum.toString().padLeft(3, '0');
    return 'https://verses.quran.com/$subfolder/$s/$a.mp3';
  }

  /// Downloads the audio file if not already cached and returns the local path.
  /// This is called per-verse when building the playback playlist.
  Future<String> ensureAudioFile(
      String subfolder, int surahNum, int ayahNum) async {
    final localPath = await _localAudioPath(subfolder, surahNum, ayahNum);
    final file = File(localPath);
    if (file.existsSync()) return localPath;

    // Ensure parent directory exists
    await file.parent.create(recursive: true);

    final url = cdnUrl(subfolder, surahNum, ayahNum);
    try {
      await _dio.download(url, localPath);
    } catch (e) {
      debugPrint('QuranDownload: Failed to download $url — $e');
      // Return CDN URL as fallback so playback isn't blocked
      return url;
    }
    return localPath;
  }

  /// Returns the set of fully downloaded surah numbers for a given reciter subfolder.
  /// A surah is considered downloaded if its folder is non-empty.
  Future<Set<int>> downloadedSurahs(String subfolder) async {
    final base = await _audioDir();
    final result = <int>{};
    final subfolderDir = Directory('${base.path}/$subfolder');
    if (!subfolderDir.existsSync()) return result;
    await for (final entity in subfolderDir.list()) {
      if (entity is Directory) {
        final name = entity.uri.pathSegments
            .lastWhere((s) => s.isNotEmpty, orElse: () => '');
        final num = int.tryParse(name);
        if (num != null) result.add(num);
      }
    }
    return result;
  }

  /// Calculates the total size in bytes of all cached audio for a subfolder+surah.
  Future<int> audioSizeBytes(String subfolder, int surahNum) async {
    final base = await _audioDir();
    final s = surahNum.toString().padLeft(3, '0');
    final dir = Directory('${base.path}/$subfolder/$s');
    if (!dir.existsSync()) return 0;
    int total = 0;
    await for (final f in dir.list()) {
      if (f is File) total += await f.length();
    }
    return total;
  }

  /// Deletes all cached audio files for a specific surah.
  Future<void> deleteAudioForSurah(String subfolder, int surahNum) async {
    final base = await _audioDir();
    final s = surahNum.toString().padLeft(3, '0');
    final dir = Directory('${base.path}/$subfolder/$s');
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  /// Deletes all audio files for a specific reciter.
  Future<void> deleteAllAudio(String subfolder) async {
    final base = await _audioDir();
    final dir = Directory('${base.path}/$subfolder');
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  // ─── Batch Download Streams ────────────────────────────────────────────────

  /// Downloads all audio for a single surah and streams progress.
  Stream<DownloadProgress> downloadSurah(
    String reciterSubfolder,
    int surahNum,
    int verseCount,
  ) async* {
    for (int ayah = 1; ayah <= verseCount; ayah++) {
      final label =
          'Surah $surahNum — $ayah/$verseCount';
      yield DownloadProgress(
          completed: ayah - 1, total: verseCount, label: label);
      await ensureAudioFile(reciterSubfolder, surahNum, ayah);
      yield DownloadProgress(
          completed: ayah,
          total: verseCount,
          label: label,
          isDone: ayah == verseCount);
    }
  }

  /// Downloads all audio for a Juz and streams progress.
  Stream<DownloadProgress> downloadJuz(
    String reciterSubfolder,
    int juzNumber,
    Map<int, int> surahVerseCounts, // surahNum → verseCount
  ) async* {
    final ranges = kJuzSurahRanges[juzNumber] ?? [];
    // Build flat list of (surahNum, ayah) pairs in the Juz
    final verses = <List<int>>[];
    for (final range in ranges) {
      final surahNum = range[0];
      final start = range[1];
      final end = range[2];
      for (int ayah = start; ayah <= end; ayah++) {
        verses.add([surahNum, ayah]);
      }
    }

    final total = verses.length;
    for (int i = 0; i < verses.length; i++) {
      final surah = verses[i][0];
      final ayah = verses[i][1];
      yield DownloadProgress(
          completed: i, total: total, label: 'Juz $juzNumber — ${i + 1}/$total');
      await ensureAudioFile(reciterSubfolder, surah, ayah);
      yield DownloadProgress(
          completed: i + 1,
          total: total,
          label: 'Juz $juzNumber — ${i + 1}/$total',
          isDone: i == total - 1);
    }
  }

  /// Downloads the entire Quran (all 6236 verses) and streams progress.
  Stream<DownloadProgress> downloadFullQuran(
    String reciterSubfolder,
    Map<int, int> surahVerseCounts, // surahNum → verseCount (114 entries)
  ) async* {
    final total =
        surahVerseCounts.values.fold<int>(0, (sum, c) => sum + c);
    int done = 0;
    for (int surah = 1; surah <= 114; surah++) {
      final count = surahVerseCounts[surah] ?? 0;
      for (int ayah = 1; ayah <= count; ayah++) {
        yield DownloadProgress(
            completed: done,
            total: total,
            label: 'Quran — Surah $surah:$ayah');
        await ensureAudioFile(reciterSubfolder, surah, ayah);
        done++;
        yield DownloadProgress(
            completed: done,
            total: total,
            label: 'Quran — Surah $surah:$ayah',
            isDone: done == total);
      }
    }
  }
}
