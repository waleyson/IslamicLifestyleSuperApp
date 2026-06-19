class TafsirModel {
  final int id;
  final String name;
  final String authorName;
  final String languageName;

  const TafsirModel({
    required this.id,
    required this.name,
    required this.authorName,
    required this.languageName,
  });

  factory TafsirModel.fromJson(Map<String, dynamic> json) {
    return TafsirModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      authorName: json['author_name'] as String? ?? '',
      languageName: json['language_name'] as String? ?? '',
    );
  }
}
