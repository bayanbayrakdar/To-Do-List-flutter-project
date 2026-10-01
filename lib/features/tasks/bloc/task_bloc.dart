import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/task_repository.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository _repository;

  TaskBloc(this._repository) : super(TaskInitial()) {
    on<LoadTasks>(_onLoad);
    on<AddTask>(_onAdd);
    on<UpdateTask>(_onUpdate);
    on<DeleteTask>(_onDelete);
    on<ToggleTaskCompletion>(_onToggle);
  }

  // Listens to the Firestore stream. Every change emits a new TaskLoaded.
  Future<void> _onLoad(LoadTasks event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    await emit.forEach(
      _repository.watchTasks(),
      onData: (tasks) => TaskLoaded(tasks),
      onError: (error, stackTrace) => const TaskError(
          'Could not load tasks. Check your connection.',
          loadingFailed: true),
    );
  }

  // TODO (reminders): after saving a task with a dueDate, this is the place
  // to schedule a local notification. See SETUP.md, section "Reminders".
  Future<void> _onAdd(AddTask event, Emitter<TaskState> emit) async {
    try {
      await _repository.addTask(event.task);
      emit(const TaskOperationSuccess('Task added'));
    } catch (_) {
      emit(const TaskError('Could not add the task.'));
    }
  }

  Future<void> _onUpdate(UpdateTask event, Emitter<TaskState> emit) async {
    try {
      await _repository.updateTask(event.task);
      emit(const TaskOperationSuccess('Task updated'));
    } catch (_) {
      emit(const TaskError('Could not update the task.'));
    }
  }

  Future<void> _onDelete(DeleteTask event, Emitter<TaskState> emit) async {
    try {
      await _repository.deleteTask(event.taskId);
      emit(const TaskOperationSuccess('Task deleted'));
    } catch (_) {
      emit(const TaskError('Could not delete the task.'));
    }
  }

  Future<void> _onToggle(
      ToggleTaskCompletion event, Emitter<TaskState> emit) async {
    try {
      await _repository
          .updateTask(event.task.copyWith(isCompleted: !event.task.isCompleted));
    } catch (_) {
      emit(const TaskError('Could not update the task.'));
    }
  }
}
