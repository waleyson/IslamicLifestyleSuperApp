import 'package:dio/dio.dart';
import '../models/surah_model.dart';
import '../models/quran_verse_model.dart';
import '../models/reciter_model.dart';
import '../models/translation_model.dart';
import '../models/tafsir_model.dart';

class QuranRepository {
  final Dio _dio;

  QuranRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.qurancdn.com/api/qdc',
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
              ),
            );

  // ─── Surahs ────────────────────────────────────────────────────────────────

  /// Fetches metadata for all 114 Surahs from the QuranCDN API.
  Future<List<SurahModel>> fetchAllSurahs() async {
    final response = await _dio.get('/chapters', queryParameters: {
      'language': 'en',
    });
    final data = response.data['chapters'] as List<dynamic>;
    return data
        .map((json) => SurahModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ─── Verses ────────────────────────────────────────────────────────────────

  /// Fetches all verses for a chapter with Arabic (Uthmani) text and a translation.
  Future<List<QuranVerseModel>> fetchVerses(
    int surahNumber, {
    int translationId = 203,
  }) async {
    final response = await _dio.get(
      '/verses/by_chapter/$surahNumber',
      queryParameters: {
        'translations': translationId,
        'per_page': 286,
        'fields': 'text_uthmani,verse_key,verse_number',
      },
    );
    final verses = response.data['verses'] as List<dynamic>;
    return verses
        .map((json) =>
            QuranVerseModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ─── Resources ─────────────────────────────────────────────────────────────

  /// Fetches all available translations (filtered by language).
  Future<List<TranslationModel>> fetchTranslations({
    String language = 'en',
  }) async {
    final response = await _dio.get(
      '/resources/translations',
      queryParameters: {'language': language},
    );
    final data = response.data['translations'] as List<dynamic>;
    return data
        .map((json) =>
            TranslationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetches all available tafsirs (filtered by language).
  Future<List<TafsirModel>> fetchTafsirs({String language = 'en'}) async {
    final response = await _dio.get(
      '/resources/tafsirs',
      queryParameters: {'language': language},
    );
    final data = response.data['tafsirs'] as List<dynamic>;
    return data
        .map((json) => TafsirModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetches tafseer text for a single ayah.
  /// [ayahKey] format: "1:1" (surah:ayah).
  Future<String> fetchTafsirForAyah(int tafsirId, String ayahKey) async {
    final response =
        await _dio.get('/tafsirs/$tafsirId/by_ayah/$ayahKey');
    final tafsir = response.data['tafsir'] as Map<String, dynamic>?;
    final rawText = tafsir?['text'] as String? ?? '';
    // Strip HTML tags that QuranCDN sometimes includes
    return rawText.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  // ─── Reciters ──────────────────────────────────────────────────────────────

  /// Fetches all available reciters with their audio subfolder info.
  Future<List<ReciterModel>> fetchReciters() async {
    final response = await _dio.get(
      '/audio/reciters',
      queryParameters: {'locale': 'en'},
    );
    final data = response.data['reciters'] as List<dynamic>;
    return data
        .map((json) =>
            ReciterModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a single Ayah with text and audio URL.
  Future<Map<String, dynamic>> fetchAyah(
    int surahNumber,
    int ayahNumber, {
    int translationId = 203,
    String reciterSubfolder = 'Alafasy_128kbps',
  }) async {
    final response = await _dio.get(
      '/verses/by_key/$surahNumber:$ayahNumber',
      queryParameters: {
        'translations': translationId,
        'fields': 'text_uthmani,verse_key,verse_number',
      },
    );
    final verse = response.data['verse'] as Map<String, dynamic>;
    final model = QuranVerseModel.fromJson(verse);
    final s = surahNumber.toString().padLeft(3, '0');
    final a = ayahNumber.toString().padLeft(3, '0');
    final audioUrl = 'https://verses.quran.com/$reciterSubfolder/$s/$a.mp3';
    return {
      'text': '${model.textUthmani}\n\n${model.translationText}',
      'audio': audioUrl,
    };
  }
}
