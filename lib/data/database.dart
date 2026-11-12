import 'package:hive_flutter/hive_flutter.dart';

import '../models/todo_item.dart';

/// Persistence layer for the to-do app.
///
/// Tasks are stored in the `myBox` Hive box under [todoListKey] as a list of
/// maps (Hive stores `Map` natively, so no generated adapters are required).
/// Builds before this version stored raw `[title, isDone]` lists under the
/// same key; [loadData] detects and migrates that legacy format in place.
class TodoDataBase {
  static const String boxName = 'myBox';
  static const String todoListKey = 'TODOLIST';
  static const String themeModeKey = 'THEME_MODE';

  final Box _myBox = Hive.box(boxName);

  /// Tasks currently loaded in memory. Mutate via the HomePage state and
  /// persist with [updateDataBase].
  List<TodoItem> todoList = [];

  bool hasStoredData() => _myBox.get(todoListKey) != null;

  /// First-launch sample data. Call [updateDataBase] right after this so the
  /// seeds are actually persisted.
  void createInitialData() {
    final now = DateTime.now();
    todoList = [
      TodoItem(
        id: TodoItem.generateId(),
        title: 'Plan my day',
        priority: TodoPriority.high,
        category: 'Personal',
        dueAt: now,
      ),
      TodoItem(
        id: TodoItem.generateId(),
        title: 'Buy groceries',
        priority: TodoPriority.medium,
        category: 'Shopping',
        dueAt: now.add(const Duration(days: 1)),
      ),
      TodoItem(
        id: TodoItem.generateId(),
        title: 'Weekly review',
        priority: TodoPriority.low,
        category: 'Work',
        repeat: RepeatRule.weekly,
      ),
    ];
  }

  /// Loads tasks from Hive. Any corrupt entries are dropped and legacy
  /// `[title, isDone]` entries are migrated to the current format; the box is
  /// rewritten when anything had to be repaired.
  void loadData() {
    final dynamic raw = _myBox.get(todoListKey);
    final items = <TodoItem>[];
    var needsRewrite = false;

    if (raw is List) {
      for (final entry in raw) {
        if (entry is Map) {
          final item = TodoItem.tryFromMap(entry);
          if (item == null) {
            needsRewrite = true; // drop unreadable entry
          } else {
            items.add(item);
          }
        } else if (entry is List && entry.length >= 2) {
          // Legacy format: [title, isDone]
          items.add(TodoItem(
            id: TodoItem.generateId(),
            title: entry[0].toString(),
            isDone: entry[1] == true,
          ));
          needsRewrite = true;
        } else {
          needsRewrite = true; // drop garbage entry
        }
      }
    } else if (raw != null) {
      // Corrupt payload (e.g. hand-edited). Start from a clean list.
      needsRewrite = true;
    }

    todoList = items;
    if (needsRewrite) updateDataBase();
  }

  void updateDataBase() {
    _myBox.put(
      todoListKey,
      todoList.map((item) => item.toMap()).toList(),
    );
  }

  String? readThemeMode() => _myBox.get(themeModeKey) as String?;

  void writeThemeMode(String mode) {
    _myBox.put(themeModeKey, mode);
  }
}
