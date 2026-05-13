import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/section_header.dart';


class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.label, required this.widget});

  final String label;
  final List<Widget> widget;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(label: label),
        ...widget.map(
          (child) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: child,
          ),
        ),

        const Divider(),
      ],
    );
  }
}
