enum BlockType {
  textBlock,
  moodTracker,
  weatherManual,
  promptBlock,
  todoBlock,
  quoteBlock,
  memoryBlock,
  weatherApi,
  photoBlock,
  // New values MUST be appended at the end — Hive serializes enum
  // values by index, so reordering or inserting would corrupt existing
  // entries on disk.
  locationBlock,
  customCarousel,
  habitTracker,
  streakBlock,
  videoBlock,
}
