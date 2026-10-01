import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/task_model.dart';

/// Reusable form for both Add and Edit.
/// If [initialTask] is given, the fields start filled in (edit mode).
class TaskForm extends StatefulWidget {
  final Task? initialTask;
  final bool isSaving;
  final String buttonText;
  final void Function(
          String title, String description, DateTime? dueDate, bool isCompleted)
      onSubmit;

  const TaskForm({
    super.key,
    this.initialTask,
    required this.isSaving,
    required this.buttonText,
    required this.onSubmit,
  });

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  DateTime? _dueDate;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController =
        TextEditingController(text: task?.description ?? '');
    _dueDate = task?.dueDate;
    _isCompleted = task?.isCompleted ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(_titleController.text.trim(),
          _descriptionController.text.trim(), _dueDate, _isCompleted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
                labelText: 'Title', prefixIcon: Icon(Icons.title)),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Title is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Description (optional)',
                alignLabelWithHint: true),
          ),
          const SizedBox(height: 16),
          // Card gives the tile a white rounded background.
          Card(
            elevation: 0,
            color: Colors.white,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFD9DCE6)),
            ),
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(_dueDate == null
                  ? 'No due date'
                  : 'Due: ${DateFormat.yMMMd().format(_dueDate!)}'),
              onTap: _pickDate,
              trailing: _dueDate == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _dueDate = null),
                    ),
            ),
          ),
          // Completed switch only makes sense when editing.
          if (widget.initialTask != null)
            SwitchListTile(
              title: const Text('Completed'),
              value: _isCompleted,
              onChanged: (v) => setState(() => _isCompleted = v),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: widget.isSaving ? null : _submit,
            child: widget.isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(widget.buttonText),
          ),
        ],
      ),
        ),
      ),
    );
  }
}
