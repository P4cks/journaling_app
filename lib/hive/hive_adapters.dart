import 'package:hive_ce/hive_ce.dart';
import 'package:journaling_app_rewrite/data/model/block_template.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/entry_section.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';
import 'package:journaling_app_rewrite/data/model/layout_kind.dart';
import 'package:journaling_app_rewrite/data/model/layout_section.dart';
import 'package:journaling_app_rewrite/data/model/section_kind.dart';

@GenerateAdapters([
  AdapterSpec<JournalEntry>(),
  AdapterSpec<EntrySection>(),
  AdapterSpec<JournalBlockData>(),
  AdapterSpec<BlockType>(),
  AdapterSpec<JournalLayout>(),
  AdapterSpec<LayoutSection>(),
  AdapterSpec<LayoutKind>(),
  AdapterSpec<SectionKind>(),
  AdapterSpec<BlockTemplate>(),
])
part 'hive_adapters.g.dart';
