import 'package:equatable/equatable.dart';
import '../data/task_model.dart';

abstract class TaskState extends Equatable {
  const TaskState();
  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<Task> tasks;
  const TaskLoaded(this.tasks);
  @override
  List<Object?> get props => [tasks];
}

/// Emitted after add / update / delete. Used for SnackBars and closing pages.
class TaskOperationSuccess extends TaskState {
  final String message;
  const TaskOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class TaskError extends TaskState {
  final String message;
  // true  = the task list could not be loaded (show error screen)
  // false = an add/update/delete failed (keep showing the list)
  final bool loadingFailed;
  const TaskError(this.message, {this.loadingFailed = false});
  @override
  List<Object?> get props => [message, loadingFailed];
}
