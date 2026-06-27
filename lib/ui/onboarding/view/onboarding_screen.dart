import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_button.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// One welcome-carousel slide: a tinted circular icon, a headline, and a
/// short body paragraph.
class _OnboardingStep {
  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  final HugeIconData icon;
  final String title;
  final String body;
}

/// The static slide content. Drawn from the app's feature inventory; kept
/// intentionally light (icon-driven, no image assets) so it reads the same
/// on first launch and on replay from Settings (GUS-18).
const List<_OnboardingStep> _kSteps = [
  _OnboardingStep(
    icon: HugeIcons.strokeRoundedNoteEdit,
    title: 'Welcome to your journal',
    body:
        'A calm, private space to reflect a little every day. '
        'Everything stays on your device.',
  ),
  _OnboardingStep(
    icon: HugeIcons.strokeRoundedCalendar03,
    title: 'Write every day',
    body:
        'Pick any day on the calendar and tap to capture how it went. '
        "Today's entry is always one tap away.",
  ),
  _OnboardingStep(
    icon: HugeIcons.strokeRoundedBlockGame,
    title: 'Build with blocks',
    body:
        'Mix moods, to-dos, prompts and free text. Drag blocks around '
        'to arrange each entry exactly how you like it.',
  ),
  _OnboardingStep(
    icon: HugeIcons.strokeRoundedDashboardSquareSetting,
    title: 'Reuse your templates',
    body:
        'Save a layout once and start every new entry pre-structured — '
        'no setting things up from scratch.',
  ),
  _OnboardingStep(
    icon: HugeIcons.strokeRoundedFire,
    title: 'Keep your streak — make it yours',
    body:
        'Track streaks and stats as the days add up, and style the app '
        'with themes and post-it flair. Even more unlocks with Pro.',
  ),
];

/// The first-run / replayable onboarding carousel.
///
/// Shown automatically on first launch (pushed by the main journal screen
/// with `extra: true`) and replayable from Settings → Help. When [firstRun]
/// is true the slides can only be left via Skip / Get started — system back
/// is blocked so the tutorial isn't accidentally dismissed before it's
/// marked complete.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.firstRun = false});

  /// True when shown automatically on first launch. Blocks back-dismissal
  /// so the tutorial exits only through Skip / Get started.
  final bool firstRun;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _kSteps.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await AppDependencies.of(context).onboardingSettings.setCompleted(true);
    if (!mounted) return;
    context.pop();
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !widget.firstRun,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                  child: AppButton(
                    variant: AppButtonVariant.text,
                    label: 'Skip',
                    onPressed: _finish,
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _kSteps.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _StepView(step: _kSteps[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _kSteps.length; i++)
                          _Dot(active: i == _index),
                      ],
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      variant: AppButtonVariant.primary,
                      expand: true,
                      label: _isLast ? 'Get started' : 'Next',
                      trailingIcon: _isLast
                          ? null
                          : HugeIcons.strokeRoundedArrowRight01,
                      onPressed: _next,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: scheme.surface,
      ),
    );
  }
}

/// A single full-screen slide body.
class _StepView extends StatelessWidget {
  const _StepView({required this.step});

  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: AppIcon(
              step.icon,
              size: 56,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            step.body,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Page-position indicator dot. The active dot is wider + primary-coloured.
class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 22 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active
            ? scheme.primary
            : scheme.onSurfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
