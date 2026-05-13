import 'package:flutter/material.dart';

/// Centered message shown for a past day that never had an entry — the
/// user cannot create one (the day is locked) and there is nothing to
/// preview, so the body just explains the state.
class NoEntryReadOnly extends StatelessWidget {
  const NoEntryReadOnly({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No entry was made on this day.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.disabledColor,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
