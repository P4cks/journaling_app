enum Mood { happy, neutral, sad }

class MoodBlockContent {
  final Mood? mood;

  const MoodBlockContent({this.mood});

  factory MoodBlockContent.fromMap(Map<String, dynamic> map) {
    final id = map['moodId'] as String?;
    if (id == null) return const MoodBlockContent();
    for (final m in Mood.values) {
      if (m.name == id) return MoodBlockContent(mood: m);
    }
    return const MoodBlockContent();
  }

  Map<String, dynamic> toMap() => {
    if (mood != null) 'moodId': mood!.name,
  };
}
