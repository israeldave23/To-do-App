import 'package:flutter/material.dart';

import '../data/database.dart';
import '../models/todo_item.dart';
import '../util/dialog_box.dart';
import '../util/task_meta.dart';
import '../util/todo_tile.dart';

enum TaskFilter { all, active, done }

enum SortMode { dueDate, priority, newest, alphabetical }

enum _MenuAction {
  sortDueDate,
  sortPriority,
  sortNewest,
  sortAlphabetical,
  clearCompleted,
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _taskController = TextEditingController();
  final TodoDataBase db = TodoDataBase();

  TaskFilter _filter = TaskFilter.all;
  String? _categoryFilter;
  String _query = '';
  SortMode _sort = SortMode.dueDate;

  @override
  void initState() {
    super.initState();
    if (db.hasStoredData()) {
      db.loadData();
    } else {
      db.createInitialData();
      db.updateDataBase();
    }
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _query = _searchController.text.trim());
  }

  // ---------- Stats ----------

  int get _total => db.todoList.length;
  int get _done => db.todoList.where((t) => t.isDone).length;
  int get _pending => _total - _done;

  int get _overdue =>
      db.todoList.where((t) => isOverdue(t.dueAt, t.isDone)).length;

  int get _dueToday =>
      db.todoList.where((t) => isDueToday(t.dueAt, t.isDone)).length;

  // ---------- Filtering & sorting ----------

  bool get _isFiltering =>
      _query.isNotEmpty ||
      _categoryFilter != null ||
      _filter != TaskFilter.all;

  List<TodoItem> get _visibleTasks {
    Iterable<TodoItem> items = db.todoList;
    if (_filter == TaskFilter.active) {
      items = items.where((t) => !t.isDone);
    } else if (_filter == TaskFilter.done) {
      items = items.where((t) => t.isDone);
    }
    if (_categoryFilter != null) {
      items = items.where((t) => t.category == _categoryFilter);
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      items = items.where((t) => t.title.toLowerCase().contains(q));
    }
    final list = items.toList();
    list.sort(_compareTasks);
    return list;
  }

  int _compareTasks(TodoItem a, TodoItem b) {
    if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
    switch (_sort) {
      case SortMode.priority:
        return _priorityWeight(b.priority) - _priorityWeight(a.priority);
      case SortMode.newest:
        return b.createdAt.compareTo(a.createdAt);
      case SortMode.alphabetical:
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      case SortMode.dueDate:
        if (a.dueAt == null && b.dueAt == null) return 0;
        if (a.dueAt == null) return 1;
        if (b.dueAt == null) return -1;
        return a.dueAt!.compareTo(b.dueAt!);
    }
    return 0;
  }

  int _priorityWeight(TodoPriority p) {
    switch (p) {
      case TodoPriority.high:
        return 3;
      case TodoPriority.medium:
        return 2;
      case TodoPriority.low:
        return 1;
    }
    return 1;
  }

  // ---------- Mutations ----------

  void _toggleTask(TodoItem item, bool? value) {
    final bool done = value ?? !item.isDone;
    setState(() {
      item.isDone = done;
      // Recurring tasks spawn the next occurrence when completed.
      if (done && item.repeat != RepeatRule.none) {
        final now = DateTime.now();
        final step = item.repeat == RepeatRule.daily
            ? const Duration(days: 1)
            : const Duration(days: 7);
        var next = (item.dueAt ?? now).add(step);
        // Keep advancing so the spawned occurrence lands in the future.
        while (next.isBefore(now)) {
          next = next.add(step);
        }
        db.todoList.add(TodoItem(
          id: TodoItem.generateId(),
          title: item.title,
          priority: item.priority,
          category: item.category,
          dueAt: next,
          repeat: item.repeat,
        ));
      }
    });
    db.updateDataBase();
  }

  void _deleteTask(TodoItem item) {
    final int index = db.todoList.indexWhere((t) => t.id == item.id);
    setState(() => db.todoList.removeWhere((t) => t.id == item.id));
    db.updateDataBase();

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Deleted "${item.title}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              db.todoList.insert(
                index.clamp(0, db.todoList.length).toInt(),
                item,
              );
            });
            db.updateDataBase();
          },
        ),
      ),
    );
  }

  void _clearCompleted() {
    final int removed = _done;
    if (removed == 0) return;
    setState(() => db.todoList.removeWhere((t) => t.isDone));
    db.updateDataBase();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cleared $removed completed task(s)')),
    );
  }

  void _saveNewTask(
    String title,
    DateTime? dueAt,
    TodoPriority priority,
    String category,
    RepeatRule repeat,
  ) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      db.todoList.add(TodoItem(
        id: TodoItem.generateId(),
        title: trimmed,
        priority: priority,
        category: category,
        dueAt: dueAt,
        repeat: repeat,
      ));
    });
    db.updateDataBase();
  }

  void _openNewTaskDialog() {
    _taskController.clear();
    showDialog<void>(
      context: context,
      builder: (context) {
        return DialogBox(
          controller: _taskController,
          onCancel: () => Navigator.of(context).pop(),
          onSave: (title, dueAt, priority, category, repeat) {
            _saveNewTask(title, dueAt, priority, category, repeat);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  void _resetFilters() {
    setState(() {
      _query = '';
      _filter = TaskFilter.all;
      _categoryFilter = null;
      _sort = SortMode.dueDate;
    });
    _searchController.clear();
  }

  void _onMenuAction(_MenuAction action) {
    switch (action) {
      case _MenuAction.sortDueDate:
        setState(() => _sort = SortMode.dueDate);
        break;
      case _MenuAction.sortPriority:
        setState(() => _sort = SortMode.priority);
        break;
      case _MenuAction.sortNewest:
        setState(() => _sort = SortMode.newest);
        break;
      case _MenuAction.sortAlphabetical:
        setState(() => _sort = SortMode.alphabetical);
        break;
      case _MenuAction.clearCompleted:
        _clearCompleted();
        break;
    }
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tasks = _visibleTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: Icon(
              widget.themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            tooltip: 'Toggle theme',
            onPressed: widget.onToggleTheme,
          ),
          PopupMenuButton<_MenuAction>(
            tooltip: 'More actions',
            icon: const Icon(Icons.more_vert),
            onSelected: _onMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem<_MenuAction>(
                enabled: false,
                height: 32,
                child: Text(
                  'SORT BY',
                  style: TextStyle(fontSize: 11, letterSpacing: 1),
                ),
              ),
              _sortItem('Due date', Icons.event_outlined,
                  _MenuAction.sortDueDate, scheme),
              _sortItem('Priority', Icons.flag_outlined,
                  _MenuAction.sortPriority, scheme),
              _sortItem('Newest first', Icons.schedule_outlined,
                  _MenuAction.sortNewest, scheme),
              _sortItem('Alphabetical', Icons.sort_by_alpha,
                  _MenuAction.sortAlphabetical, scheme),
              const PopupMenuDivider(),
              PopupMenuItem<_MenuAction>(
                value: _MenuAction.clearCompleted,
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined,
                        size: 20, color: scheme.error),
                    const SizedBox(width: 12),
                    Text('Clear completed',
                        style: TextStyle(color: scheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewTaskDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchBar(),
            _buildProgressCard(),
            _buildFilterChips(),
            _buildCategoryChips(),
            Expanded(
              child: tasks.isEmpty
                  ? _buildEmptyState(scheme)
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 96),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final item = tasks[index];
                        return TodoTile(
                          key: ValueKey(item.id),
                          item: item,
                          onChanged: (value) => _toggleTask(item, value),
                          onDelete: (_) => _deleteTask(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<_MenuAction> _sortItem(
    String label,
    IconData icon,
    _MenuAction action,
    ColorScheme scheme,
  ) {
    final bool selected = (action == _MenuAction.sortDueDate &&
            _sort == SortMode.dueDate) ||
        (action == _MenuAction.sortPriority && _sort == SortMode.priority) ||
        (action == _MenuAction.sortNewest && _sort == SortMode.newest) ||
        (action == _MenuAction.sortAlphabetical &&
            _sort == SortMode.alphabetical);
    return PopupMenuItem<_MenuAction>(
      value: action,
      child: Row(
        children: [
          Icon(icon,
              size: 20, color: selected ? scheme.primary : null),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          if (selected) Icon(Icons.check, size: 18, color: scheme.primary),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search tasks…',
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear search',
                  onPressed: _searchController.clear,
                ),
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final int total = _total;
    final int done = _done;
    final double fraction = total == 0 ? 0 : done / total;
    final int percent = (fraction * 100).round();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF105B50), Color(0xFF2E8B74)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR PROGRESS',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_done of $_total done',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatChip(
                icon: Icons.hourglass_empty,
                label: 'Pending',
                value: '$_pending',
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.today_outlined,
                label: 'Due today',
                value: '$_dueToday',
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.warning_amber_rounded,
                label: 'Overdue',
                value: '$_overdue',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          ChoiceChip(
            label: Text('All ($_total)'),
            selected: _filter == TaskFilter.all,
            onSelected: (_) => setState(() => _filter = TaskFilter.all),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text('Active ($_pending)'),
            selected: _filter == TaskFilter.active,
            onSelected: (_) => setState(() => _filter = TaskFilter.active),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text('Done ($_done)'),
            selected: _filter == TaskFilter.done,
            onSelected: (_) => setState(() => _filter = TaskFilter.done),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          ChoiceChip(
            avatar: const Icon(Icons.apps, size: 16),
            label: const Text('All categories'),
            selected: _categoryFilter == null,
            onSelected: (_) => setState(() => _categoryFilter = null),
          ),
          for (final category in kTaskCategories) ...[
            const SizedBox(width: 8),
            ChoiceChip(
              avatar: Icon(categoryIcon(category), size: 16),
              label: Text(category),
              selected: _categoryFilter == category,
              onSelected: (_) => setState(
                () => _categoryFilter =
                    _categoryFilter == category ? null : category,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme scheme) {
    final bool filtering = _isFiltering;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filtering ? Icons.search_off : Icons.task_alt,
              size: 64,
              color: scheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              filtering ? 'No matching tasks' : 'Nothing here yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              filtering
                  ? 'Try a different search or clear the filters.'
                  : 'Tap "New Task" to add your first task.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            if (filtering) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Clear filters'),
                onPressed: _resetFilters,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
