class TranslationModel {
  final int id;
  final String name;
  final String authorName;
  final String languageName;

  const TranslationModel({
    required this.id,
    required this.name,
    required this.authorName,
    required this.languageName,
  });

  factory TranslationModel.fromJson(Map<String, dynamic> json) {
    return TranslationModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      authorName: json['author_name'] as String? ?? '',
      languageName: json['language_name'] as String? ?? '',
    );
  }
}
