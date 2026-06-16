/// A single "wanna-do" / dream entry inside a [WannadoDefinition].
///
/// Definitions live in the `BlockSettings` registry (mirroring
/// `CustomCarouselDefinition`) and are rendered by the `wannado` section
/// widget as a vertical auto-rotating carousel. It is **pure display**:
/// there is no per-item done/checked state — a wanna-do is just a piece
/// of text the user wants to be reminded of.
///
/// Wire shape (inside a `WannadoDefinition`'s `items` list):
/// ```json
/// {"id": "uuid", "text": "Hike the Camino"}
/// ```
class WannadoItem {
  final String id;
  final String text;

  const WannadoItem({required this.id, required this.text});

  WannadoItem copyWith({String? text}) =>
      WannadoItem(id: id, text: text ?? this.text);

  factory WannadoItem.fromMap(Map<String, dynamic> map) => WannadoItem(
    id: (map['id'] as String?) ?? '',
    text: (map['text'] as String?) ?? '',
  );

  Map<String, dynamic> toMap() => {'id': id, 'text': text};

  @override
  String toString() => 'WannadoItem(id=$id, text="$text")';
}
