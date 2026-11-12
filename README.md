# To-Do App (Flutter)

A modern, Material 3 to-do app with due dates, priorities, recurring tasks,
categories, search and dark mode. Built with Flutter and persisted locally
with Hive — no account or network required.

## Features

- **Tasks with rich metadata** — title, priority (low / medium / high),
  category (personal, work, shopping, health, finance, other), due date
  with optional time, and repeat rules (none / daily / weekly).
- **Recurring tasks** — completing a daily or weekly task automatically
  spawns its next occurrence.
- **Search** — live filtering as you type, with one-tap clear.
- **Filters & sorting** — All / Active / Done, category chips and sorting by
  due date, priority, newest or alphabetical.
- **Progress dashboard** — completion percentage, progress bar and
  pending / due-today / overdue counters at a glance.
- **Overdue highlighting** — overdue tasks and due-today tasks get distinct
  coloured chips; overdue shows in both the stats card and the task list.
- **Undo delete** — deletions are reversible via snackbar; completed tasks
  can be cleared in bulk from the overflow menu.
- **Dark mode** — system default with a one-tap toggle, persisted across
  launches.
- **Smart persistence** — tasks are stored as maps in Hive (no code
  generation needed) and the app automatically migrates tasks stored by
  older versions (`[title, isDone]` lists) on first launch. Corrupt entries
  are dropped instead of crashing.

## Getting started

```bash
flutter pub get
flutter run
```

## Project layout

```
lib/
  main.dart            # entry point: Hive init, theme mode persistence
  theme.dart           # Material 3 light/dark themes
  data/database.dart   # Hive persistence + legacy data migration
  models/todo_item.dart# TodoItem model, priorities, repeat rules
  pages/home_page.dart # home screen: stats, search, filters, list
  util/dialog_box.dart # "New task" dialog
  util/todo_tile.dart  # task card widget
  util/task_meta.dart  # formatting + priority/category helpers
```

## Notes

- Reminders are surfaced **in-app** (overdue / due-today indicators). OS-level
  notifications would require the `flutter_local_notifications` plugin plus
  native configuration and were intentionally left out to keep the dependency
  footprint at zero.
