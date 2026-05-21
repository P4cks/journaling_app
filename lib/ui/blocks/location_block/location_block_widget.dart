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

  /// Host's "push expanded route" callback. Location is the one
  /// exception to the GestureDetector-everywhere rule — wrapping the
  /// FlutterMap in an opaque GestureDetector would steal its pan /
  /// pinch-zoom / double-tap-zoom gestures. Instead we use a raw
  /// `Listener` to spot a double-tap pattern without entering the
  /// arena; the map keeps every native interaction.
  final VoidCallback? onDoubleTap;

  @override
  State<LocationBlockWidget> createState() => _LocationBlockWidgetState();
}

class _LocationBlockWidgetState extends State<LocationBlockWidget> {
  static const _fallbackCenter = LatLng(20, 0);
  static const _fallbackZoom = 1.5;
  static const _pinZoom = 13.0;
  static const _doubleTapWindow = Duration(milliseconds: 300);
  static const _doubleTapSlop = 20.0;

  late final MapController _mapController;
  DateTime? _lastDownAt;
  Offset? _lastDownPos;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _onPointerDown(PointerDownEvent event) {
    final onDoubleTap = widget.onDoubleTap;
    if (onDoubleTap == null) return;
    final now = DateTime.now();
    final pos = event.position;
    final last = _lastDownAt;
    final lastPos = _lastDownPos;
    if (last != null &&
        lastPos != null &&
        now.difference(last) <= _doubleTapWindow &&
        (pos - lastPos).distance <= _doubleTapSlop) {
      _lastDownAt = null;
      _lastDownPos = null;
      onDoubleTap();
      return;
    }
    _lastDownAt = now;
    _lastDownPos = pos;
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
      return Center(
        child: Text(
          '—',
          style: TextStyle(
            fontSize: 40,
            color: Theme.of(context).disabledColor,
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
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
                flags: isEditable
                    ? (InteractiveFlag.drag |
                          InteractiveFlag.pinchZoom |
                          InteractiveFlag.doubleTapZoom |
                          InteractiveFlag.scrollWheelZoom)
                    : InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.example.journaling_app_rewrite',
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
    );
  }
}
