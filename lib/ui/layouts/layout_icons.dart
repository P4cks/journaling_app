import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Curated catalogue of icons selectable for a `JournalLayout`. Names are
/// the Phosphor identifier (e.g. `"squaresFour"`) so we persist plain
/// strings — no need for a Hive adapter on `IconData`. New entries can be
/// appended; removing one would orphan any layout that was saved with
/// that name (it would fall back to the default icon, which is fine).
class LayoutIcon {
  const LayoutIcon({
    required this.name,
    required this.duotone,
    required this.fill,
    required this.label,
  });

  final String name;
  final IconData duotone;
  final IconData fill;
  final String label;
}

const kDefaultLayoutIconName = 'squaresFour';

const kLayoutIcons = <LayoutIcon>[
  // Default
  LayoutIcon(
    name: 'squaresFour',
    duotone: PhosphorIconsDuotone.squaresFour,
    fill: PhosphorIconsFill.squaresFour,
    label: 'Grid',
  ),
  // Writing & notes
  LayoutIcon(
    name: 'notebook',
    duotone: PhosphorIconsDuotone.notebook,
    fill: PhosphorIconsFill.notebook,
    label: 'Notebook',
  ),
  LayoutIcon(
    name: 'notepad',
    duotone: PhosphorIconsDuotone.notepad,
    fill: PhosphorIconsFill.notepad,
    label: 'Notepad',
  ),
  LayoutIcon(
    name: 'book',
    duotone: PhosphorIconsDuotone.book,
    fill: PhosphorIconsFill.book,
    label: 'Book',
  ),
  LayoutIcon(
    name: 'bookOpen',
    duotone: PhosphorIconsDuotone.bookOpen,
    fill: PhosphorIconsFill.bookOpen,
    label: 'Book open',
  ),
  LayoutIcon(
    name: 'pencilSimple',
    duotone: PhosphorIconsDuotone.pencilSimple,
    fill: PhosphorIconsFill.pencilSimple,
    label: 'Pencil',
  ),
  LayoutIcon(
    name: 'feather',
    duotone: PhosphorIconsDuotone.feather,
    fill: PhosphorIconsFill.feather,
    label: 'Feather',
  ),
  // Mood / mind
  LayoutIcon(
    name: 'smiley',
    duotone: PhosphorIconsDuotone.smiley,
    fill: PhosphorIconsFill.smiley,
    label: 'Mood',
  ),
  LayoutIcon(
    name: 'heart',
    duotone: PhosphorIconsDuotone.heart,
    fill: PhosphorIconsFill.heart,
    label: 'Heart',
  ),
  LayoutIcon(
    name: 'brain',
    duotone: PhosphorIconsDuotone.brain,
    fill: PhosphorIconsFill.brain,
    label: 'Brain',
  ),
  LayoutIcon(
    name: 'lightbulb',
    duotone: PhosphorIconsDuotone.lightbulb,
    fill: PhosphorIconsFill.lightbulb,
    label: 'Idea',
  ),
  LayoutIcon(
    name: 'star',
    duotone: PhosphorIconsDuotone.star,
    fill: PhosphorIconsFill.star,
    label: 'Star',
  ),
  LayoutIcon(
    name: 'flame',
    duotone: PhosphorIconsDuotone.flame,
    fill: PhosphorIconsFill.flame,
    label: 'Flame',
  ),
  // Lists / planning
  LayoutIcon(
    name: 'listChecks',
    duotone: PhosphorIconsDuotone.listChecks,
    fill: PhosphorIconsFill.listChecks,
    label: 'Checklist',
  ),
  LayoutIcon(
    name: 'listBullets',
    duotone: PhosphorIconsDuotone.listBullets,
    fill: PhosphorIconsFill.listBullets,
    label: 'List',
  ),
  LayoutIcon(
    name: 'target',
    duotone: PhosphorIconsDuotone.target,
    fill: PhosphorIconsFill.target,
    label: 'Target',
  ),
  LayoutIcon(
    name: 'flag',
    duotone: PhosphorIconsDuotone.flag,
    fill: PhosphorIconsFill.flag,
    label: 'Flag',
  ),
  // Weather / nature
  LayoutIcon(
    name: 'sun',
    duotone: PhosphorIconsDuotone.sun,
    fill: PhosphorIconsFill.sun,
    label: 'Sun',
  ),
  LayoutIcon(
    name: 'moon',
    duotone: PhosphorIconsDuotone.moon,
    fill: PhosphorIconsFill.moon,
    label: 'Moon',
  ),
  LayoutIcon(
    name: 'cloud',
    duotone: PhosphorIconsDuotone.cloud,
    fill: PhosphorIconsFill.cloud,
    label: 'Cloud',
  ),
  LayoutIcon(
    name: 'drop',
    duotone: PhosphorIconsDuotone.drop,
    fill: PhosphorIconsFill.drop,
    label: 'Drop',
  ),
  LayoutIcon(
    name: 'leaf',
    duotone: PhosphorIconsDuotone.leaf,
    fill: PhosphorIconsFill.leaf,
    label: 'Leaf',
  ),
  LayoutIcon(
    name: 'tree',
    duotone: PhosphorIconsDuotone.tree,
    fill: PhosphorIconsFill.tree,
    label: 'Tree',
  ),
  LayoutIcon(
    name: 'mountains',
    duotone: PhosphorIconsDuotone.mountains,
    fill: PhosphorIconsFill.mountains,
    label: 'Mountains',
  ),
  // Lifestyle
  LayoutIcon(
    name: 'coffee',
    duotone: PhosphorIconsDuotone.coffee,
    fill: PhosphorIconsFill.coffee,
    label: 'Coffee',
  ),
  LayoutIcon(
    name: 'forkKnife',
    duotone: PhosphorIconsDuotone.forkKnife,
    fill: PhosphorIconsFill.forkKnife,
    label: 'Food',
  ),
  LayoutIcon(
    name: 'barbell',
    duotone: PhosphorIconsDuotone.barbell,
    fill: PhosphorIconsFill.barbell,
    label: 'Workout',
  ),
  LayoutIcon(
    name: 'musicNote',
    duotone: PhosphorIconsDuotone.musicNote,
    fill: PhosphorIconsFill.musicNote,
    label: 'Music',
  ),
  LayoutIcon(
    name: 'camera',
    duotone: PhosphorIconsDuotone.camera,
    fill: PhosphorIconsFill.camera,
    label: 'Camera',
  ),
  LayoutIcon(
    name: 'airplane',
    duotone: PhosphorIconsDuotone.airplane,
    fill: PhosphorIconsFill.airplane,
    label: 'Travel',
  ),
  LayoutIcon(
    name: 'gift',
    duotone: PhosphorIconsDuotone.gift,
    fill: PhosphorIconsFill.gift,
    label: 'Gift',
  ),
  LayoutIcon(
    name: 'briefcase',
    duotone: PhosphorIconsDuotone.briefcase,
    fill: PhosphorIconsFill.briefcase,
    label: 'Work',
  ),
];

/// Resolve [name] to a `LayoutIcon`. Returns the default icon if [name] is
/// `null` or doesn't match a known entry (e.g. a saved layout from a
/// previous version where an icon was later removed from the catalogue).
LayoutIcon layoutIconFor(String? name) {
  if (name == null) return _defaultIcon;
  for (final icon in kLayoutIcons) {
    if (icon.name == name) return icon;
  }
  return _defaultIcon;
}

final LayoutIcon _defaultIcon = kLayoutIcons.firstWhere(
  (i) => i.name == kDefaultLayoutIconName,
);
