import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/task_bloc.dart';
import '../../bloc/task_event.dart';
import '../../bloc/task_state.dart';
import '../../data/task_model.dart';
import '../widgets/task_form.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  bool _isSaving = false;

  void _save(String title, String description, DateTime? dueDate, bool _) {
    setState(() => _isSaving = true);
    // id is empty here; the repository generates the real id.
    context.read<TaskBloc>().add(AddTask(Task(
          id: '',
          title: title,
          description: description,
          createdAt: DateTime.now(),
          dueDate: dueDate,
        )));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state is TaskOperationSuccess) {
          Navigator.of(context).pop();
        } else if (state is TaskError) {
          setState(() => _isSaving = false); // HomePage shows the SnackBar
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Add Task')),
        body: TaskForm(
            isSaving: _isSaving, buttonText: 'Save', onSubmit: _save),
      ),
    );
  }
}
