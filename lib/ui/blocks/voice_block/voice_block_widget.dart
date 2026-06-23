import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/model/block_content/voice_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/services/audio_storage_service.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/block_options_button.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_button.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/theme/color_hex.dart';
import 'package:journaling_app_rewrite/ui/theme/tonal.dart';
import 'package:record/record.dart';

/// Hard cap on a single voice note. The recorder auto-stops here so a
/// forgotten recording can't grow without bound (GUS-12).
const Duration kMaxVoiceDuration = Duration(seconds: 60);

/// A 1×1 voice-note block. Empty state shows a "Record voice" affordance
/// that opens a recording sheet; once recorded, the cell hosts an inline
/// play/pause control with a scrubbing progress bar. The Re-record /
/// Remove sheet is reached via the top-right [BlockOptionsButton] —
/// long-press is left free for `BlockGrid`'s drag-to-reorder (GUS-76).
/// Double-tap pushes the expanded route.
///
/// Unlike the photo block this is **not** an action block — the filled
/// cell hosts a sustained interactive player rather than firing a
/// one-shot action, and the expanded route renders that same player (see
/// `BlockTypeDisplay.isActionBlock`).
class VoiceBlockWidget extends StatefulWidget {
  const VoiceBlockWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
    this.onDoubleTap,
    this.expanded = false,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;

  /// Host's "push expanded route" callback — fires on double-tap.
  final VoidCallback? onDoubleTap;

  /// True when rendered inside the expanded route — suppresses the
  /// top-right options button (re-record / remove stay reachable from
  /// the in-grid tile).
  final bool expanded;

  @override
  State<VoiceBlockWidget> createState() => _VoiceBlockWidgetState();
}

class _VoiceBlockWidgetState extends State<VoiceBlockWidget> {
  Future<void> _record({String? previousPath}) async {
    final onChanged = widget.onChanged;
    if (onChanged == null) return;
    final storage = AppDependencies.of(context).audioStorage;
    final result = await showVoiceRecorderSheet(context, storage);
    if (result == null || !mounted) return;
    // Drop the old clip only once the new one is captured.
    if (previousPath != null && previousPath != result.path) {
      storage.deleteAtPath(previousPath);
    }
    onChanged(
      widget.data.copyWith(
        content: VoiceBlockContent(
          audioPath: result.path,
          durationMs: result.durationMs,
        ).toMap(),
      ),
    );
  }

  Future<void> _manage() async {
    final onChanged = widget.onChanged;
    if (onChanged == null) return;
    final content = VoiceBlockContent.fromMap(widget.data.content);
    final currentPath = content.audioPath;
    if (currentPath == null) return;
    final action = await _showManageSheet(context);
    if (action == null || !mounted) return;
    switch (action) {
      case 'rerecord':
        await _record(previousPath: currentPath);
        break;
      case 'remove':
        AppDependencies.of(context).audioStorage.deleteAtPath(currentPath);
        onChanged(
          widget.data.copyWith(content: const VoiceBlockContent().toMap()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = VoiceBlockContent.fromMap(widget.data.content);

    if (!content.hasAudio) {
      if (widget.mode == BlockMode.readOnly) {
        return _centeredHint(theme, 'No recording');
      }
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onChanged == null ? null : () => _record(),
        onDoubleTap: widget.onDoubleTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  HugeIcons.strokeRoundedMic01,
                  size: 32,
                  color: blockInk(context),
                ),
                const SizedBox(height: 4),
                Text(
                  'Record voice',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: blockInk(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final player = _VoicePlayer(
      key: ValueKey('voice-player-${content.audioPath}'),
      path: content.audioPath!,
      durationMs: content.durationMs,
    );

    if (widget.mode == BlockMode.readOnly) {
      return Padding(padding: const EdgeInsets.all(12), child: player);
    }

    // The inner play/pause InkWell wins single taps; the outer detector
    // catches double-tap (expand). Long-press is left free for
    // `BlockGrid`'s drag-to-reorder; the Re-record / Remove sheet is
    // reached via the top-right options button instead (GUS-76).
    final body = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: widget.onDoubleTap,
      child: Padding(padding: const EdgeInsets.all(12), child: player),
    );

    if (widget.onChanged == null || widget.expanded) return body;

    return Stack(
      fit: StackFit.expand,
      children: [
        body,
        Positioned(
          top: 4,
          right: 4,
          child: BlockOptionsButton(onPressed: _manage),
        ),
      ],
    );
  }

  Widget _centeredHint(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.all(12),
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.disabledColor,
        ),
      ),
    ),
  );
}

Future<String?> _showManageSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: AppIcon(HugeIcons.strokeRoundedMic01),
              title: const Text('Re-record'),
              onTap: () => Navigator.of(sheetContext).pop('rerecord'),
            ),
            ListTile(
              leading: AppIcon(
                HugeIcons.strokeRoundedDelete02,
                color: Theme.of(sheetContext).colorScheme.error,
              ),
              title: Text(
                'Remove',
                style: TextStyle(
                  color: Theme.of(sheetContext).colorScheme.error,
                ),
              ),
              onTap: () => Navigator.of(sheetContext).pop('remove'),
            ),
          ],
        ),
      );
    },
  );
}

