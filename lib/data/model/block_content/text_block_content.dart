class TextBlockContent {
  final String text;

  const TextBlockContent({required this.text});

  factory TextBlockContent.fromMap(Map<String, dynamic> map) =>
      TextBlockContent(text: (map['text'] as String?) ?? '');

  Map<String, dynamic> toMap() => {'text': text};
}
