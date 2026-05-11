import 'package:flutter/widgets.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

extension BlockTypeDisplay on BlockType {
  String get label {
    switch (this) {
      case BlockType.textBlock:
        return 'Text';
      case BlockType.moodTracker:
        return 'Mood Tracker';
    }
  }

  IconData get icon {
    switch (this) {
      case BlockType.textBlock:
        return PhosphorIconsDuotone.textAa;
      case BlockType.moodTracker:
        return PhosphorIconsDuotone.smiley;
    }
  }
}
