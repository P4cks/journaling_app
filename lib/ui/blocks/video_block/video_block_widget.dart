import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:journaling_app_rewrite/data/model/block_content/video_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/block_options_button.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/theme/tonal.dart';
import 'package:video_player/video_player.dart';

/// Fires the video block's primary action — opens the capture / manage
/// sheet without mounting any widget. Mirrors `firePhotoBlockAction`:
/// called by the host when an action block is engaged with "expand on
/// edit" OFF, and reused by the in-grid widget's own taps so the picker
/// logic is single-sourced.
Future<void> fireVideoBlockAction(
  BuildContext context,
  JournalBlockData data,
  ValueChanged<JournalBlockData> onChanged,
) async {
  final content = VideoBlockContent.fromMap(data.content);
  final storage = AppDependencies.of(context).videoStorage;
  final picker = ImagePicker();

  Future<void> emit(
    String? newPath, {
    int? durationMs,
    String? previousPath,
  }) async {
    if (previousPath != null && previousPath != newPath) {
      storage.deleteAtPath(previousPath);
    }
    onChanged(
      data.copyWith(
        content: VideoBlockContent(
          videoPath: newPath,
          durationMs: durationMs,
        ).toMap(),
      ),
    );
  }

  Future<void> pick(ImageSource source, {String? previousPath}) async {
    final picked = await picker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 10),
    );
    if (picked == null || !context.mounted) return;
    final stored = await storage.savePickedFile(picked);
    final durationMs = await _readDurationMs(stored);
    if (!context.mounted) return;
    await emit(stored, durationMs: durationMs, previousPath: previousPath);
  }

  if (!content.hasVideo) {
    final source = await _showVideoSourceSheet(context);
    if (source != null && context.mounted) {
      await pick(source);
    }
    return;
  }

  final manage = await _showVideoManageSheet(context);
  if (!context.mounted) return;
  final currentPath = content.videoPath!;
  switch (manage) {
    case 'play':
      await _showFullscreenPlayer(context, currentPath);
      break;
    case 'replace':
      final source = await _showVideoSourceSheet(context);
      if (source != null && context.mounted) {
        await pick(source, previousPath: currentPath);
      }
      break;
    case 'remove':
      await emit(null, previousPath: currentPath);
      break;
  }
}

/// Reads the clip duration off the saved file by briefly initialising a
/// throwaway controller. Returns null on any failure (badly muxed file,
/// codec the platform can't probe) — the badge just won't render.
Future<int?> _readDurationMs(String path) async {
  final controller = VideoPlayerController.file(File(path));
  try {
    await controller.initialize();
    final ms = controller.value.duration.inMilliseconds;
    return ms > 0 ? ms : null;
  } catch (_) {
    return null;
  } finally {
    await controller.dispose();
  }
}

Future<ImageSource?> _showVideoSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: AppIcon(HugeIcons.strokeRoundedVideo01),
              title: const Text('Record video'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: AppIcon(HugeIcons.strokeRoundedImage01),
              title: const Text('Choose from library'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      );
    },
  );
}

Future<String?> _showVideoManageSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: AppIcon(HugeIcons.strokeRoundedPlay),
              title: const Text('Play'),
              onTap: () => Navigator.of(sheetContext).pop('play'),
            ),
            ListTile(
              leading: AppIcon(HugeIcons.strokeRoundedExchange01),
              title: const Text('Replace'),
              onTap: () => Navigator.of(sheetContext).pop('replace'),
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

Future<void> _showFullscreenPlayer(BuildContext context, String path) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FullscreenVideoPlayer(path: path),
    ),
  );
}

