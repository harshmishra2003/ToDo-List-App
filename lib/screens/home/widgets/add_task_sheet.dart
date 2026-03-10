import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../models/task_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/task_provider.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _priority = AppConstants.priorityMedium;
  String? _errorMsg;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMsg = null;
    });

    final authProvider = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();
    final uid = authProvider.user?.uid;
    final idToken = await authProvider.getIdToken();

    if (uid == null || idToken == null) {
      setState(() {
        _isSubmitting = false;
        _errorMsg = 'Not logged in. Please sign in again.';
      });
      return;
    }

    final task = Task(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      priority: _priority,
      createdAt: DateTime.now(),
    );

    try {
      final newId = await taskProvider.addTaskRaw(uid, idToken, task);
      if (mounted) {
        Navigator.pop(context); // ← closes the sheet
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar(
            message: '✅ Task added successfully!',
            color: AppTheme.successColor,
            icon: Icons.check_circle_rounded,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMsg = 'Failed to add task: ${_friendlyError(e.toString())}';
        });
      }
    }
  }

  String _friendlyError(String error) {
    if (error.contains('401') || error.contains('Unauthorized')) {
      return 'Authentication failed. Try signing out and back in.';
    }
    if (error.contains('403') || error.contains('Permission denied')) {
      return 'Database permission denied. Check Firebase Rules.';
    }
    if (error.contains('network') || error.contains('SocketException')) {
      return 'No internet connection.';
    }
    if (error.contains('null') || error.contains('YOUR_FIREBASE')) {
      return 'Firebase not configured. Check database URL.';
    }
    return 'Server error. Please retry.';
  }

  SnackBar _buildSnackBar({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppTheme.darkCard,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 3),
      content: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(color: AppTheme.darkTextPrimary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomPad),
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.darkBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header row with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '✨ New Task',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkTextPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppTheme.darkTextSecondary),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Error message
            if (_errorMsg != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMsg!,
                        style: GoogleFonts.poppins(color: AppTheme.errorColor, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Title
            TextFormField(
              controller: _titleController,
              autofocus: true,
              style: const TextStyle(color: AppTheme.darkTextPrimary),
              decoration: const InputDecoration(
                labelText: 'Task title *',
                prefixIcon: Icon(Icons.title, color: AppTheme.primaryLight),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Please enter a title' : null,
              onChanged: (_) => setState(() => _errorMsg = null),
            ),
            const SizedBox(height: 14),

            // Description
            TextFormField(
              controller: _descController,
              maxLines: 2,
              style: const TextStyle(color: AppTheme.darkTextPrimary),
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                prefixIcon: Icon(Icons.notes, color: AppTheme.primaryLight),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // Priority selector
            Text(
              'Priority',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkTextSecondary,
                  fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                AppConstants.priorityLow,
                AppConstants.priorityMedium,
                AppConstants.priorityHigh,
              ]
                  .map((p) => _PriorityOption(
                        priority: p,
                        isSelected: _priority == p,
                        onTap: () => setState(() => _priority = p),
                      ))
                  .expand((w) => [w, const SizedBox(width: 10)])
                  .toList()
                ..removeLast(),
            ),

            const SizedBox(height: 28),

            // Submit
            SizedBox(
              width: double.infinity,
              child: _isSubmitting
                  ? Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Text('Adding task...',
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Add Task'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityOption extends StatelessWidget {
  final String priority;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityOption({
    required this.priority,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.priorityColor(priority);
    final label = priority[0].toUpperCase() + priority.substring(1);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : AppTheme.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppTheme.darkBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? color : AppTheme.darkTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
