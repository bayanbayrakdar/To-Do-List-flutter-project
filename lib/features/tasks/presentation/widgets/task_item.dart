import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/task_model.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskItem({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  // A task is overdue if its due date is before today and it isn't done.
  bool get _isOverdue {
    if (task.dueDate == null || task.isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return task.dueDate!.isBefore(today);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Completed tasks: grey text with a line through it.
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          color: task.isCompleted ? scheme.outline : null,
        );

    return Card(
      elevation: 0,
      color: task.isCompleted ? const Color(0xFFFAFAFC) : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
                value: task.isCompleted, onChanged: (_) => onToggle()),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: titleStyle),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(task.description,
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                    ],
                    if (task.dueDate != null) ...[
                      const SizedBox(height: 8),
                      _DueChip(
                        text: 'Due: ${DateFormat.yMMMd().format(task.dueDate!)}',
                        isOverdue: _isOverdue,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit),
                onPressed: onEdit),
            IconButton(
                tooltip: 'Delete',
                icon: Icon(Icons.delete, color: scheme.error),
                onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}

/// Small rounded label showing the due date (red when overdue).
class _DueChip extends StatelessWidget {
  final String text;
  final bool isOverdue;
  const _DueChip({required this.text, required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background =
        isOverdue ? scheme.errorContainer : scheme.secondaryContainer;
    final foreground =
        isOverdue ? scheme.onErrorContainer : scheme.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, color: foreground)),
        ],
      ),
    );
  }
}
