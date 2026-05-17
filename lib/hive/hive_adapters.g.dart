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
      date: fields[4] as DateTime,
      lastModified: fields[3] as DateTime,
      sections: (fields[6] as List).cast<EntrySection>(),
      title: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, JournalEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(3)
      ..write(obj.lastModified)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.title)
      ..writeByte(6)
      ..write(obj.sections);
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
      case 2:
        return BlockType.weatherManual;
      case 3:
        return BlockType.promptBlock;
      case 4:
        return BlockType.todoBlock;
      case 5:
        return BlockType.quoteBlock;
      case 6:
        return BlockType.memoryBlock;
      case 7:
        return BlockType.weatherApi;
      case 8:
        return BlockType.photoBlock;
      case 9:
        return BlockType.locationBlock;
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
      case BlockType.weatherManual:
        writer.writeByte(2);
      case BlockType.promptBlock:
        writer.writeByte(3);
      case BlockType.todoBlock:
        writer.writeByte(4);
      case BlockType.quoteBlock:
        writer.writeByte(5);
      case BlockType.memoryBlock:
        writer.writeByte(6);
      case BlockType.weatherApi:
        writer.writeByte(7);
      case BlockType.photoBlock:
        writer.writeByte(8);
      case BlockType.locationBlock:
        writer.writeByte(9);
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

class JournalLayoutAdapter extends TypeAdapter<JournalLayout> {
  @override
  final typeId = 4;

  @override
  JournalLayout read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JournalLayout(
      id: fields[0] as String,
      name: fields[1] as String,
      kind: fields[4] as LayoutKind,
      sections: (fields[5] as List).cast<LayoutSection>(),
      iconName: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, JournalLayout obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.iconName)
      ..writeByte(4)
      ..write(obj.kind)
      ..writeByte(5)
      ..write(obj.sections);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalLayoutAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BlockTemplateAdapter extends TypeAdapter<BlockTemplate> {
  @override
  final typeId = 7;

  @override
  BlockTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BlockTemplate(
      id: fields[0] as String,
      type: fields[1] as BlockType,
      configJson: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BlockTemplate obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.configJson);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EntrySectionAdapter extends TypeAdapter<EntrySection> {
  @override
  final typeId = 8;

  @override
  EntrySection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EntrySection(
      id: fields[0] as String,
      kind: fields[1] as SectionKind,
      blocks: (fields[3] as List).cast<JournalBlockData>(),
      rows: (fields[2] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, EntrySection obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.kind)
      ..writeByte(2)
      ..write(obj.rows)
      ..writeByte(3)
      ..write(obj.blocks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntrySectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LayoutSectionAdapter extends TypeAdapter<LayoutSection> {
  @override
  final typeId = 9;

  @override
  LayoutSection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LayoutSection(
      id: fields[0] as String,
      kind: fields[1] as SectionKind,
      blocks: (fields[3] as List).cast<BlockTemplate>(),
      rows: (fields[2] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, LayoutSection obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.kind)
      ..writeByte(2)
      ..write(obj.rows)
      ..writeByte(3)
      ..write(obj.blocks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayoutSectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LayoutKindAdapter extends TypeAdapter<LayoutKind> {
  @override
  final typeId = 10;

  @override
  LayoutKind read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LayoutKind.blockOnly;
      case 1:
        return LayoutKind.fixedFourPlusText;
      case 2:
        return LayoutKind.custom;
      default:
        return LayoutKind.blockOnly;
    }
  }

  @override
  void write(BinaryWriter writer, LayoutKind obj) {
    switch (obj) {
      case LayoutKind.blockOnly:
        writer.writeByte(0);
      case LayoutKind.fixedFourPlusText:
        writer.writeByte(1);
      case LayoutKind.custom:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayoutKindAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SectionKindAdapter extends TypeAdapter<SectionKind> {
  @override
  final typeId = 11;

  @override
  SectionKind read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SectionKind.text;
      case 1:
        return SectionKind.blockGrid;
      case 2:
        return SectionKind.featureBlock;
      default:
        return SectionKind.text;
    }
  }

  @override
  void write(BinaryWriter writer, SectionKind obj) {
    switch (obj) {
      case SectionKind.text:
        writer.writeByte(0);
      case SectionKind.blockGrid:
        writer.writeByte(1);
      case SectionKind.featureBlock:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectionKindAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
