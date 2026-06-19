class ReciterModel {
  final int id;
  final String name;
  final String? style; // e.g. "Murattal", "Mujawwad", or null
  final String subfolder; // Used to build CDN URL: verses.quran.com/{subfolder}/...

  const ReciterModel({
    required this.id,
    required this.name,
    this.style,
    required this.subfolder,
  });

  factory ReciterModel.fromJson(Map<String, dynamic> json) {
    final recitationStyle = json['recitation_style'] as String?;
    // The subfolder is in audio_url field or constructed from the name
    // QuranCDN returns audio_url like: https://verses.quran.com/Alafasy_128kbps/001/001.mp3
    final audioUrl = json['audio_url'] as String? ?? '';
    String subfolder = '';
    if (audioUrl.isNotEmpty) {
      final uri = Uri.tryParse(audioUrl);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        subfolder = uri.pathSegments.first;
      }
    }

    return ReciterModel(
      id: json['id'] as int? ?? 0,
      name: json['reciter_name'] as String? ?? json['name'] as String? ?? '',
      style: recitationStyle,
      subfolder: subfolder,
    );
  }

  String get displayName =>
      style != null && style!.isNotEmpty ? '$name ($style)' : name;
}
