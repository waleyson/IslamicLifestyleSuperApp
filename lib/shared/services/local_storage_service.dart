import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

class LocalStorageService {
  Future<void> init() async {
    await Hive.initFlutter();
    // Register adapters here later
  }

  Future<Box<T>> openBox<T>(String boxName) async {
    return await Hive.openBox<T>(boxName);
  }

  // Example generic methods
  Future<void> saveData<T>(String boxName, String key, T value) async {
    final box = await openBox<T>(boxName);
    await box.put(key, value);
  }

  Future<T?> getData<T>(String boxName, String key) async {
    final box = await openBox<T>(boxName);
    return box.get(key);
  }
}
