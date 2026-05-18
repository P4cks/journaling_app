import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/section_header.dart';

/// Groups related settings rows under a shared section label.
///
/// [label] becomes the section header, and [children] are the already-built
/// controls or rows for that group. The output is a vertical settings section
/// with consistent row padding and a divider after the group.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.label,
    required this.children,
  });

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(label: label),
        ...children.map(
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
