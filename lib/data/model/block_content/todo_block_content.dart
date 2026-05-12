class TodoItem {
  final String id;
  final String text;
  final bool done;

  const TodoItem({required this.id, required this.text, this.done = false});

  factory TodoItem.fromMap(Map<String, dynamic> map) => TodoItem(
    id: (map['id'] as String?) ?? '',
    text: (map['text'] as String?) ?? '',
    done: (map['done'] as bool?) ?? false,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    if (done) 'done': true,
  };

  TodoItem copyWith({String? id, String? text, bool? done}) => TodoItem(
    id: id ?? this.id,
    text: text ?? this.text,
    done: done ?? this.done,
  );
}

class TodoBlockContent {
  final List<TodoItem> items;

  const TodoBlockContent({this.items = const []});

  factory TodoBlockContent.fromMap(Map<String, dynamic> map) {
    final raw = map['items'];
    if (raw is! List) return const TodoBlockContent();
    return TodoBlockContent(
      items: [
        for (final entry in raw)
          if (entry is Map<String, dynamic>)
            TodoItem.fromMap(entry)
          else if (entry is Map)
            TodoItem.fromMap(Map<String, dynamic>.from(entry)),
      ],
    );
  }

  Map<String, dynamic> toMap() => {
    'items': [for (final item in items) item.toMap()],
  };
}
