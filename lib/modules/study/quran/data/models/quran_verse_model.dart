class QuranVerseModel {
  final String verseKey; // e.g. "1:1"
  final int verseNumber;
  final String textUthmani; // Arabic (Uthmani script)
  final String translationText;

  const QuranVerseModel({
    required this.verseKey,
    required this.verseNumber,
    required this.textUthmani,
    required this.translationText,
  });

  factory QuranVerseModel.fromJson(Map<String, dynamic> json) {
    final translations = json['translations'] as List<dynamic>?;
    final translationText = translations != null && translations.isNotEmpty
        ? (translations.first['text'] as String? ?? '')
        : '';

    return QuranVerseModel(
      verseKey: json['verse_key'] as String? ?? '',
      verseNumber: json['verse_number'] as int? ?? 0,
      textUthmani: json['text_uthmani'] as String? ?? '',
      translationText: _stripHtmlTags(translationText),
    );
  }

  Map<String, dynamic> toJson() => {
        'verse_key': verseKey,
        'verse_number': verseNumber,
        'text_uthmani': textUthmani,
        'translation_text': translationText,
      };

  factory QuranVerseModel.fromCacheJson(Map<String, dynamic> json) {
    return QuranVerseModel(
      verseKey: json['verse_key'] as String? ?? '',
      verseNumber: json['verse_number'] as int? ?? 0,
      textUthmani: json['text_uthmani'] as String? ?? '',
      translationText: json['translation_text'] as String? ?? '',
    );
  }

  /// Strips basic HTML tags from translation text (QuranCDN includes <sup> tags etc.)
  static String _stripHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}
