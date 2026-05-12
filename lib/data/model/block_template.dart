import 'dart:convert';
import 'package:journaling_app_rewrite/data/model/block_type.dart';

/// One entry in a `JournalLayout.blocks` list: a [BlockType] plus an
/// optional configuration map (encoded as JSON for forward-compat,
/// mirroring `JournalBlockData.contentJson`).
///
/// The config is baked into the initial content map of the materialized
/// `JournalBlockData` when an entry is created from a layout — see
/// `JournalRepository.createEntryForDate`. That way the layout author
/// can pre-fill template-level state (a prompt question, a char limit)
/// that survives into every entry created from the layout.
class BlockTemplate {
  final String id;
  final BlockType type;
  final String configJson;

  const BlockTemplate({
    required this.id,
    required this.type,
    required this.configJson,
  });

  Map<String, dynamic> get config =>
      (jsonDecode(configJson) as Map<String, dynamic>);

  factory BlockTemplate.create({
    required String id,
    required BlockType type,
    Map<String, dynamic> config = const {},
  }) => BlockTemplate(
    id: id,
    type: type,
    configJson: jsonEncode(config),
  );

  BlockTemplate copyWith({
    String? id,
    BlockType? type,
    Map<String, dynamic>? config,
  }) => BlockTemplate(
    id: id ?? this.id,
    type: type ?? this.type,
    configJson: config == null ? configJson : jsonEncode(config),
  );

  @override
  String toString() => 'BlockTemplate(id: $id, type: $type)';
}
