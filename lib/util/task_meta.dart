import 'package:flutter/material.dart';

import '../models/todo_item.dart';

const List<String> _monthShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _two(int n) => n.toString().padLeft(2, '0');

String priorityLabel(TodoPriority p) {
  switch (p) {
    case TodoPriority.high:
      return 'High';
    case TodoPriority.medium:
      return 'Medium';
    case TodoPriority.low:
      return 'Low';
  }
  return 'Medium';
}

Color priorityColor(TodoPriority p) {
  switch (p) {
    case TodoPriority.high:
      return const Color(0xFFE5484D);
    case TodoPriority.medium:
      return const Color(0xFFF5A623);
    case TodoPriority.low:
      return const Color(0xFF3D9A70);
  }
  return const Color(0xFFF5A623);
}

String repeatLabel(RepeatRule r) {
  switch (r) {
    case RepeatRule.none:
      return 'None';
    case RepeatRule.daily:
      return 'Daily';
    case RepeatRule.weekly:
      return 'Weekly';
  }
  return 'None';
}

IconData categoryIcon(String category) {
  switch (category) {
    case 'Personal':
      return Icons.person_outline;
    case 'Work':
      return Icons.work_outline;
    case 'Shopping':
      return Icons.shopping_bag_outlined;
    case 'Health':
      return Icons.favorite_border;
    case 'Finance':
      return Icons.attach_money;
    default:
      return Icons.label_outline;
  }
}

/// '3 Nov' — with the year appended when it differs from the current year.
String formatDate(DateTime d) {
  final now = DateTime.now();
  final base = '${d.day} ${_monthShort[d.month - 1]}';
  return d.year == now.year ? base : '$base ${d.year}';
}

String formatTimeOfDay(int hour, int minute) => '${_two(hour)}:${_two(minute)}';

String formatTime(TimeOfDay t) => formatTimeOfDay(t.hour, t.minute);

String formatDateTime(DateTime d) =>
    '${formatDate(d)} · ${formatTimeOfDay(d.hour, d.minute)}';

/// Short label used on the due-date chip of a task tile.
String formatDueLabel(DateTime due, bool isDone) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(due.year, due.month, due.day);
  final time = formatTimeOfDay(due.hour, due.minute);
  if (dueDay == today) return 'Today · $time';
  if (!isDone && dueDay.isBefore(today)) {
    return 'Overdue · ${formatDate(due)}';
  }
  return '${formatDate(due)} · $time';
}

bool isOverdue(DateTime? due, bool isDone) {
  if (due == null || isDone) return false;
  return due.isBefore(DateTime.now());
}

bool isDueToday(DateTime? due, bool isDone) {
  if (due == null || isDone) return false;
  final now = DateTime.now();
  return due.year == now.year && due.month == now.month && due.day == now.day;
}
