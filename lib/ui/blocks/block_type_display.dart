import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';

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
        return Icons.text_fields;
      case BlockType.moodTracker:
        return Icons.sentiment_satisfied;
    }
  }
}
