/// One slot in a user-defined carousel — either an emoji string or a
/// curated icon name (resolved to a HugeIcons glyph by the carousel
/// icon catalogue; the stable name ids originated as Phosphor
/// identifiers and are preserved as-is). Discriminated by [kind] so
/// the renderer knows whether `value` is a unicode emoji ("😀") or
/// an icon identifier ("sun"). Persisted both in the registry
/// ([CustomCarouselDefinition]) and verbatim in a block's content
/// (when the user has picked one).
///
/// The wire shape is `{"kind": "emoji"|"icon", "value": "..."}`. Unknown
/// `kind` strings decode as [CarouselItemKind.emoji] with the raw
/// value passed through — defensive against schema drift.
enum CarouselItemKind { emoji, icon }

class CarouselItem {
  final CarouselItemKind kind;
  final String value;

  const CarouselItem({required this.kind, required this.value});

  factory CarouselItem.emoji(String emoji) =>
      CarouselItem(kind: CarouselItemKind.emoji, value: emoji);

  factory CarouselItem.icon(String iconName) =>
      CarouselItem(kind: CarouselItemKind.icon, value: iconName);

  factory CarouselItem.fromMap(Map<String, dynamic> map) {
    final rawKind = map['kind'] as String?;
    final value = (map['value'] as String?) ?? '';
    final kind = rawKind == 'icon'
        ? CarouselItemKind.icon
        : CarouselItemKind.emoji;
    return CarouselItem(kind: kind, value: value);
  }

  Map<String, dynamic> toMap() => {'kind': kind.name, 'value': value};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CarouselItem && other.kind == kind && other.value == value);

  @override
  int get hashCode => Object.hash(kind, value);

  @override
  String toString() => 'CarouselItem(${kind.name}: $value)';
}
