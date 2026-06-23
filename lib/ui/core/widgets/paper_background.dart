import 'package:flutter/material.dart';

/// Warm tactile journal background (GUS-85): the palette surface with a very
/// faint, tileable paper grain painted over it, behind [child].
///
/// The grain asset (`assets/textures/paper_grain.png`) is pure-white RGB with
/// the grain carried in its alpha channel, so a `srcIn` colour filter recolours
/// the speckle per theme — dark flecks on the cream light surface, light flecks
/// on the warm-dark surface — from one texture. It's deliberately a whisper:
/// blocks and cards sit on top with their own fills and occlude it, so the
/// grain only reads in the open "page" gutters.
///
/// Used as the body background of the main journal screen. Cheap: a single
/// repeated `DecorationImage`, no per-frame painting.
class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key, required this.child, this.opacity = 0.6});

  /// The content painted on top of the textured surface.
  final Widget child;

  /// Overall strength of the grain layer (multiplies the texture's own low
  /// alpha). Keep it small — the texture already tops out around 70/255.
  final double opacity;

  static const _grainAsset = 'assets/textures/paper_grain.png';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Tint the grain toward the ink colour but heavily muted, so it reads as
    // fibre in the paper rather than visible dots.
    final grainTint = scheme.onSurface.withValues(alpha: 0.5);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        image: DecorationImage(
          image: const AssetImage(_grainAsset),
          repeat: ImageRepeat.repeat,
          opacity: opacity,
          colorFilter: ColorFilter.mode(grainTint, BlendMode.srcIn),
        ),
      ),
      child: child,
    );
  }
}
