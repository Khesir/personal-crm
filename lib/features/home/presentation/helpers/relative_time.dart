const _minutesPerHour = 60;
const _hoursPerDay = 24;
const _daysPerWeek = 7;

String formatRelativeTime(DateTime dateTime, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final difference = reference.difference(dateTime);

  if (difference.inSeconds < _minutesPerHour) return 'now';
  if (difference.inMinutes < _minutesPerHour) return '${difference.inMinutes}m';
  if (difference.inHours < _hoursPerDay) return '${difference.inHours}h';

  final referenceDay = DateTime(reference.year, reference.month, reference.day);
  final dateTimeDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final dayDifference = referenceDay.difference(dateTimeDay).inDays;

  if (dayDifference == 1) return 'Yesterday';
  if (dayDifference < _daysPerWeek) return '${dayDifference}d';

  final weeks = dayDifference ~/ _daysPerWeek;
  if (dayDifference < _daysPerWeek * 4) return '${weeks}w';

  return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
}
