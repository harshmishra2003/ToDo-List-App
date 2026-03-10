import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';
import '../services/local_storage_service.dart';

enum TaskFilter { all, active, completed }

enum TaskLoadStatus { idle, loading, loaded, error }

enum StorageMode { cloud, local }

class TaskProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final LocalStorageService _localService = LocalStorageService();

  List<Task> _tasks = [];
  TaskFilter _filter = TaskFilter.all;
  TaskLoadStatus _loadStatus = TaskLoadStatus.idle;
  StorageMode _storageMode = StorageMode.cloud;
  String? _errorMessage;

  // ── Getters ────────────────────────────────────────────────────────────────
  List<Task> get tasks => _tasks;
  TaskFilter get filter => _filter;
  TaskLoadStatus get loadStatus => _loadStatus;
  StorageMode get storageMode => _storageMode;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loadStatus == TaskLoadStatus.loading;
  bool get isOffline => _storageMode == StorageMode.local;

  int get localTaskCount => _tasks.where((t) => t.isLocal).length;
  int get localTasksRemaining =>
      LocalStorageService.maxLocalTasks - localTaskCount;

  List<Task> get filteredTasks {
    switch (_filter) {
      case TaskFilter.active:
        return _tasks.where((t) => !t.isCompleted).toList();
      case TaskFilter.completed:
        return _tasks.where((t) => t.isCompleted).toList();
      case TaskFilter.all:
        return _tasks;
    }
  }

  int get totalCount => _tasks.length;
  int get activeCount => _tasks.where((t) => !t.isCompleted).length;
  int get completedCount => _tasks.where((t) => t.isCompleted).length;

  void setFilter(TaskFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  // ── Fetch tasks ────────────────────────────────────────────────────────────
  /// Tries Firebase first. Falls back to local storage if Firebase fails.
  Future<void> fetchTasks(String uid, String idToken) async {
    _loadStatus = TaskLoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Try cloud first
      final cloudTasks = await _dbService.fetchTasks(uid, idToken);
      _tasks = cloudTasks;
      _storageMode = StorageMode.cloud;
      _loadStatus = TaskLoadStatus.loaded;

      // Merge any local tasks that weren't synced yet
      final localTasks = await _localService.getLocalTasks();
      if (localTasks.isNotEmpty) {
        final localIds = localTasks.map((t) => t.id).toSet();
        _tasks.removeWhere((t) => localIds.contains(t.id));
        _tasks = [...localTasks, ..._tasks];
        _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      // Firebase unavailable — fall back to local storage
      try {
        _tasks = await _localService.getLocalTasks();
        _storageMode = StorageMode.local;
        _loadStatus = TaskLoadStatus.loaded;
        _errorMessage =
            '⚠️ Offline mode — showing local tasks (max ${LocalStorageService.maxLocalTasks})';
      } catch (_) {
        _loadStatus = TaskLoadStatus.error;
        _errorMessage = 'Failed to load tasks. Pull down to retry.';
      }
    }
    notifyListeners();
  }

  // ── Add task (throws — use in sheets for inline error display) ─────────────
  Future<String> addTaskRaw(String uid, String idToken, Task task) async {
    if (isOffline) {
      // Offline path — save locally
      if (localTaskCount >= LocalStorageService.maxLocalTasks) {
        throw LocalLimitException(
          'Offline limit reached! Max ${LocalStorageService.maxLocalTasks} local tasks.',
        );
      }
      final saved = await _localService.addTask(task);
      _tasks.insert(0, saved);
      notifyListeners();
      return saved.id;
    } else {
      // Online path — try Firebase, fall back to local on failure
      try {
        final newId = await _dbService.addTask(uid, idToken, task);
        final savedTask = task.copyWith(id: newId, isLocal: false);
        _tasks.insert(0, savedTask);
        notifyListeners();
        return newId;
      } catch (e) {
        // Firebase failed mid-session — switch to offline
        _storageMode = StorageMode.local;
        _errorMessage = '⚠️ Offline mode — task saved locally';
        if (localTaskCount >= LocalStorageService.maxLocalTasks) {
          notifyListeners();
          throw LocalLimitException(
            'Offline limit reached! Max ${LocalStorageService.maxLocalTasks} local tasks.',
          );
        }
        final saved = await _localService.addTask(task);
        _tasks.insert(0, saved);
        notifyListeners();
        return saved.id;
      }
    }
  }

  Future<bool> addTask(String uid, String idToken, Task task) async {
    try {
      await addTaskRaw(uid, idToken, task);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Update task ────────────────────────────────────────────────────────────
  Future<bool> updateTask(String uid, String idToken, Task updatedTask) async {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    final original = index != -1 ? _tasks[index] : null;

    if (index != -1) {
      _tasks[index] = updatedTask;
      notifyListeners();
    }

    try {
      if (updatedTask.isLocal || isOffline) {
        await _localService.updateTask(updatedTask);
      } else {
        await _dbService.updateTask(uid, idToken, updatedTask);
      }
      return true;
    } catch (e) {
      // Revert
      if (original != null && index != -1) {
        _tasks[index] = original;
        notifyListeners();
      }
      return false;
    }
  }

  // ── Toggle completion ──────────────────────────────────────────────────────
  Future<void> toggleComplete(String uid, String idToken, Task task) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = updated;
      notifyListeners(); // Optimistic
    }

    try {
      if (task.isLocal || isOffline) {
        await _localService.toggleComplete(task.id);
      } else {
        await _dbService.toggleComplete(uid, idToken, task.id, !task.isCompleted);
      }
    } catch (_) {
      // Revert
      if (index != -1) {
        _tasks[index] = task;
        notifyListeners();
      }
    }
  }

  // ── Delete task ────────────────────────────────────────────────────────────
  Future<bool> deleteTask(String uid, String idToken, String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    final task = index != -1 ? _tasks[index] : null;
    final isLocalTask = task?.isLocal ?? false;

    if (index != -1) {
      _tasks.removeAt(index);
      notifyListeners(); // Optimistic
    }

    try {
      if (isLocalTask || isOffline) {
        await _localService.deleteTask(taskId);
      } else {
        await _dbService.deleteTask(uid, idToken, taskId);
      }
      return true;
    } catch (_) {
      // Revert
      if (task != null && index != -1) {
        _tasks.insert(index, task);
        notifyListeners();
      }
      return false;
    }
  }

  // ── Clear all (on sign-out) ────────────────────────────────────────────────
  void clearTasks() {
    _tasks = [];
    _filter = TaskFilter.all;
    _loadStatus = TaskLoadStatus.idle;
    _storageMode = StorageMode.cloud;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
