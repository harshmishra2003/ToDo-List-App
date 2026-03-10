import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

/// Stores tasks locally on-device using SharedPreferences.
/// Used as offline fallback when Firebase Realtime DB is unavailable.
/// Maximum [maxLocalTasks] tasks allowed in local mode.
class LocalStorageService {
  static const String _tasksKey = 'local_tasks';
  static const int maxLocalTasks = 5;

  // ── Read ──────────────────────────────────────────────────────────────────
  Future<List<Task>> getLocalTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_tasksKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Write (internal) ──────────────────────────────────────────────────────
  Future<void> _saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_tasksKey, encoded);
  }

  // ── Add ───────────────────────────────────────────────────────────────────
  /// Returns the added [Task] or throws [LocalLimitException] if limit reached.
  Future<Task> addTask(Task task) async {
    final tasks = await getLocalTasks();
    if (tasks.length >= maxLocalTasks) {
      throw LocalLimitException(
        'Offline limit reached. Maximum $maxLocalTasks local tasks allowed.',
      );
    }
    final localTask = task.copyWith(isLocal: true);
    tasks.insert(0, localTask);
    await _saveTasks(tasks);
    return localTask;
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> deleteTask(String taskId) async {
    final tasks = await getLocalTasks();
    tasks.removeWhere((t) => t.id == taskId);
    await _saveTasks(tasks);
  }

  // ── Update ────────────────────────────────────────────────────────────────
  Future<void> updateTask(Task updatedTask) async {
    final tasks = await getLocalTasks();
    final index = tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      tasks[index] = updatedTask.copyWith(isLocal: true);
      await _saveTasks(tasks);
    }
  }

  // ── Toggle ────────────────────────────────────────────────────────────────
  Future<void> toggleComplete(String taskId) async {
    final tasks = await getLocalTasks();
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      tasks[index] = tasks[index].copyWith(isCompleted: !tasks[index].isCompleted);
      await _saveTasks(tasks);
    }
  }

  // ── Clear all local tasks (e.g. on sign-out) ──────────────────────────────
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tasksKey);
  }

  // ── Count ─────────────────────────────────────────────────────────────────
  Future<int> getCount() async {
    return (await getLocalTasks()).length;
  }
}

class LocalLimitException implements Exception {
  final String message;
  const LocalLimitException(this.message);
  @override
  String toString() => message;
}
