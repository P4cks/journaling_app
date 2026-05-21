import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/model/block_content/weather_api_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/services/weather_service.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/weather_manual/weather_manual_widget.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Fetches current weather via [WeatherService] (Open-Meteo + geolocator)
/// and bakes the result into the entry's content the first time it
/// renders. Reuses the manual weather block's HugeIcons icon mapping.
class WeatherApiWidget extends StatefulWidget {
  const WeatherApiWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
    this.onDoubleTap,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;

  /// Host's "push expanded route" callback — fires on double-tap.
  /// Display-only block; no single-tap engage.
  final VoidCallback? onDoubleTap;

  @override
  State<WeatherApiWidget> createState() => _WeatherApiWidgetState();
}

class _WeatherApiWidgetState extends State<WeatherApiWidget> {
  bool _fetching = false;
  WeatherFetchStatus? _failureStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeFetch();
  }

  void _maybeFetch() {
    final content = WeatherApiBlockContent.fromMap(widget.data.content);
    // Trigger a fetch on the usual "no weather yet" path, but also
    // when the weather is already stored without a cityName — that's
    // the legacy shape from before reverse-geocoding shipped, and we
    // want to backfill the city without forcing the user to re-create
    // the entry.
    final needsCityBackfill = content.isFetched && content.cityName == null;
    if ((content.isFetched && !needsCityBackfill) || _fetching) return;
    _fetching = true;
    final service = AppDependencies.of(context).weatherService;
    service.getCurrentWeather().then((result) {
      if (!mounted) return;
      _fetching = false;
      if (!result.isOk) {
        setState(() => _failureStatus = result.status);
        return;
      }
      _failureStatus = null;
      widget.onChanged?.call(
        widget.data.copyWith(
          content: WeatherApiBlockContent(
            conditionId: result.conditionId,
            temperatureC: result.temperatureC,
            cityName: result.cityName,
            fetchedDate: result.fetchedDate,
          ).toMap(),
        ),
      );
    });
  }

  void _retry() {
    setState(() => _failureStatus = null);
    _fetching = false;
    _maybeFetch();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = WeatherApiBlockContent.fromMap(widget.data.content);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: widget.onDoubleTap,
      child: _buildBody(context, theme, content),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    WeatherApiBlockContent content,
  ) {
    if (content.isFetched) {
      final temp = content.temperatureC;
      final city = content.cityName;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              weatherIconFor(content.conditionId!, selected: true),
              size: 56,
            ),
            if (temp != null) ...[
              const SizedBox(height: 6),
              Text(
                '${temp.round()}°C',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                (city == null || city.isEmpty) ? '—' : city,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: (city == null || city.isEmpty)
                      ? theme.disabledColor
                      : theme.colorScheme.onSurfaceVariant,
                  fontStyle: (city == null || city.isEmpty)
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    if (_failureStatus != null) {
      final (message, retryLabel) = _messageFor(_failureStatus!);
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: _retry,
              icon: AppIcon(HugeIcons.strokeRoundedRefresh, size: 14),
              label: Text(retryLabel),
            ),
          ],
        ),
      );
    }

    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  (String, String) _messageFor(WeatherFetchStatus status) {
    switch (status) {
      case WeatherFetchStatus.permissionDenied:
        return ('Enable location to get today’s weather.', 'Grant');
      case WeatherFetchStatus.locationDisabled:
        return ('Location services are off.', 'Retry');
      case WeatherFetchStatus.networkFailure:
        return ('Couldn’t fetch weather.', 'Retry');
      case WeatherFetchStatus.ok:
        return ('', '');
    }
  }
}
