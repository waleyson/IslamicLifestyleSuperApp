class SurahModel {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;
  final String audioUrl;

  SurahModel({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
    required this.audioUrl,
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    final number = json['number'] as int;
    return SurahModel(
      number: number,
      name: json['name'] as String,
      englishName: json['englishName'] as String,
      englishNameTranslation: json['englishNameTranslation'] as String,
      numberOfAyahs: json['numberOfAyahs'] as int,
      revelationType: json['revelationType'] as String,
      audioUrl:
          'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$number.mp3',
    );
  }
}
