import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:islamic_super_app/modules/study/quran/data/models/surah_model.dart';
import 'package:islamic_super_app/modules/study/quran/data/repositories/quran_repository.dart';

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return QuranRepository();
});

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
