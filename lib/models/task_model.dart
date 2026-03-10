import 'dart:convert';

class Task {
  final String id;
  String title;
  String description;
  bool isCompleted;
  DateTime createdAt;
  String priority; // 'high' | 'medium' | 'low'
  bool isLocal; // true = stored on-device only (offline mode)

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    required this.createdAt,
    this.priority = 'medium',
    this.isLocal = false,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    String? priority,
    bool? isLocal,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'priority': priority,
      'isLocal': isLocal,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      priority: json['priority'] ?? 'medium',
      isLocal: json['isLocal'] ?? false,
    );
  }

  /// Used to parse tasks coming from Firebase (id is the key, not in body)
  factory Task.fromFirebase(String id, Map<String, dynamic> json) {
    return Task(
      id: id,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      priority: json['priority'] ?? 'medium',
      isLocal: false,
    );
  }

  static List<Task> fromFirebaseResponse(Map<String, dynamic> data) {
    final tasks = <Task>[];
    data.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        tasks.add(Task.fromFirebase(key, value));
      }
    });
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }

  String toJsonString() => jsonEncode(toJson());
}
