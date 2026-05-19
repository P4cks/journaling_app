import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/model/block_content/weather_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/carousel_block_scaffold.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Resolve a `conditionId` (e.g. `'sun'`) to its HugeIcons glyph. The
/// `selected` parameter is retained for call-site compatibility — the
/// free HugeIcons package only ships the stroke-rounded family, so the
/// glyph is the same regardless. Selection state should be communicated
/// via colour instead.
HugeIconData weatherIconFor(String conditionId, {required bool selected}) {
  switch (conditionId) {
    case 'sun':
      return HugeIcons.strokeRoundedSun01;
    case 'partly_cloudy':
      return HugeIcons.strokeRoundedSunCloud01;
    case 'cloud':
      return HugeIcons.strokeRoundedCloud;
    case 'rain':
      return HugeIcons.strokeRoundedCloudMidRain;
    case 'thunderstorm':
      return HugeIcons.strokeRoundedCloudAngledZap;
    case 'snow':
      return HugeIcons.strokeRoundedSnow;
    case 'fog':
      return HugeIcons.strokeRoundedCloudFastWind;
    default:
      return HugeIcons.strokeRoundedQuestion;
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
