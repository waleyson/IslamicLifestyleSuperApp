class SurahModel {
  final int number;
  final String name; // Arabic name (name_arabic)
  final String englishName; // Romanized (name_simple)
  final String englishNameTranslation; // translated_name.name
  final int numberOfAyahs; // verses_count
  final String revelationType; // revelation_place

  const SurahModel({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  /// Parses the QuranCDN /chapters response shape.
  factory SurahModel.fromJson(Map<String, dynamic> json) {
    final translatedName = json['translated_name'] as Map<String, dynamic>?;
    return SurahModel(
      number: json['id'] as int? ?? 0,
      name: json['name_arabic'] as String? ?? '',
      englishName: json['name_simple'] as String? ?? '',
      englishNameTranslation: translatedName?['name'] as String? ?? '',
      numberOfAyahs: json['verses_count'] as int? ?? 0,
      revelationType: json['revelation_place'] as String? ?? '',
    );
  }
}
