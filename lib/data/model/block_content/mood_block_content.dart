/// Curated emoji set used by the mood carousel.
///
/// Order is presentation order in the carousel. The persisted value is the
/// emoji string itself, so reordering or removing emojis here is safe — old
/// entries keep rendering whatever they stored.
const moodEmojis = <String>[
  '😄',
  '😊',
  '😌',
  '😐',
  '😢',
  '😠',
  '😩',
  '😍',
  '🤔',
];

/// Legacy `moodId` (enum-name) → emoji migration.
/// Pre-emoji wire format only stored these three names.
const _legacyMoodIdToEmoji = <String, String>{
  'happy': '😄',
  'neutral': '😐',
  'sad': '😢',
};

class MoodBlockContent {
  final String? emoji;

  const MoodBlockContent({this.emoji});

  factory MoodBlockContent.fromMap(Map<String, dynamic> map) {
    final emoji = map['emoji'] as String?;
    if (emoji != null && emoji.isNotEmpty) {
      return MoodBlockContent(emoji: emoji);
    }
    final legacyId = map['moodId'] as String?;
    if (legacyId != null) {
      final migrated = _legacyMoodIdToEmoji[legacyId];
      if (migrated != null) return MoodBlockContent(emoji: migrated);
    }
    return const MoodBlockContent();
  }

  Map<String, dynamic> toMap() => {
    if (emoji != null) 'emoji': emoji,
  };
}
