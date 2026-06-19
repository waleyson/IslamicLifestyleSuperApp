import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:islamic_super_app/modules/study/quran/data/models/surah_model.dart';
import 'package:islamic_super_app/modules/study/quran/data/models/quran_verse_model.dart';
import 'package:islamic_super_app/modules/study/quran/data/models/reciter_model.dart';
import 'package:islamic_super_app/modules/study/quran/data/models/translation_model.dart';
import 'package:islamic_super_app/modules/study/quran/data/models/tafsir_model.dart';
import 'package:islamic_super_app/modules/study/quran/data/repositories/quran_repository.dart';
import 'package:islamic_super_app/modules/study/quran/data/services/quran_download_service.dart';

// ─── Repository & Services ────────────────────────────────────────────────────

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return QuranRepository();
});

final quranDownloadServiceProvider = Provider<QuranDownloadService>((ref) {
  return QuranDownloadService();
});

// ─── Selection State ──────────────────────────────────────────────────────────

class SelectedReciterIdNotifier extends Notifier<int> {
  @override
  int build() => 7;
  @override
  set state(int value) => super.state = value;
}

/// Default: Mishary Alafasy (ID 7)
final selectedReciterIdProvider = NotifierProvider<SelectedReciterIdNotifier, int>(
  SelectedReciterIdNotifier.new,
);

class SelectedTranslationIdNotifier extends Notifier<int> {
  @override
  int build() => 203;
  @override
  set state(int value) => super.state = value;
}

/// Default: Al-Hilali & Khan — King Fahd Complex English (ID 203)
final selectedTranslationIdProvider = NotifierProvider<SelectedTranslationIdNotifier, int>(
  SelectedTranslationIdNotifier.new,
);

class SelectedTafsirIdNotifier extends Notifier<int> {
  @override
  int build() => 169;
  @override
  set state(int value) => super.state = value;
}

/// Default: Ibn Kathir (ID 169)
final selectedTafsirIdProvider = NotifierProvider<SelectedTafsirIdNotifier, int>(
  SelectedTafsirIdNotifier.new,
);

class ShowTranslationNotifier extends Notifier<bool> {
  static const _prefKey = 'show_translation_preference';

  @override
  bool build() {
    final box = Hive.box('daily_targets_box');
    return box.get(_prefKey, defaultValue: true) as bool;
  }

  Future<void> toggle(bool value) async {
    final box = Hive.box('daily_targets_box');
    await box.put(_prefKey, value);
    state = value;
  }
}

final showTranslationProvider = NotifierProvider<ShowTranslationNotifier, bool>(
  ShowTranslationNotifier.new,
);

// ─── Resource Lists ───────────────────────────────────────────────────────────

final reciterListProvider = FutureProvider<List<ReciterModel>>((ref) async {
  final repo = ref.read(quranRepositoryProvider);
  return repo.fetchReciters();
});

final translationListProvider =
    FutureProvider<List<TranslationModel>>((ref) async {
  final repo = ref.read(quranRepositoryProvider);
  return repo.fetchTranslations();
});

final tafsirListProvider = FutureProvider<List<TafsirModel>>((ref) async {
  final repo = ref.read(quranRepositoryProvider);
  return repo.fetchTafsirs();
});

// ─── Surah List ───────────────────────────────────────────────────────────────

final quranListProvider =
    AsyncNotifierProvider<QuranListNotifier, List<SurahModel>>(
  QuranListNotifier.new,
);

class QuranListNotifier extends AsyncNotifier<List<SurahModel>> {
  @override
  Future<List<SurahModel>> build() async {
    final repo = ref.read(quranRepositoryProvider);
    return repo.fetchAllSurahs();
  }
}

// ─── Verses (with cache-first strategy) ──────────────────────────────────────

/// Fetches verses for a surah, checking the local Hive cache first.
/// Re-fetches when the selected translation changes.
final quranVersesProvider =
    FutureProvider.family<List<QuranVerseModel>, int>((ref, surahNum) async {
  final translationId = ref.watch(selectedTranslationIdProvider);
  final downloadService = ref.read(quranDownloadServiceProvider);
  final repo = ref.read(quranRepositoryProvider);

  // Check Hive cache first
  final cached = downloadService.getCachedVerses(surahNum, translationId);
  if (cached != null && cached.isNotEmpty) return cached;

  // Fetch from API and cache the result
  final verses = await repo.fetchVerses(surahNum, translationId: translationId);
  await downloadService.cacheVerses(surahNum, translationId, verses);
  return verses;
});

// ─── Resolved Reciter ─────────────────────────────────────────────────────────

/// Returns the currently selected ReciterModel (null while loading).
final selectedReciterProvider = Provider<ReciterModel?>((ref) {
  final id = ref.watch(selectedReciterIdProvider);
  final recitersAsync = ref.watch(reciterListProvider);
  return recitersAsync.whenOrNull(
    data: (reciters) {
      try {
        return reciters.firstWhere((r) => r.id == id);
      } catch (_) {
        return reciters.isNotEmpty ? reciters.first : null;
      }
    },
  );
});
