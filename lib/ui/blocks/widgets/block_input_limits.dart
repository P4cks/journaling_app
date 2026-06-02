import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/services/debug_settings.dart';

/// Hard-coded default input caps per editable block type.
///
/// These are the values shipped to users. The debug menu can override
/// any of them at runtime ([DebugSettings] nullable-int overrides) so we
/// can tune good values during testing — once a value is settled, bake it
/// back into the constant here and drop the matching debug override.
const int kTextBlockMaxChars = 280;
const int kTextSectionMaxChars = 280;
const int kPromptAnswerMaxChars = 280;
const int kTodoItemMaxChars = 80;
const int kTodoMaxItems = 8;

/// Effective input limits = debug override (when set) ?? hard-coded default.
///
/// Resolve once per build via [BlockInputLimits.of] and read the field you
/// need. Wrap the editable subtree in
/// `ListenableBuilder(listenable: debugSettings)` so live debug tuning
/// re-resolves and updates open blocks.
class BlockInputLimits {
  const BlockInputLimits({
    required this.textBlockChars,
    required this.textSectionChars,
    required this.promptChars,
    required this.todoItemChars,
    required this.todoMaxItems,
  });

  final int textBlockChars;
  final int textSectionChars;
  final int promptChars;
  final int todoItemChars;
  final int todoMaxItems;

  factory BlockInputLimits.of(DebugSettings debug) => BlockInputLimits(
    textBlockChars: debug.textBlockCharLimit ?? kTextBlockMaxChars,
    textSectionChars: debug.textSectionCharLimit ?? kTextSectionMaxChars,
    promptChars: debug.promptCharLimit ?? kPromptAnswerMaxChars,
    todoItemChars: debug.todoItemCharLimit ?? kTodoItemMaxChars,
    todoMaxItems: debug.todoMaxItems ?? kTodoMaxItems,
  );
}

/// Shared `TextField.buildCounter` that renders a compact
/// `current/limit` counter. Visible whenever the field is focused or
/// non-empty; hidden on an empty unfocused field to avoid clutter.
///
/// Pass [onlyWhenFocused] for dense layouts (e.g. todo rows) where the
/// counter should appear only on the actively-edited field.
Widget? Function(
  BuildContext, {
  required int currentLength,
  required bool isFocused,
  required int? maxLength,
})
buildCharCounter({bool onlyWhenFocused = false}) {
  return (
    context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) {
    if (maxLength == null) return null;
    final show = onlyWhenFocused ? isFocused : isFocused || currentLength > 0;
    if (!show) return null;
    final theme = Theme.of(context);
    final atCap = currentLength >= maxLength;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        '$currentLength/$maxLength',
        style: theme.textTheme.labelSmall?.copyWith(
          color: atCap
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  };
}