String _formatDuration(int ms) {
  final totalSeconds = (ms / 1000).round();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// One clip filling the 1×1 cell. Empty state shows a centred "+ Add
/// video" affordance that opens a Record / Library action sheet. Once
/// set, the cell renders the poster frame with a play overlay; the
/// Play / Replace / Remove sheet is reached via the top-right
/// [BlockOptionsButton] — long-press is left free for `BlockGrid`'s
/// drag-to-reorder (GUS-76). Double-tap still expands.
class VideoBlockWidget extends StatelessWidget {
  const VideoBlockWidget({
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
  /// top-right options button (the route fires the action on body tap).
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = VideoBlockContent.fromMap(data.content);

    if (!content.hasVideo) {
      if (mode == BlockMode.readOnly) {
        // Video glyph + label, not bare "No video" text, so the block is
        // recognizable as a video block in previews like the layout
        // editor (GUS-73).
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  HugeIcons.strokeRoundedVideo01,
                  size: 28,
                  color: theme.disabledColor,
                ),
                const SizedBox(height: 4),
                Text(
                  'Video',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.disabledColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null
            ? null
            : () => fireVideoBlockAction(context, data, onChanged!),
        onDoubleTap: onDoubleTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  HugeIcons.strokeRoundedVideo01,
                  size: 32,
                  color: blockInk(context),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add video',
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

    final poster = _VideoPoster(
      path: content.videoPath!,
      durationMs: content.durationMs,
    );

    if (mode == BlockMode.readOnly) {
      // Read-only previews (e.g. memory block, add-block sheet) still
      // get the poster, but tapping plays the clip fullscreen.
      return Padding(
        padding: const EdgeInsets.all(12),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showFullscreenPlayer(context, content.videoPath!),
          child: poster,
        ),
      );
    }

    // Double-tap pushes the expanded route. Long-press is intentionally
    // NOT handled here so it falls through to `BlockGrid`'s
    // `LongPressDraggable` (drag-to-reorder); the manage sheet is reached
    // via the top-right options button instead (GUS-76).
    final body = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: onDoubleTap,
      child: Padding(padding: const EdgeInsets.all(12), child: poster),
    );

    if (onChanged == null || expanded) return body;

    return Stack(
      fit: StackFit.expand,
      children: [
        body,
        Positioned(
          top: 4,
          right: 4,
          child: BlockOptionsButton(
            onPressed: () => fireVideoBlockAction(context, data, onChanged!),
          ),
        ),
      ],
    );
  }
}

/// Renders the first frame of [path] as a static poster with a centred
/// play glyph and an optional duration badge. Keeps a single controller
/// alive only long enough to paint frame 0 (paused).
class _VideoPoster extends StatefulWidget {
  const _VideoPoster({required this.path, this.durationMs});

  final String path;
  final int? durationMs;

  @override
  State<_VideoPoster> createState() => _VideoPosterState();
}

class _VideoPosterState extends State<_VideoPoster> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(_VideoPoster oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _controller?.dispose();
      _controller = null;
      _failed = false;
      _init();
    }
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.file(File(widget.path));
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = _controller;

    final Widget frame;
    if (_failed) {
      frame = ColoredBox(
        color: Colors.black,
        child: Center(
          child: Text(
            'Video missing',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: Colors.white70,
            ),
          ),
        ),
      );
    } else if (controller != null && controller.value.isInitialized) {
      frame = FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    } else {
      frame = const ColoredBox(
        color: Colors.black,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            frame,
            if (!_failed)
              const Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.play_arrow, color: Colors.white, size: 28),
                  ),
                ),
              ),
            if (widget.durationMs != null && !_failed)
              Positioned(
                right: 6,
                bottom: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Text(
                      _formatDuration(widget.durationMs!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Fullscreen tap-to-toggle player pushed from the Play action. Auto-plays
/// on open; tapping the surface toggles play/pause.
class _FullscreenVideoPlayer extends StatefulWidget {
  const _FullscreenVideoPlayer({required this.path});

  final String path;

  @override
  State<_FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<_FullscreenVideoPlayer> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path));
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _controller.play();
    });
    _controller.addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _toggle() {
    if (!_ready) return;
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: _ready
            ? GestureDetector(
                onTap: _toggle,
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_controller),
                      VideoProgressIndicator(_controller, allowScrubbing: true),
                      if (!_controller.value.isPlaying)
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
