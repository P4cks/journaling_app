import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/icon_emoji_picker.dart';
import 'package:journaling_app_rewrite/ui/layouts/layout_icons.dart';

/// Modal bottom sheet that lets the user pick an icon for a layout.
///
/// Thin wrapper over the shared [showIconEmojiPicker] (icon-only — no
/// emoji tab) mapping [kLayoutIcons] to [PickerIcon]s. Returns the chosen
/// icon's `name` (a stable identifier like `"squaresFour"`), or `null` if
/// the sheet was dismissed without picking. The caller should treat a
/// returned name of [kDefaultLayoutIconName] the same as `null` if they
/// want to persist "no preference" — both render the same default glyph.
Future<String?> showLayoutIconPicker(
  BuildContext context, {
  String? selected,
}) async {
  final result = await showIconEmojiPicker(
    context,
    title: 'Pick an icon',
    selectedIconName: selected,
    icons: [
      for (final i in kLayoutIcons)
        PickerIcon(name: i.name, icon: i.icon, label: i.label),
    ],
  );
  return result is PickerIconResult ? result.name : null;
}
