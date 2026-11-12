import 'package:flutter/material.dart';

import '../models/todo_item.dart';
import 'task_meta.dart';

typedef TaskSaveCallback = void Function(
  String title,
  DateTime? dueAt,
  TodoPriority priority,
  String category,
  RepeatRule repeat,
);

/// "New task" dialog. Collects the title plus optional due date/time,
/// priority, category and repeat rule, then hands them to [onSave].
class DialogBox extends StatefulWidget {
  const DialogBox({
    super.key,
    required this.controller,
    required this.onSave,
    required this.onCancel,
  });

  final TextEditingController controller;
  final TaskSaveCallback onSave;
  final VoidCallback onCancel;

  @override
  State<DialogBox> createState() => _DialogBoxState();
}

class _DialogBoxState extends State<DialogBox> {
  TodoPriority _priority = TodoPriority.medium;
  String _category = kTaskCategories.first;
  RepeatRule _repeat = RepeatRule.none;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;

  DateTime? get _combinedDue {
    if (_dueDate == null) return null;
    final time = _dueTime;
    return DateTime(
      _dueDate!.year,
      _dueDate!.month,
      _dueDate!.day,
      time?.hour ?? 9,
      time?.minute ?? 0,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (!mounted) return;
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (!mounted) return;
    if (picked != null) setState(() => _dueTime = picked);
  }

  void _submit() {
    final title = widget.controller.text.trim();
    if (title.isEmpty) return;
    widget.onSave(title, _combinedDue, _priority, _category, _repeat);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      title: Row(
        children: [
          Icon(Icons.add_task, color: scheme.primary),
          const SizedBox(width: 10),
          const Text('New task'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: widget.controller,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  hintText: 'What needs to be done?',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
              ),
              const SizedBox(height: 16),
              const _SectionLabel('Due date'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(
                      _dueDate == null ? 'Pick date' : formatDate(_dueDate!),
                    ),
                    onPressed: _pickDate,
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(
                      _dueTime == null ? 'Set time' : formatTime(_dueTime!),
                    ),
                    onPressed: _dueDate == null ? null : _pickTime,
                  ),
                  if (_dueDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      tooltip: 'Clear due date',
                      onPressed: () => setState(() {
                        _dueDate = null;
                        _dueTime = null;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              const _SectionLabel('Priority'),
              Wrap(
                spacing: 8,
                children: [
                  for (final p in TodoPriority.values)
                    ChoiceChip(
                      avatar: Icon(
                        Icons.flag,
                        size: 16,
                        color: priorityColor(p),
                      ),
                      label: Text(priorityLabel(p)),
                      selected: _priority == p,
                      onSelected: (_) => setState(() => _priority = p),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              const _SectionLabel('Category'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in kTaskCategories)
                    ChoiceChip(
                      avatar: Icon(categoryIcon(c), size: 16),
                      label: Text(c),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              const _SectionLabel('Repeat'),
              Wrap(
                spacing: 8,
                children: [
                  for (final r in RepeatRule.values)
                    ChoiceChip(
                      avatar: r == RepeatRule.none
                          ? null
                          : const Icon(Icons.repeat, size: 16),
                      label: Text(repeatLabel(r)),
                      selected: _repeat == r,
                      onSelected: (_) => setState(() => _repeat = r),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: widget.controller,
          builder: (context, value, _) {
            return FilledButton.icon(
              onPressed: value.text.trim().isEmpty ? null : _submit,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Save task'),
            );
          },
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
          color: scheme.primary,
        ),
      ),
    );
  }
}
