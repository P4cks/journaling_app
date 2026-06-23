import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/icon_emoji_picker.dart';
import 'package:journaling_app_rewrite/ui/layouts/layout_icons.dart';

/// Modal bottom sheet that lets the user pick an emoji or an icon for a
/// layout.
///
/// Thin wrapper over the shared [showIconEmojiPicker] (Emoji + Icon tabs via
/// `allowEmoji: true`, GUS-82) mapping [kLayoutIcons] to [PickerIcon]s.
/// Returns the chosen icon's `name` (a stable ASCII identifier like
/// `"squaresFour"`) **or** the chosen emoji glyph (e.g. `"😀"`) — both are
/// persisted verbatim in `JournalLayout.iconName` and disambiguated at render
/// time by `isEmojiValue`. Returns `null` if the sheet was dismissed without
/// picking. The caller should treat a returned name of [kDefaultLayoutIconName]
/// the same as `null` if they want to persist "no preference" — both render
/// the same default glyph.
Future<String?> showLayoutIconPicker(
  BuildContext context, {
  String? selected,
}) async {
  final result = await showIconEmojiPicker(
    context,
    title: 'Pick an emoji or icon',
    allowEmoji: true,
    selectedIconName: selected,
    icons: [
      for (final i in kLayoutIcons)
        PickerIcon(name: i.name, icon: i.icon, label: i.label),
    ],
  );
  return switch (result) {
    PickerIconResult(:final name) => name,
    PickerEmojiResult(:final emoji) => emoji,
    _ => null,
  };
}