/// Inline audio player for a recorded clip. Shows a play/pause button, a
/// progress bar, and an elapsed / total time readout. Owns its own
/// [AudioPlayer] for the widget's lifetime.
class _VoicePlayer extends StatefulWidget {
  const _VoicePlayer({super.key, required this.path, this.durationMs});

  final String path;
  final int? durationMs;

  @override
  State<_VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<_VoicePlayer> {
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<dynamic>> _subs = [];

  bool _playing = false;
  Duration _position = Duration.zero;
  Duration? _total;

  @override
  void initState() {
    super.initState();
    _total = widget.durationMs == null
        ? null
        : Duration(milliseconds: widget.durationMs!);
    _subs.add(
      _player.onPositionChanged.listen((p) {
        if (mounted) setState(() => _position = p);
      }),
    );
    _subs.add(
      _player.onDurationChanged.listen((d) {
        if (mounted && d > Duration.zero) setState(() => _total = d);
      }),
    );
    _subs.add(
      _player.onPlayerStateChanged.listen((state) {
        if (mounted) setState(() => _playing = state == PlayerState.playing);
      }),
    );
    _subs.add(
      _player.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _playing = false;
            _position = Duration.zero;
          });
        }
      }),
    );
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
    } else {
      // Resume from a paused position; otherwise (re)start from source.
      if (_position > Duration.zero && _player.state == PlayerState.paused) {
        await _player.resume();
      } else {
        await _player.play(DeviceFileSource(widget.path));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _total ?? Duration.zero;
    final progress = total.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    final label = total == Duration.zero
        ? _format(_position)
        : '${_format(_position)} / ${_format(total)}';

    // Tonal ink so the inline player reads on-hue on a coloured block (GUS-86).
    final ink = blockInk(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: ink,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: AppIcon(
                  _playing
                      ? HugeIcons.strokeRoundedPause
                      : HugeIcons.strokeRoundedPlay,
                  size: 24,
                  color: contrastOn(ink),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                color: ink,
                backgroundColor: ink.withValues(alpha: 0.18),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: ink.withValues(alpha: 0.7),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Result of a completed recording session.
class VoiceRecording {
  const VoiceRecording({required this.path, required this.durationMs});
  final String path;
  final int durationMs;
}

/// Opens the modal recording sheet. Returns the captured [VoiceRecording]
/// on stop, or `null` if the user cancelled or permission was denied.
Future<VoiceRecording?> showVoiceRecorderSheet(
  BuildContext context,
  AudioStorageService storage,
) {
  return showModalBottomSheet<VoiceRecording>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    builder: (sheetContext) => _RecorderSheet(storage: storage),
  );
}

class _RecorderSheet extends StatefulWidget {
  const _RecorderSheet({required this.storage});

  final AudioStorageService storage;

  @override
  State<_RecorderSheet> createState() => _RecorderSheetState();
}

class _RecorderSheetState extends State<_RecorderSheet> {
  final AudioRecorder _recorder = AudioRecorder();

  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  String? _path;
  bool _recording = false;
  bool _starting = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) {
          setState(() {
            _starting = false;
            _error = 'Microphone permission is required to record.';
          });
        }
        return;
      }
      final path = await widget.storage.newRecordingPath();
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      if (!mounted) return;
      setState(() {
        _path = path;
        _recording = true;
        _starting = false;
      });
      _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!mounted) return;
        setState(() => _elapsed += const Duration(milliseconds: 100));
        if (_elapsed >= kMaxVoiceDuration) {
          _stop();
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _starting = false;
          _error = 'Could not start recording.';
        });
      }
    }
  }

  Future<void> _stop() async {
    if (!_recording) return;
    _recording = false;
    _ticker?.cancel();
    final measured = _elapsed;
    String? outPath;
    try {
      outPath = await _recorder.stop();
    } catch (_) {
      outPath = _path;
    }
    final path = outPath ?? _path;
    if (!mounted) return;
    if (path == null) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pop(
      VoiceRecording(path: path, durationMs: measured.inMilliseconds),
    );
  }

  Future<void> _cancel() async {
    _recording = false;
    _ticker?.cancel();
    try {
      await _recorder.stop();
    } catch (_) {
      // ignore
    }
    final path = _path;
    if (path != null) {
      widget.storage.deleteAtPath(path);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        (_elapsed.inMilliseconds / kMaxVoiceDuration.inMilliseconds).clamp(
          0.0,
          1.0,
        );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              AppIcon(
                HugeIcons.strokeRoundedMicOff01,
                size: 36,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              AppButton(
                variant: AppButtonVariant.primary,
                onPressed: () => Navigator.of(context).pop(),
                label: 'Close',
              ),
            ] else if (_starting) ...[
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: 16),
              Text('Preparing…', style: theme.textTheme.bodyMedium),
            ] else ...[
              Text(
                _format(_elapsed),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'max ${_format(kMaxVoiceDuration)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  color: theme.colorScheme.error,
                  backgroundColor: theme.colorScheme.error.withValues(
                    alpha: 0.18,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  AppButton(
                    variant: AppButtonVariant.text,
                    onPressed: _cancel,
                    label: 'Cancel',
                  ),
                  AppButton(
                    variant: AppButtonVariant.primary,
                    onPressed: _stop,
                    icon: HugeIcons.strokeRoundedStop,
                    label: 'Stop',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _format(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
