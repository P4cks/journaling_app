import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// One curated Phosphor icon offered to the user when building a custom
/// carousel. Stable [name] is persisted in `CarouselItem.value`; the
/// duotone / fill `IconData`s are resolved at render time so the
/// downstream wire shape never depends on Flutter SDK or Phosphor
/// internals.
///
/// Adding a new icon is always safe. **Removing** one orphans existing
/// items in saved definitions that referenced it; those decode to no
/// glyph via [carouselIconFor] returning the fallback. Prefer keeping
/// deprecated entries in place over breaking saved definitions.
class CarouselIcon {
  const CarouselIcon({
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

/// Curated set of icons offered in the custom-carousel item picker.
/// Starts from a small general-purpose selection — heavy on activities,
/// nature, food, and productivity glyphs. Order is presentation order
/// in the picker (alphabetical within each rough category).
const kCarouselIcons = <CarouselIcon>[
  // Nature / weather
  CarouselIcon(
    name: 'sun',
    duotone: PhosphorIconsDuotone.sun,
    fill: PhosphorIconsFill.sun,
    label: 'Sun',
  ),
  CarouselIcon(
    name: 'moon',
    duotone: PhosphorIconsDuotone.moon,
    fill: PhosphorIconsFill.moon,
    label: 'Moon',
  ),
  CarouselIcon(
    name: 'cloud',
    duotone: PhosphorIconsDuotone.cloud,
    fill: PhosphorIconsFill.cloud,
    label: 'Cloud',
  ),
  CarouselIcon(
    name: 'star',
    duotone: PhosphorIconsDuotone.star,
    fill: PhosphorIconsFill.star,
    label: 'Star',
  ),
  CarouselIcon(
    name: 'leaf',
    duotone: PhosphorIconsDuotone.leaf,
    fill: PhosphorIconsFill.leaf,
    label: 'Leaf',
  ),
  CarouselIcon(
    name: 'tree',
    duotone: PhosphorIconsDuotone.tree,
    fill: PhosphorIconsFill.tree,
    label: 'Tree',
  ),
  CarouselIcon(
    name: 'flower',
    duotone: PhosphorIconsDuotone.flower,
    fill: PhosphorIconsFill.flower,
    label: 'Flower',
  ),
  CarouselIcon(
    name: 'mountains',
    duotone: PhosphorIconsDuotone.mountains,
    fill: PhosphorIconsFill.mountains,
    label: 'Mountains',
  ),
  CarouselIcon(
    name: 'waves',
    duotone: PhosphorIconsDuotone.waves,
    fill: PhosphorIconsFill.waves,
    label: 'Waves',
  ),
  CarouselIcon(
    name: 'fire',
    duotone: PhosphorIconsDuotone.fire,
    fill: PhosphorIconsFill.fire,
    label: 'Fire',
  ),
  // Activities
  CarouselIcon(
    name: 'barbell',
    duotone: PhosphorIconsDuotone.barbell,
    fill: PhosphorIconsFill.barbell,
    label: 'Workout',
  ),
  CarouselIcon(
    name: 'personSimpleRun',
    duotone: PhosphorIconsDuotone.personSimpleRun,
    fill: PhosphorIconsFill.personSimpleRun,
    label: 'Run',
  ),
  CarouselIcon(
    name: 'personSimpleWalk',
    duotone: PhosphorIconsDuotone.personSimpleWalk,
    fill: PhosphorIconsFill.personSimpleWalk,
    label: 'Walk',
  ),
  CarouselIcon(
    name: 'personSimpleBike',
    duotone: PhosphorIconsDuotone.personSimpleBike,
    fill: PhosphorIconsFill.personSimpleBike,
    label: 'Bike',
  ),
  CarouselIcon(
    name: 'soccerBall',
    duotone: PhosphorIconsDuotone.soccerBall,
    fill: PhosphorIconsFill.soccerBall,
    label: 'Sport',
  ),
  // Food / drink
  CarouselIcon(
    name: 'coffee',
    duotone: PhosphorIconsDuotone.coffee,
    fill: PhosphorIconsFill.coffee,
    label: 'Coffee',
  ),
  CarouselIcon(
    name: 'hamburger',
    duotone: PhosphorIconsDuotone.hamburger,
    fill: PhosphorIconsFill.hamburger,
    label: 'Food',
  ),
  CarouselIcon(
    name: 'pizza',
    duotone: PhosphorIconsDuotone.pizza,
    fill: PhosphorIconsFill.pizza,
    label: 'Pizza',
  ),
  CarouselIcon(
    name: 'beerStein',
    duotone: PhosphorIconsDuotone.beerStein,
    fill: PhosphorIconsFill.beerStein,
    label: 'Beer',
  ),
  CarouselIcon(
    name: 'wine',
    duotone: PhosphorIconsDuotone.wine,
    fill: PhosphorIconsFill.wine,
    label: 'Wine',
  ),
  CarouselIcon(
    name: 'cake',
    duotone: PhosphorIconsDuotone.cake,
    fill: PhosphorIconsFill.cake,
    label: 'Cake',
  ),
  // Emotion / energy
  CarouselIcon(
    name: 'heart',
    duotone: PhosphorIconsDuotone.heart,
    fill: PhosphorIconsFill.heart,
    label: 'Heart',
  ),
  CarouselIcon(
    name: 'smiley',
    duotone: PhosphorIconsDuotone.smiley,
    fill: PhosphorIconsFill.smiley,
    label: 'Smile',
  ),
  CarouselIcon(
    name: 'lightning',
    duotone: PhosphorIconsDuotone.lightning,
    fill: PhosphorIconsFill.lightning,
    label: 'Energy',
  ),
  CarouselIcon(
    name: 'sparkle',
    duotone: PhosphorIconsDuotone.sparkle,
    fill: PhosphorIconsFill.sparkle,
    label: 'Spark',
  ),
  // Productivity
  CarouselIcon(
    name: 'book',
    duotone: PhosphorIconsDuotone.book,
    fill: PhosphorIconsFill.book,
    label: 'Book',
  ),
  CarouselIcon(
    name: 'bookOpen',
    duotone: PhosphorIconsDuotone.bookOpen,
    fill: PhosphorIconsFill.bookOpen,
    label: 'Reading',
  ),
  CarouselIcon(
    name: 'pen',
    duotone: PhosphorIconsDuotone.pen,
    fill: PhosphorIconsFill.pen,
    label: 'Write',
  ),
  CarouselIcon(
    name: 'briefcase',
    duotone: PhosphorIconsDuotone.briefcase,
    fill: PhosphorIconsFill.briefcase,
    label: 'Work',
  ),
  CarouselIcon(
    name: 'lightbulb',
    duotone: PhosphorIconsDuotone.lightbulb,
    fill: PhosphorIconsFill.lightbulb,
    label: 'Idea',
  ),
  CarouselIcon(
    name: 'target',
    duotone: PhosphorIconsDuotone.target,
    fill: PhosphorIconsFill.target,
    label: 'Goal',
  ),
  CarouselIcon(
    name: 'check',
    duotone: PhosphorIconsDuotone.check,
    fill: PhosphorIconsFill.check,
    label: 'Done',
  ),
  // Home / pets
  CarouselIcon(
    name: 'house',
    duotone: PhosphorIconsDuotone.house,
    fill: PhosphorIconsFill.house,
    label: 'Home',
  ),
  CarouselIcon(
    name: 'bed',
    duotone: PhosphorIconsDuotone.bed,
    fill: PhosphorIconsFill.bed,
    label: 'Sleep',
  ),
  CarouselIcon(
    name: 'pawPrint',
    duotone: PhosphorIconsDuotone.pawPrint,
    fill: PhosphorIconsFill.pawPrint,
    label: 'Pet',
  ),
  // Misc
  CarouselIcon(
    name: 'gift',
    duotone: PhosphorIconsDuotone.gift,
    fill: PhosphorIconsFill.gift,
    label: 'Gift',
  ),
  CarouselIcon(
    name: 'musicNote',
    duotone: PhosphorIconsDuotone.musicNote,
    fill: PhosphorIconsFill.musicNote,
    label: 'Music',
  ),
  CarouselIcon(
    name: 'headphones',
    duotone: PhosphorIconsDuotone.headphones,
    fill: PhosphorIconsFill.headphones,
    label: 'Audio',
  ),
  CarouselIcon(
    name: 'camera',
    duotone: PhosphorIconsDuotone.camera,
    fill: PhosphorIconsFill.camera,
    label: 'Camera',
  ),
  CarouselIcon(
    name: 'paintBrush',
    duotone: PhosphorIconsDuotone.paintBrush,
    fill: PhosphorIconsFill.paintBrush,
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
