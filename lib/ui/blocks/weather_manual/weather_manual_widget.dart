import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_content/weather_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

IconData weatherIconFor(String conditionId, {required bool selected}) {
  switch (conditionId) {
    case 'sun':
      return selected ? PhosphorIconsFill.sun : PhosphorIconsDuotone.sun;
    case 'partly_cloudy':
      return selected
          ? PhosphorIconsFill.cloudSun
          : PhosphorIconsDuotone.cloudSun;
    case 'cloud':
      return selected ? PhosphorIconsFill.cloud : PhosphorIconsDuotone.cloud;
    case 'rain':
      return selected
          ? PhosphorIconsFill.cloudRain
          : PhosphorIconsDuotone.cloudRain;
    case 'thunderstorm':
      return selected
          ? PhosphorIconsFill.cloudLightning
          : PhosphorIconsDuotone.cloudLightning;
    case 'snow':
      return selected
          ? PhosphorIconsFill.snowflake
          : PhosphorIconsDuotone.snowflake;
    case 'fog':
      return selected
          ? PhosphorIconsFill.cloudFog
          : PhosphorIconsDuotone.cloudFog;
    default:
      return PhosphorIconsDuotone.question;
  }
}

class WeatherManualWidget extends StatefulWidget {
  const WeatherManualWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;

  @override
  State<WeatherManualWidget> createState() => _WeatherManualWidgetState();
}

class _WeatherManualWidgetState extends State<WeatherManualWidget> {
  late final PageController _controller;

  int get _initialIndex {
    final id = WeatherBlockContent.fromMap(widget.data.content).conditionId;
    final idx = id == null ? -1 : weatherConditionIds.indexOf(id);
    return idx < 0 ? 0 : idx;
  }

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: _initialIndex,
      viewportFraction: 0.42,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _emit(String? id) {
    widget.onChanged?.call(
      JournalBlockData.create(
        id: widget.data.id,
        type: widget.data.type,
        content: WeatherBlockContent(conditionId: id).toMap(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = WeatherBlockContent.fromMap(widget.data.content);

    if (widget.mode == BlockMode.readOnly) {
      if (content.conditionId == null) {
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
      return Center(
        child: AppIcon(
          weatherIconFor(content.conditionId!, selected: true),
          size: 64,
        ),
      );
    }

    final selected = content.conditionId;

    return PageView.builder(
      controller: _controller,
      itemCount: weatherConditionIds.length,
      onPageChanged: (index) {
        FocusScope.of(context).unfocus();
        _emit(weatherConditionIds[index]);
      },
      itemBuilder: (context, index) {
        final id = weatherConditionIds[index];
        final isSelected = id == selected;
        return Center(
          child: AnimatedScale(
            scale: isSelected ? 1.0 : 0.6,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.45,
              duration: const Duration(milliseconds: 180),
              child: AppIcon(
                weatherIconFor(id, selected: isSelected),
                size: 64,
              ),
            ),
          ),
        );
      },
    );
  }
}
