import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// One curated HugeIcons glyph offered to the user when building a
/// custom carousel. Stable [name] is persisted in `CarouselItem.value`;
/// the underlying [icon] data is resolved at render time so the
/// downstream wire shape never depends on Flutter SDK or icon-library
/// internals.
///
/// (Names originated as Phosphor identifiers — kept as-is after the
/// HugeIcons migration so existing saved selections still resolve.
/// Pre-1.0 we don't migrate string keys when the visual mapping
/// changes.)
///
/// Adding a new icon is always safe. **Removing** one orphans existing
/// items in saved definitions that referenced it; those decode to no
/// glyph via [carouselIconFor] returning the fallback. Prefer keeping
/// deprecated entries in place over breaking saved definitions.
class CarouselIcon {
  const CarouselIcon({
    required this.name,
    required this.icon,
    required this.label,
  });

  final String name;
  final HugeIconData icon;
  final String label;
}

/// Curated set of icons offered in the custom-carousel item picker.
/// Starts from a small general-purpose selection — heavy on activities,
/// nature, food, and productivity glyphs. Order is presentation order
/// in the picker (alphabetical within each rough category).
final kCarouselIcons = <CarouselIcon>[
  // Nature / weather
  CarouselIcon(
    name: 'sun',
    icon: HugeIcons.strokeRoundedSun01,
    label: 'Sun',
  ),
  CarouselIcon(
    name: 'moon',
    icon: HugeIcons.strokeRoundedMoon,
    label: 'Moon',
  ),
  CarouselIcon(
    name: 'cloud',
    icon: HugeIcons.strokeRoundedCloud,
    label: 'Cloud',
  ),
  CarouselIcon(
    name: 'star',
    icon: HugeIcons.strokeRoundedStar,
    label: 'Star',
  ),
  CarouselIcon(
    name: 'leaf',
    icon: HugeIcons.strokeRoundedLeaf01,
    label: 'Leaf',
  ),
  CarouselIcon(
    name: 'tree',
    icon: HugeIcons.strokeRoundedTree01,
    label: 'Tree',
  ),
  CarouselIcon(
    name: 'flower',
    icon: HugeIcons.strokeRoundedFlower,
    label: 'Flower',
  ),
  CarouselIcon(
    name: 'mountains',
    icon: HugeIcons.strokeRoundedMountain,
    label: 'Mountains',
  ),
  CarouselIcon(
    name: 'waves',
    icon: HugeIcons.strokeRoundedWave,
    label: 'Waves',
  ),
  CarouselIcon(
    name: 'fire',
    icon: HugeIcons.strokeRoundedFire,
    label: 'Fire',
  ),
  // Activities
  CarouselIcon(
    name: 'barbell',
    icon: HugeIcons.strokeRoundedDumbbell01,
    label: 'Workout',
  ),
  CarouselIcon(
    name: 'personSimpleRun',
    icon: HugeIcons.strokeRoundedWorkoutRun,
    label: 'Run',
  ),
  CarouselIcon(
    name: 'personSimpleWalk',
    icon: HugeIcons.strokeRoundedWalking,
    label: 'Walk',
  ),
  CarouselIcon(
    name: 'personSimpleBike',
    icon: HugeIcons.strokeRoundedBicycle,
    label: 'Bike',
  ),
  CarouselIcon(
    name: 'soccerBall',
    icon: HugeIcons.strokeRoundedFootball,
    label: 'Sport',
  ),
  // Food / drink
  CarouselIcon(
    name: 'coffee',
    icon: HugeIcons.strokeRoundedCoffee01,
    label: 'Coffee',
  ),
  CarouselIcon(
    name: 'hamburger',
    icon: HugeIcons.strokeRoundedHamburger01,
    label: 'Food',
  ),
  CarouselIcon(
    name: 'pizza',
    icon: HugeIcons.strokeRoundedPizza01,
    label: 'Pizza',
  ),
  CarouselIcon(
    name: 'beerStein',
    icon: HugeIcons.strokeRoundedSoftDrink01,
    label: 'Beer',
  ),
  CarouselIcon(
    name: 'wine',
    icon: HugeIcons.strokeRoundedDrink,
    label: 'Wine',
  ),
  CarouselIcon(
    name: 'cake',
    icon: HugeIcons.strokeRoundedBirthdayCake,
    label: 'Cake',
  ),
  // Emotion / energy
  CarouselIcon(
    name: 'heart',
    icon: HugeIcons.strokeRoundedFavourite,
    label: 'Heart',
  ),
  CarouselIcon(
    name: 'smiley',
    icon: HugeIcons.strokeRoundedSmile,
    label: 'Smile',
  ),
  CarouselIcon(
    name: 'lightning',
    icon: HugeIcons.strokeRoundedZap,
    label: 'Energy',
  ),
  CarouselIcon(
    name: 'sparkle',
    icon: HugeIcons.strokeRoundedSparkles,
    label: 'Spark',
  ),
  // Productivity
  CarouselIcon(
    name: 'book',
    icon: HugeIcons.strokeRoundedBook01,
    label: 'Book',
  ),
  CarouselIcon(
    name: 'bookOpen',
    icon: HugeIcons.strokeRoundedBookOpen01,
    label: 'Reading',
  ),
  CarouselIcon(
    name: 'pen',
    icon: HugeIcons.strokeRoundedPen01,
    label: 'Write',
  ),
  CarouselIcon(
    name: 'briefcase',
    icon: HugeIcons.strokeRoundedBriefcase01,
    label: 'Work',
  ),
  CarouselIcon(
    name: 'lightbulb',
    icon: HugeIcons.strokeRoundedBulb,
    label: 'Idea',
  ),
  CarouselIcon(
    name: 'target',
    icon: HugeIcons.strokeRoundedTarget01,
    label: 'Goal',
  ),
  CarouselIcon(
    name: 'check',
    icon: HugeIcons.strokeRoundedTick01,
    label: 'Done',
  ),
  // Home / pets
  CarouselIcon(
    name: 'house',
    icon: HugeIcons.strokeRoundedHome01,
    label: 'Home',
  ),
  CarouselIcon(
    name: 'bed',
    icon: HugeIcons.strokeRoundedBed,
    label: 'Sleep',
  ),
  CarouselIcon(
    name: 'pawPrint',
    icon: HugeIcons.strokeRoundedBone01,
    label: 'Pet',
  ),
  // Misc
  CarouselIcon(
    name: 'gift',
    icon: HugeIcons.strokeRoundedGift,
    label: 'Gift',
  ),
  CarouselIcon(
    name: 'musicNote',
    icon: HugeIcons.strokeRoundedMusicNote01,
    label: 'Music',
  ),
  CarouselIcon(
    name: 'headphones',
    icon: HugeIcons.strokeRoundedHeadphones,
    label: 'Audio',
  ),
  CarouselIcon(
    name: 'camera',
    icon: HugeIcons.strokeRoundedCamera01,
    label: 'Camera',
  ),
  CarouselIcon(
    name: 'paintBrush',
    icon: HugeIcons.strokeRoundedPaintBrush01,
    label: 'Art',
  ),
];

/// Lookup by stable `name`. Unknown names fall back to a generic
/// question-mark glyph so a removed/typo'd id renders something legible
/// rather than crashing.
CarouselIcon? carouselIconFor(String name) {
  for (final icon in kCarouselIcons) {
    if (icon.name == name) return icon;
  }
  return null;
}
