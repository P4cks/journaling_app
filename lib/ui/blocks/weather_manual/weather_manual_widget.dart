import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_content/weather_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/carousel_block_scaffold.dart';
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
      builder: (context, _) => CarouselBlockScaffold<String>(
        blockId: data.id,
        mode: mode,
        title: settings.carouselTitlesEnabled ? "Today's weather" : null,
        options: weatherConditionIds,
        selected: WeatherBlockContent.fromMap(data.content).conditionId,
        itemBuilder: (ctx, id, isSelected) =>
            AppIcon(weatherIconFor(id, selected: isSelected), size: 64),
        onSelected: (id) => onChanged?.call(
          data.copyWith(content: WeatherBlockContent(conditionId: id).toMap()),
        ),
        onInteractionLockChanged: onInteractionLockChanged,
      ),
    );
  }
}
