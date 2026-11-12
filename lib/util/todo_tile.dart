import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../models/todo_item.dart';
import 'task_meta.dart';

class TodoTile extends StatelessWidget {
  const TodoTile({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  final TodoItem item;
  final void Function(bool?) onChanged;
  final void Function(BuildContext)? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final overdue = isOverdue(item.dueAt, item.isDone);
    final dueToday = isDueToday(item.dueAt, item.isDone);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: onDelete,
              icon: Icons.delete_outline,
              label: 'Delete',
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              borderRadius: BorderRadius.circular(16),
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Checkbox(
                value: item.isDone,
                onChanged: onChanged,
                activeColor: scheme.primary,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                        decoration: item.isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: item.isDone
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (item.dueAt != null)
                          _MetaChip(
                            icon: overdue
                                ? Icons.warning_amber_rounded
                                : Icons.calendar_today_outlined,
                            label: formatDueLabel(item.dueAt!, item.isDone),
                            filled: true,
                            background: overdue
                                ? scheme.errorContainer
                                : dueToday
                                    ? scheme.tertiaryContainer
                                    : scheme.secondaryContainer,
                            foreground: overdue
                                ? scheme.onErrorContainer
                                : dueToday
                                    ? scheme.onTertiaryContainer
                                    : scheme.onSecondaryContainer,
                          ),
                        _MetaChip(
                          icon: categoryIcon(item.category),
                          label: item.category,
                        ),
                        if (item.repeat != RepeatRule.none)
                          _MetaChip(
                            icon: Icons.repeat,
                            label: repeatLabel(item.repeat),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              ),
              Tooltip(
                message: '${priorityLabel(item.priority)} priority',
                child: Padding(
                  padding: const EdgeInsets.only(right: 14, left: 6),
                  child: Icon(
                    Icons.flag,
                    size: 19,
                    color: priorityColor(item.priority),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.filled = false,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = foreground ?? scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? background : null,
        borderRadius: BorderRadius.circular(10),
        border: filled
            ? null
            : Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
