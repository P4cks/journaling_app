// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class JournalEntryAdapter extends TypeAdapter<JournalEntry> {
  @override
  final typeId = 0;

  @override
  JournalEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JournalEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      widgets: (fields[2] as List).cast<JournalBlockData>(),
    );
  }

  @override
  void write(BinaryWriter writer, JournalEntry obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.widgets);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class JournalBlockDataAdapter extends TypeAdapter<JournalBlockData> {
  @override
  final typeId = 1;

  @override
  JournalBlockData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JournalBlockData(
      id: fields[0] as String,
      type: fields[1] as BlockType,
      contentJson: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, JournalBlockData obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.contentJson);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalBlockDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BlockTypeAdapter extends TypeAdapter<BlockType> {
  @override
  final typeId = 2;

  @override
  BlockType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BlockType.textBlock;
      case 1:
        return BlockType.moodTracker;
      default:
        return BlockType.textBlock;
    }
  }

  @override
  void write(BinaryWriter writer, BlockType obj) {
    switch (obj) {
      case BlockType.textBlock:
        writer.writeByte(0);
      case BlockType.moodTracker:
        writer.writeByte(1);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
