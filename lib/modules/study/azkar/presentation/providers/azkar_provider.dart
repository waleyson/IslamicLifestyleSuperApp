import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';
import 'package:islamic_super_app/modules/study/azkar/data/repositories/azkar_repository.dart';

final azkarRepositoryProvider = Provider<AzkarRepository>((ref) {
  return AzkarRepository();
});

/// Fetches and caches the list of Hisnul Muslim categories (e.g. Travel, Morning & Evening)
final azkarCategoriesProvider =
    AsyncNotifierProvider<AzkarCategoriesNotifier, List<AzkarCategory>>(
  AzkarCategoriesNotifier.new,
);

class AzkarCategoriesNotifier extends AsyncNotifier<List<AzkarCategory>> {
  @override
  Future<List<AzkarCategory>> build() async {
    final repo = ref.read(azkarRepositoryProvider);
    return repo.fetchCategories();
  }
}

/// Fetches chapters within a given category ID (e.g., specific supplications in Travel)
final azkarChaptersProvider =
    FutureProvider.family<List<AzkarChapter>, int>((ref, categoryId) async {
  final repo = ref.read(azkarRepositoryProvider);
  return repo.fetchChapters(categoryId);
});

/// Fetches supplication details (Arabic, English, reference) within a chapter ID
final azkarItemsProvider =
    FutureProvider.family<List<AzkarItem>, int>((ref, chapterId) async {
  final repo = ref.read(azkarRepositoryProvider);
  return repo.fetchItems(chapterId);
});
