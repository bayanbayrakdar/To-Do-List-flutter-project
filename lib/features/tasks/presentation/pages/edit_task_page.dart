import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/task_bloc.dart';
import '../../bloc/task_event.dart';
import '../../bloc/task_state.dart';
import '../../data/task_model.dart';
import '../widgets/task_form.dart';

class EditTaskPage extends StatefulWidget {
  final Task task;
  const EditTaskPage({super.key, required this.task});

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  bool _isSaving = false;

  void _save(
      String title, String description, DateTime? dueDate, bool isCompleted) {
    setState(() => _isSaving = true);
    final updated = widget.task.copyWith(
      title: title,
      description: description,
      dueDate: dueDate,
      clearDueDate: dueDate == null,
      isCompleted: isCompleted,
    );
    context.read<TaskBloc>().add(UpdateTask(updated));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state is TaskOperationSuccess) {
          Navigator.of(context).pop();
        } else if (state is TaskError) {
          setState(() => _isSaving = false);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit Task')),
        body: TaskForm(
          initialTask: widget.task,
          isSaving: _isSaving,
          buttonText: 'Update',
          onSubmit: _save,
        ),
      ),
    );
  }
}
