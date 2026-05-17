import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_content/weather_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/block_with_title.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/collapsible_carousel_block.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
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

class WeatherManualWidget extends StatelessWidget {
  const WeatherManualWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
    this.onInteractionLockChanged,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;
  final void Function(String blockId, bool locked)? onInteractionLockChanged;

  @override
  Widget build(BuildContext context) {
    final settings = AppDependencies.of(context).blockSettings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => BlockWithTitle(
        title: settings.weatherTitle,
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final selected = WeatherBlockContent.fromMap(data.content).conditionId;

    if (mode == BlockMode.readOnly) {
      return _buildCollapsed(context, selected);
    }

    return CollapsibleCarouselBlock<String>(
      blockId: data.id,
      options: weatherConditionIds,
      selected: selected,
      collapsedBuilder: _buildCollapsed,
      itemBuilder: (ctx, id, isSelected) => AnimatedScale(
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
      onSelected: (id) => onChanged?.call(
        JournalBlockData.create(
          id: data.id,
          type: data.type,
          content: WeatherBlockContent(conditionId: id).toMap(),
        ),
      ),
      onInteractionLockChanged: onInteractionLockChanged,
    );
  }

  Widget _buildCollapsed(BuildContext context, String? conditionId) {
    if (conditionId == null) {
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
        weatherIconFor(conditionId, selected: true),
        size: 64,
      ),
    );
  }
}
