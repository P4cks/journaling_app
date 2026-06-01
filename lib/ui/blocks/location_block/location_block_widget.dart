import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:journaling_app_rewrite/data/model/block_content/location_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:latlong2/latlong.dart';

/// Map block backed by flutter_map + OpenStreetMap tiles. In editable
/// mode the user long-presses on the map to drop (or move) a pin; the
/// resulting `LatLng` is persisted into the block content. In read-only
/// mode the map is non-interactive and shows the saved pin (or an
/// em-dash placeholder when no pin is stored).
class LocationBlockWidget extends StatefulWidget {
  const LocationBlockWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
    this.onDoubleTap,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;

  /// Host's "push expanded route" callback. Wired into a
  /// `GestureDetector(onDoubleTap, deferToChild)` over the map. The
  /// map's `InteractiveFlag.doubleTapZoom` is intentionally omitted
  /// so the double-tap gesture is free for us to claim — pinch + drag
  /// + scroll-wheel still work for zoom, and long-press still drops
  /// pins natively (deferToChild lets inner-widget recognizers win
  /// the gestures they want).
  final VoidCallback? onDoubleTap;

  @override
  State<LocationBlockWidget> createState() => _LocationBlockWidgetState();
}

class _LocationBlockWidgetState extends State<LocationBlockWidget> {
  static const _fallbackCenter = LatLng(20, 0);
  static const _fallbackZoom = 1.5;
  static const _pinZoom = 13.0;

  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(LocationBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the stored pin changed from outside (e.g. a layout-picker
    // confirm rewrote the entry, or the user pulled in a different
    // day's entry), recentre the map on the new pin.
    final oldPin = _pinOf(oldWidget.data);
    final newPin = _pinOf(widget.data);
    if (newPin != null && newPin != oldPin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(newPin, _pinZoom);
      });
    }
  }

  LatLng? _pinOf(JournalBlockData data) {
    final c = LocationBlockContent.fromMap(data.content);
    if (!c.hasPin) return null;
    return LatLng(c.latitude!, c.longitude!);
  }

  void _onLongPress(TapPosition tap, LatLng point) {
    if (widget.mode != BlockMode.editable) return;
    widget.onChanged?.call(
      widget.data.copyWith(
        content: LocationBlockContent(
          latitude: point.latitude,
          longitude: point.longitude,
        ).toMap(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pin = _pinOf(widget.data);
    final isEditable = widget.mode == BlockMode.editable;

    if (!isEditable && pin == null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Text(
            '—',
            style: TextStyle(
              fontSize: 40,
              color: Theme.of(context).disabledColor,
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      // `opaque` so taps in the 12 px chrome inset are claimed here
      // (and don't fall through to the body's tap-to-unfocus). The
      // map's own recognizers still win the gestures they care about
      // (drag, pinch-zoom, long-press) because they're more specific
      // than our single `onDoubleTap`. The map's
      // `InteractiveFlag.doubleTapZoom` is omitted below so our
      // handler wins double-taps. Single tap on the map area falls
      // through to a no-op — the user pans or long-presses instead.
      behavior: HitTestBehavior.opaque,
      onDoubleTap: widget.onDoubleTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: pin ?? _fallbackCenter,
                  initialZoom: pin != null ? _pinZoom : _fallbackZoom,
                  minZoom: 1,
                  maxZoom: 18,
                  onLongPress: isEditable ? _onLongPress : null,
                  interactionOptions: InteractionOptions(
                    // `doubleTapZoom` is intentionally OFF — the
                    // double-tap gesture is reserved for the host's
                    // "push expanded route" callback. Users can still
                    // zoom via pinch / scroll-wheel.
                    flags: isEditable
                        ? (InteractiveFlag.drag |
                              InteractiveFlag.pinchZoom |
                              InteractiveFlag.scrollWheelZoom)
                        : InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.journaling_app_rewrite',
                    maxNativeZoom: 19,
                  ),
                  if (pin != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: pin,
                          width: 32,
                          height: 32,
                          alignment: Alignment.topCenter,
                          child: AppIcon(
                            HugeIcons.strokeRoundedMapPin,
                            size: 32,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (isEditable && pin == null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: scheme.surface.withValues(alpha: 0.82),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Text(
                      'Long-press to drop a pin',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
