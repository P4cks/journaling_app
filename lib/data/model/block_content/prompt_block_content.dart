class PromptBlockContent {
  /// The question rendered above the answer field. Seeded from the
  /// layout's per-block config at entry materialization and never
  /// edited from inside the entry editor.
  final String prompt;

  /// The user's answer for this entry. Edited inline in the entry
  /// editor; per-keystroke save like the text block.
  final String answer;

  const PromptBlockContent({this.prompt = '', this.answer = ''});

  factory PromptBlockContent.fromMap(Map<String, dynamic> map) {
    return PromptBlockContent(
      prompt: (map['prompt'] as String?) ?? '',
      answer: (map['answer'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    if (prompt.isNotEmpty) 'prompt': prompt,
    if (answer.isNotEmpty) 'answer': answer,
  };
}
