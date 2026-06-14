import 'package:muslim_data_flutter/muslim_data_flutter.dart';

class AzkarRepository {
  final MuslimRepository _muslimRepo = MuslimRepository();

  /// Fetches all available Azkar categories (e.g. Morning & Evening, Travel, Prayer)
  Future<List<AzkarCategory>> fetchCategories() async {
    return _muslimRepo.getAzkarCategories();
  }

  /// Fetches chapters within a specific category
  Future<List<AzkarChapter>> fetchChapters(int categoryId) async {
    return _muslimRepo.getAzkarChapters(categoryId: categoryId);
  }

  /// Fetches all individual supplications/items within a chapter
  Future<List<AzkarItem>> fetchItems(int chapterId) async {
    return _muslimRepo.getAzkarItems(chapterId: chapterId);
  }
}
