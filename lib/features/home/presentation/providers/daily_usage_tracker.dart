/// Daily usage tracker — tracks free-tier brainstorm usage per day.
library;


import 'package:hive/hive.dart';

class DailyUsageTracker {
  static const String _boxName = 'daily_usage';
  static const String _countKey = 'count';
  static const String _dateKey = 'date';

  Future<Box<int>> _openBox() async {
    return await Hive.openBox<int>(_boxName);
  }

  /// Get the current day's count, resetting if the date has changed.
  Future<int> getDailyCount() async {
    final box = await _openBox();
    final storedDate = box.get(_dateKey);
    final today = DateTime.now();
    final todayKey = _dateKeyFor(today);

    if (storedDate == null || storedDate != todayKey) {
      // Reset for new day.
      await box.put(_dateKey, todayKey);
      await box.put(_countKey, 0);
      return 0;
    }

    return box.get(_countKey, defaultValue: 0) ?? 0;
  }

  /// Increment the daily count.
  Future<int> increment() async {
    final box = await _openBox();
    final count = await getDailyCount();
    final newCount = count + 1;
    await box.put(_countKey, newCount);
    return newCount;
  }

  /// Reset count to zero (for testing or manual reset).
  Future<void> reset() async {
    final box = await _openBox();
    await box.put(_countKey, 0);
  }

  int _dateKeyFor(DateTime date) {
    return date.year * 10000 + date.month * 100 + date.day;
  }
}
