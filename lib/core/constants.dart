import 'package:flutter_dotenv/flutter_dotenv.dart';

// ============================================================
//  CORE CONSTANTS
//  Secured via flutter_dotenv (.env file ignored in git)
// ============================================================

class AppConstants {
  // Read Database URL securely from environment
  static String get databaseUrl =>
      dotenv.env['FIREBASE_DB_URL'] ?? 'https://login-ff68f-default-rtdb.firebaseio.com';

  // App-level constants
  static const String appName = 'Tasky';
  static const int splashDuration = 2; // seconds

  // Task priority levels
  static const String priorityHigh = 'high';
  static const String priorityMedium = 'medium';
  static const String priorityLow = 'low';

  // Realtime DB endpoints
  static String tasksEndpoint(String uid) =>
      '$databaseUrl/users/$uid/tasks.json';
  static String taskEndpoint(String uid, String taskId) =>
      '$databaseUrl/users/$uid/tasks/$taskId.json';
}
