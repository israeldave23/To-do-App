import 'dart:math';

enum TodoPriority { low, medium, high }

enum RepeatRule { none, daily, weekly }

/// Preset categories offered in the UI. Stored as plain strings on the item
/// so custom categories remain possible in the future.
const List<String> kTaskCategories = [
  'Personal',
  'Work',
  'Shopping',
  'Health',
  'Finance',
  'Other',
];

/// A single to-do item.
///
/// Items are persisted as plain maps (Hive stores `Map` natively), so no
/// generated `TypeAdapter` is required. See [TodoDataBase] for read/write and
/// legacy-format migration.
class TodoItem {
  TodoItem({
    required this.id,
    required this.title,
    this.isDone = false,
    this.priority = TodoPriority.medium,
    this.category = 'Personal',
    this.dueAt,
    this.repeat = RepeatRule.none,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  String title;
  bool isDone;
  TodoPriority priority;
  String category;
  DateTime? dueAt;
  RepeatRule repeat;
  final DateTime createdAt;

  static final Random _random = Random();

  static String generateId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(0x7fffffff)}';

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'isDone': isDone,
      'priority': priority.index,
      'category': category,
      'repeat': repeat.index,
      'createdAt': createdAt.microsecondsSinceEpoch,
    };
    if (dueAt != null) {
      map['dueAt'] = dueAt!.microsecondsSinceEpoch;
    }
    return map;
  }

  /// Defensive parser: returns null when the payload is unusable instead of
  /// throwing, so one corrupt entry cannot take down the whole list.
  static TodoItem? tryFromMap(dynamic raw) {
    if (raw is! Map) return null;
    final title = raw['title'];
    if (title is! String || title.isEmpty) return null;
    return TodoItem(
      id: raw['id'] is String ? raw['id'] as String : generateId(),
      title: title,
      isDone: raw['isDone'] == true,
      priority: _enumAt(TodoPriority.values, raw['priority'],
          TodoPriority.medium),
      category: raw['category'] is String &&
              (raw['category'] as String).isNotEmpty
          ? raw['category'] as String
          : 'Personal',
      dueAt: raw['dueAt'] is int
          ? DateTime.fromMicrosecondsSinceEpoch(raw['dueAt'] as int)
          : null,
      repeat: _enumAt(RepeatRule.values, raw['repeat'], RepeatRule.none),
      createdAt: raw['createdAt'] is int
          ? DateTime.fromMicrosecondsSinceEpoch(raw['createdAt'] as int)
          : null,
    );
  }

  static T _enumAt<T>(List<T> values, dynamic raw, T fallback) {
    if (raw is int && raw >= 0 && raw < values.length) return values[raw];
    return fallback;
  }
}
