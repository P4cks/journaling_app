import 'package:hive_ce/hive_ce.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry_collection.dart';

@GenerateAdapters([AdapterSpec<JournalEntry>(), AdapterSpec<JournalBlockData>(), AdapterSpec<BlockType>(), AdapterSpec<JournalEntryCollection>()])
part 'hive_adapters.g.dart';