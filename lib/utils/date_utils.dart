class AppDateUtils {
  /// Safely parse DateTime from dynamic value with consistent timezone handling
  static DateTime safeParseDate(dynamic value) {
    if (value == null) return DateTime.now();
    final s = value.toString();
    final dt = DateTime.tryParse(s);
    return (dt ?? DateTime.now()).toLocal();
  }

  /// Format DateTime to Vietnamese date string
  static String formatVietnameseDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }

  /// Format DateTime to Vietnamese time string
  static String formatVietnameseTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Format DateTime to Vietnamese date and time string
  static String formatVietnameseDateTime(DateTime dateTime) {
    return '${formatVietnameseDate(dateTime)} ${formatVietnameseTime(dateTime)}';
  }

  /// Check if two DateTime objects represent the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Get time difference in hours between two DateTime objects
  static double getHoursDifference(DateTime date1, DateTime date2) {
    return date1.difference(date2).inHours.toDouble();
  }
}
