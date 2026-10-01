import 'package:cloud_firestore/cloud_firestore.dart';
import 'task_model.dart';

/// All Firestore access for tasks lives here.
/// Path: users/{userId}/tasks/{taskId}
class TaskRepository {
  final String userId;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  TaskRepository(this.userId);

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _db.collection('users').doc(userId).collection('tasks');

  // READ: a stream that emits a new list whenever tasks change.
  Stream<List<Task>> watchTasks() {
    return _tasks
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Task.fromMap(doc.data(), doc.id)).toList());
  }

  // CREATE
  Future<void> addTask(Task task) async {
    final doc = _tasks.doc(); // generates a new id
    await doc.set(task.copyWith(id: doc.id).toMap());
  }

  // UPDATE
  Future<void> updateTask(Task task) => _tasks.doc(task.id).update(task.toMap());

  // DELETE
  Future<void> deleteTask(String taskId) => _tasks.doc(taskId).delete();
}
