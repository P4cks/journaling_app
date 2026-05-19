import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      segments: [
        ButtonSegment(
          value: ThemeMode.system,
          label: const Text('System'),
          icon: AppIcon(HugeIcons.strokeRoundedSmartPhone01),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          label: const Text('Light'),
          icon: AppIcon(HugeIcons.strokeRoundedSun01),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          label: const Text('Dark'),
          icon: AppIcon(HugeIcons.strokeRoundedMoon),
        ),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}
