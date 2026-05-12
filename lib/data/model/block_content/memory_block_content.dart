import 'package:journaling_app_rewrite/data/model/block_type.dart';

/// A locked-in reference to a past block, captured the first time this
/// memory block was opened.
///
/// `snapshotJson` stores the source block's `contentJson` verbatim so
/// future schema changes to the source block's content shape don't
/// invalidate the memory.
class MemoryBlockContent {
  final String? sourceEntryDate; // yyyy-MM-dd of the source entry
  final String? sourceBlockId;
  final BlockType? sourceType;
  final String? snapshotJson;

  const MemoryBlockContent({
    this.sourceEntryDate,
    this.sourceBlockId,
    this.sourceType,
    this.snapshotJson,
  });

  bool get isSeeded => sourceBlockId != null && snapshotJson != null;

  factory MemoryBlockContent.fromMap(Map<String, dynamic> map) {
    BlockType? type;
    final typeName = map['sourceType'] as String?;
    if (typeName != null) {
      for (final t in BlockType.values) {
        if (t.name == typeName) {
          type = t;
          break;
        }
      }
    }
    return MemoryBlockContent(
      sourceEntryDate: map['sourceEntryDate'] as String?,
      sourceBlockId: map['sourceBlockId'] as String?,
      sourceType: type,
      snapshotJson: map['snapshotJson'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    if (sourceEntryDate != null) 'sourceEntryDate': sourceEntryDate,
    if (sourceBlockId != null) 'sourceBlockId': sourceBlockId,
    if (sourceType != null) 'sourceType': sourceType!.name,
    if (snapshotJson != null) 'snapshotJson': snapshotJson,
  };
}
