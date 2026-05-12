import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';

/// Text-block-global configuration: an optional character limit applied
/// to every text block in every entry. Leaving the field empty removes
/// the limit.
class TextBlockSettingsScreen extends StatefulWidget {
  const TextBlockSettingsScreen({super.key});

  @override
  State<TextBlockSettingsScreen> createState() =>
      _TextBlockSettingsScreenState();
}

class _TextBlockSettingsScreenState extends State<TextBlockSettingsScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _initialized = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final limit = AppDependencies.of(context).blockSettings.textCharLimit;
    _controller.text = limit?.toString() ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _controller.text.trim();
    final settings = AppDependencies.of(context).blockSettings;
    if (raw.isEmpty) {
      await settings.setTextCharLimit(null);
      if (!mounted) return;
      _showSaved();
      return;
    }
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      setState(() {
        _error = 'Enter a positive whole number, or leave blank.';
      });
      return;
    }
    setState(() => _error = null);
    await settings.setTextCharLimit(parsed);
    if (!mounted) return;
    _showSaved();
  }

  void _showSaved() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Text block')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Character limit',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Applied to every text block. Leave blank for no limit.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Limit',
                hintText: 'e.g. 200',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
