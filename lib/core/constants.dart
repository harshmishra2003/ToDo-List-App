// ============================================================
//  CORE CONSTANTS
//  TODO: Replace the values below with your Firebase project
//  config after setting up Firebase Console.
// ============================================================

class AppConstants {
  // TODO: Paste your Firebase Realtime Database URL here
  // Example: https://my-todo-app-default-rtdb.firebaseio.com
  static const String databaseUrl =
      'https://login-ff68f-default-rtdb.firebaseio.com';

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
