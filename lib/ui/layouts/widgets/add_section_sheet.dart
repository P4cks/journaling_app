import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/section_kind.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Picked-section descriptor returned by [showAddSectionSheet].
class AddSectionResult {
  const AddSectionResult({required this.kind, this.rows});
  final SectionKind kind;
  final int? rows;
}

/// Allowed row counts for a block-grid section in the custom-layout editor.
const List<int> kAllowedSectionRows = [1, 2, 3, 4];

/// Modal bottom sheet that picks a new section type — text or
/// block-grid (with row count). Returns the picked descriptor or
/// `null` on dismiss.
Future<AddSectionResult?> showAddSectionSheet(BuildContext context) {
  return showModalBottomSheet<AddSectionResult>(
    context: context,
    builder: (sheetContext) => const _AddSectionBody(),
  );
}

class _AddSectionBody extends StatefulWidget {
  const _AddSectionBody();

  @override
  State<_AddSectionBody> createState() => _AddSectionBodyState();
}

class _AddSectionBodyState extends State<_AddSectionBody> {
  bool _pickingRows = false;
  int _rows = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _pickingRows ? 'Block grid — how many rows?' : 'Add a section',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
          if (_pickingRows)
            _buildRowPicker(theme)
          else
            _buildKindPicker(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildKindPicker() {
    return Column(
      children: [
        ListTile(
          leading: const AppIcon(PhosphorIconsDuotone.textT),
          title: const Text('Text section'),
          subtitle: const Text('A full-width multi-line text area.'),
          onTap: () =>
              Navigator.of(context).pop(const AddSectionResult(kind: SectionKind.text)),
        ),
        ListTile(
          leading: const AppIcon(PhosphorIconsDuotone.squaresFour),
          title: const Text('Block grid'),
          subtitle: const Text(
            'A 2-column grid of 1×1 blocks. Choose 1–4 rows.',
          ),
          onTap: () => setState(() => _pickingRows = true),
        ),
      ],
    );
  }

  Widget _buildRowPicker(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<int>(
            segments: [
              for (final r in kAllowedSectionRows)
                ButtonSegment(value: r, label: Text('$r')),
            ],
            selected: {_rows},
            onSelectionChanged: (sel) => setState(() => _rows = sel.first),
          ),
          const SizedBox(height: 8),
          Text(
            '${2 * _rows} block slot${_rows == 1 ? '' : 's'} (2 columns × $_rows row${_rows == 1 ? '' : 's'}).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _pickingRows = false),
                child: const Text('Back'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(
                  AddSectionResult(kind: SectionKind.blockGrid, rows: _rows),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
