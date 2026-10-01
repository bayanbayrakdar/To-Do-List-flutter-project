import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_event.dart';
import '../../bloc/task_bloc.dart';
import '../../bloc/task_event.dart';
import '../../bloc/task_state.dart';
import '../../data/task_model.dart';
import '../widgets/task_item.dart';
import 'add_task_page.dart';
import 'edit_task_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // New pages are pushed on the Navigator (above our BlocProvider),
  // so we pass the existing TaskBloc along with BlocProvider.value.
  void _openPage(BuildContext context, Widget page) {
    final bloc = context.read<TaskBloc>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(value: bloc, child: page),
    ));
  }

  Future<void> _confirmDelete(BuildContext context, Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<TaskBloc>().add(DeleteTask(task.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openPage(context, const AddTaskPage()),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskOperationSuccess) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is TaskError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        // Don't redraw the list for success messages or failed operations.
        buildWhen: (previous, current) =>
            current is! TaskOperationSuccess &&
            (current is! TaskError || current.loadingFailed),
        builder: (context, state) {
          if (state is TaskError) {
            return Center(child: Text(state.message));
          }
          if (state is TaskLoaded) {
            if (state.tasks.isEmpty) return const _EmptyState();
            final doneCount = state.tasks.where((t) => t.isCompleted).length;
            // Center + max width keeps the list readable on a wide window.
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  // +1 because the first row is the progress summary.
                  itemCount: state.tasks.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _ProgressSummary(
                          done: doneCount, total: state.tasks.length);
                    }
                    final task = state.tasks[index - 1];
                    return TaskItem(
                      task: task,
                      onToggle: () => context
                          .read<TaskBloc>()
                          .add(ToggleTaskCompletion(task)),
                      onEdit: () =>
                          _openPage(context, EditTaskPage(task: task)),
                      onDelete: () => _confirmDelete(context, task),
                    );
                  },
                ),
              ),
            );
          }
          // TaskInitial / TaskLoading
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

/// "2 of 5 completed" with a progress bar.
class _ProgressSummary extends StatelessWidget {
  final int done;
  final int total;
  const _ProgressSummary({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$done of $total completed',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onPrimaryContainer)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: 8,
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checklist, size: 72, color: scheme.outline),
          const SizedBox(height: 12),
          Text('No tasks yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Tap + to add your first task',
              style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
