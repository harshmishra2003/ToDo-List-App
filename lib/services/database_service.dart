import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/task_model.dart';

/// Handles all Realtime Database operations via REST API (not Firebase SDK).
/// All requests include the user's ID token as auth parameter.
class DatabaseService {
  final Dio _dio;

  DatabaseService()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    // Request / Response logging in debug mode
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => debugPrint(o.toString()),
    ));
  }

  void debugPrint(String msg) {
    // ignore: avoid_print
    print('[DatabaseService] $msg');
  }

  // ── Fetch Tasks ───────────────────────────────────────────
  Future<List<Task>> fetchTasks(String uid, String idToken) async {
    final url = '${AppConstants.tasksEndpoint(uid)}?auth=$idToken';
    final response = await _dio.get(url);

    if (response.data == null) return [];

    final Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
    return Task.fromFirebaseResponse(data);
  }

  // ── Add Task ──────────────────────────────────────────────
  /// Firebase REST POST returns the new auto-generated key in { "name": "..." }
  Future<String> addTask(String uid, String idToken, Task task) async {
    final url = '${AppConstants.tasksEndpoint(uid)}?auth=$idToken';
    final response = await _dio.post(url, data: task.toJson());

    final String newId = response.data['name'];
    return newId;
  }

  // ── Update Task ───────────────────────────────────────────
  Future<void> updateTask(String uid, String idToken, Task task) async {
    final url = '${AppConstants.taskEndpoint(uid, task.id)}?auth=$idToken';
    await _dio.patch(url, data: task.toJson());
  }

  // ── Delete Task ───────────────────────────────────────────
  Future<void> deleteTask(String uid, String idToken, String taskId) async {
    final url = '${AppConstants.taskEndpoint(uid, taskId)}?auth=$idToken';
    await _dio.delete(url);
  }

  // ── Toggle Completion ─────────────────────────────────────
  Future<void> toggleComplete(
      String uid, String idToken, String taskId, bool isCompleted) async {
    final url = '${AppConstants.taskEndpoint(uid, taskId)}?auth=$idToken';
    await _dio.patch(url, data: {'isCompleted': isCompleted});
  }
}
