// Regenerates lib/ui/core/widgets/emoji_catalogue.dart from the official
// Unicode emoji-test.txt (the canonical, versioned list that also drives
// system keyboards).
//
// Usage:
//   dart run tool/gen_emoji_catalogue.dart            # fetches latest from unicode.org
//   dart run tool/gen_emoji_catalogue.dart <path>     # parses a local emoji-test.txt
//
// Keeps only `fully-qualified` entries, drops the Component group and the
// skin-tone / hair-color variants (GUS-44 — base forms only), groups each
// emoji by its top-level Unicode group, and emits a `const kEmojiCatalogue`.

import 'dart:io';

const _url = 'https://unicode.org/Public/emoji/latest/emoji-test.txt';

const _groupToCategory = <String, String>{
  'Smileys & Emotion': 'smileys',
  'People & Body': 'people',
  'Animals & Nature': 'nature',
  'Food & Drink': 'food',
  'Travel & Places': 'travel',
  'Activities': 'activities',
  'Objects': 'objects',
  'Symbols': 'symbols',
  'Flags': 'flags',
};

final _skinTone = RegExp('skin tone');
final _hairColor = RegExp(r': (red|curly|white|blond) hair$|: bald$');
final _dataLine = RegExp(
  r'^([0-9A-Fa-f ]+);\s*fully-qualified\s*#\s*(\S+)\s+E[\d.]+\s+(.+)$',
);

Future<void> main(List<String> args) async {
  final raw = args.isNotEmpty
      ? await File(args.first).readAsString()
      : await _fetch(_url);

  String? version;
  String? category;
  final entries = <(String emoji, String name, String category)>[];
  final seen = <String>{};

  for (final line in raw.split('\n')) {
    if (line.startsWith('# Version:')) {
      version = line.substring('# Version:'.length).trim();
      continue;
    }
    if (line.startsWith('# group:')) {
      final group = line.substring('# group:'.length).trim();
      category = _groupToCategory[group]; // null for Component → skipped
      continue;
    }
    if (line.isEmpty || line.startsWith('#') || category == null) continue;

    final m = _dataLine.firstMatch(line);
    if (m == null) continue;

    final name = m.group(3)!.trim();
    if (_skinTone.hasMatch(name) || _hairColor.hasMatch(name)) continue;

    final codePoints = m
        .group(1)!
        .trim()
        .split(RegExp(r'\s+'))
        .map((h) => int.parse(h, radix: 16));
    final emoji = String.fromCharCodes(codePoints);
    if (!seen.add(emoji)) continue;

    entries.add((emoji, name, category));
  }

  final buf = StringBuffer()
    ..writeln('// GENERATED FILE — do not edit by hand.')
    ..writeln('//')
    ..writeln(
      '// Source: Unicode emoji-test.txt'
      '${version == null ? '' : ' (Emoji $version)'}.',
    )
    ..writeln('// Regenerate with: dart run tool/gen_emoji_catalogue.dart')
    ..writeln('//')
    ..writeln('// Base forms only — skin-tone and hair-color variants are')
    ..writeln('// excluded (GUS-44). The full set of every variant would make')
    ..writeln('// the picker grid unusable; saved picks store the emoji string')
    ..writeln('// verbatim, so dropping a variant here never breaks history.')
    ..writeln()
    ..writeln('/// Top-level Unicode emoji groups, in display order.')
    ..writeln('enum EmojiCategory {')
    ..writeln('  smileys,')
    ..writeln('  people,')
    ..writeln('  nature,')
    ..writeln('  food,')
    ..writeln('  travel,')
    ..writeln('  activities,')
    ..writeln('  objects,')
    ..writeln('  symbols,')
    ..writeln('  flags,')
    ..writeln('}')
    ..writeln()
    ..writeln('/// One emoji offered in the picker. [emoji] is the persisted')
    ..writeln('/// value (stored verbatim in `CarouselItem.value`); [name] is')
    ..writeln('/// the CLDR short name, used for search.')
    ..writeln('class EmojiEntry {')
    ..writeln('  const EmojiEntry(this.emoji, this.name, this.category);')
    ..writeln()
    ..writeln('  final String emoji;')
    ..writeln('  final String name;')
    ..writeln('  final EmojiCategory category;')
    ..writeln('}')
    ..writeln()
    ..writeln('/// The full curated emoji set (${entries.length} entries), in')
    ..writeln('/// CLDR / keyboard order.')
    ..writeln('const kEmojiCatalogue = <EmojiEntry>[');
  for (final (emoji, name, cat) in entries) {
    buf.writeln("  EmojiEntry('$emoji', '${_esc(name)}', EmojiCategory.$cat),");
  }
  buf.writeln('];');

  const out = 'lib/ui/core/widgets/emoji_catalogue.dart';
  await File(out).writeAsString(buf.toString());
  stdout.writeln('Wrote ${entries.length} emojis to $out (Emoji $version).');
}

String _esc(String s) => s.replaceAll(r'\', r'\\').replaceAll("'", r"\'");

Future<String> _fetch(String url) async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(Uri.parse(url));
    final res = await req.close();
    if (res.statusCode != 200) {
      throw HttpException('GET $url → ${res.statusCode}');
    }
    final chunks = <int>[];
    await for (final c in res) {
      chunks.addAll(c);
    }
    return String.fromCharCodes(chunks);
  } finally {
    client.close();
  }
}
