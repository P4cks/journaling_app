import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Curated catalogue of icons selectable for a `JournalLayout`. Names
/// are stable string ids (originally Phosphor identifiers; kept as-is
/// after the HugeIcons migration so existing saved layouts still
/// resolve). We persist plain strings — no need for a Hive adapter on
/// the underlying icon data. New entries can be appended; removing one
/// would orphan any layout that was saved with that name (it falls
/// back to the default icon, which is fine).
class LayoutIcon {
  const LayoutIcon({
    required this.name,
    required this.icon,
    required this.label,
  });

  final String name;
  final HugeIconData icon;
  final String label;
}

const kDefaultLayoutIconName = 'squaresFour';

final kLayoutIcons = <LayoutIcon>[
  // Default
  LayoutIcon(
    name: 'squaresFour',
    icon: HugeIcons.strokeRoundedGrid,
    label: 'Grid',
  ),
  // Writing & notes
  LayoutIcon(
    name: 'notebook',
    icon: HugeIcons.strokeRoundedNotebook01,
    label: 'Notebook',
  ),
  LayoutIcon(
    name: 'notepad',
    icon: HugeIcons.strokeRoundedNotebook02,
    label: 'Notepad',
  ),
  LayoutIcon(name: 'book', icon: HugeIcons.strokeRoundedBook01, label: 'Book'),
  LayoutIcon(
    name: 'bookOpen',
    icon: HugeIcons.strokeRoundedBookOpen01,
    label: 'Book open',
  ),
  LayoutIcon(
    name: 'pencilSimple',
    icon: HugeIcons.strokeRoundedPencil,
    label: 'Pencil',
  ),
  LayoutIcon(
    name: 'feather',
    icon: HugeIcons.strokeRoundedQuillWrite01,
    label: 'Feather',
  ),
  // Mood / mind
  LayoutIcon(name: 'smiley', icon: HugeIcons.strokeRoundedSmile, label: 'Mood'),
  LayoutIcon(
    name: 'heart',
    icon: HugeIcons.strokeRoundedFavourite,
    label: 'Heart',
  ),
  LayoutIcon(name: 'brain', icon: HugeIcons.strokeRoundedBrain, label: 'Brain'),
  LayoutIcon(
    name: 'lightbulb',
    icon: HugeIcons.strokeRoundedBulb,
    label: 'Idea',
  ),
  LayoutIcon(name: 'star', icon: HugeIcons.strokeRoundedStar, label: 'Star'),
  LayoutIcon(name: 'flame', icon: HugeIcons.strokeRoundedFire, label: 'Flame'),
  // Lists / planning
  LayoutIcon(
    name: 'listChecks',
    icon: HugeIcons.strokeRoundedCheckList,
    label: 'Checklist',
  ),
  LayoutIcon(
    name: 'listBullets',
    icon: HugeIcons.strokeRoundedLeftToRightListBullet,
    label: 'List',
  ),
  LayoutIcon(
    name: 'target',
    icon: HugeIcons.strokeRoundedTarget01,
    label: 'Target',
  ),
  LayoutIcon(name: 'flag', icon: HugeIcons.strokeRoundedFlag01, label: 'Flag'),
  // Weather / nature
  LayoutIcon(name: 'sun', icon: HugeIcons.strokeRoundedSun01, label: 'Sun'),
  LayoutIcon(name: 'moon', icon: HugeIcons.strokeRoundedMoon, label: 'Moon'),
  LayoutIcon(name: 'cloud', icon: HugeIcons.strokeRoundedCloud, label: 'Cloud'),
  LayoutIcon(name: 'drop', icon: HugeIcons.strokeRoundedDroplet, label: 'Drop'),
  LayoutIcon(name: 'leaf', icon: HugeIcons.strokeRoundedLeaf01, label: 'Leaf'),
  LayoutIcon(name: 'tree', icon: HugeIcons.strokeRoundedTree01, label: 'Tree'),
  LayoutIcon(
    name: 'mountains',
    icon: HugeIcons.strokeRoundedMountain,
    label: 'Mountains',
  ),
  // Lifestyle
  LayoutIcon(
    name: 'coffee',
    icon: HugeIcons.strokeRoundedCoffee01,
    label: 'Coffee',
  ),
  LayoutIcon(
    name: 'forkKnife',
    icon: HugeIcons.strokeRoundedRestaurant01,
    label: 'Food',
  ),
  LayoutIcon(
    name: 'barbell',
    icon: HugeIcons.strokeRoundedDumbbell01,
    label: 'Workout',
  ),
  LayoutIcon(
    name: 'musicNote',
    icon: HugeIcons.strokeRoundedMusicNote01,
    label: 'Music',
  ),
  LayoutIcon(
    name: 'camera',
    icon: HugeIcons.strokeRoundedCamera01,
    label: 'Camera',
  ),
  LayoutIcon(
    name: 'airplane',
    icon: HugeIcons.strokeRoundedAirplane01,
    label: 'Travel',
  ),
  LayoutIcon(name: 'gift', icon: HugeIcons.strokeRoundedGift, label: 'Gift'),
  LayoutIcon(
    name: 'briefcase',
    icon: HugeIcons.strokeRoundedBriefcase01,
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
