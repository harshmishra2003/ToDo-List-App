import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../models/task_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/task_provider.dart';

class EditTaskDialog extends StatefulWidget {
  final Task task;
  const EditTaskDialog({super.key, required this.task});

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late String _priority;
  late bool _isCompleted;
  bool _isSaving = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
    _priority = widget.task.priority;
    _isCompleted = widget.task.isCompleted;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() { _isSaving = true; _errorMsg = null; });

    final authProvider = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();
    final uid = authProvider.user?.uid;
    final idToken = await authProvider.getIdToken();
    if (uid == null || idToken == null) {
      setState(() { _isSaving = false; _errorMsg = 'Not authenticated.'; });
      return;
    }

    final updated = widget.task.copyWith(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      priority: _priority,
      isCompleted: _isCompleted,
    );

    try {
      await taskProvider.updateTask(uid, idToken, updated);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.darkCard,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            duration: const Duration(seconds: 3),
            content: Row(
              children: [
                const Icon(Icons.edit_note, color: AppTheme.primaryLight, size: 20),
                const SizedBox(width: 10),
                Text('✏️ Task updated!',
                    style: GoogleFonts.poppins(color: AppTheme.darkTextPrimary)),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMsg = 'Failed to save. Check your connection.';
        });
      }
    }
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 20),

          Row(
            children: [
              const Icon(Icons.edit_outlined, color: AppTheme.primaryLight, size: 22),
              const SizedBox(width: 10),
              Text(
                'Edit Task',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Title
          TextFormField(
            controller: _titleController,
            autofocus: true,
            style: const TextStyle(color: AppTheme.darkTextPrimary),
            decoration: const InputDecoration(
              labelText: 'Task title',
              prefixIcon: Icon(Icons.title, color: AppTheme.primaryLight),
            ),
          ),
          const SizedBox(height: 14),

          // Description
          TextFormField(
            controller: _descController,
            maxLines: 2,
            style: const TextStyle(color: AppTheme.darkTextPrimary),
            decoration: const InputDecoration(
              labelText: 'Description',
              prefixIcon: Icon(Icons.notes, color: AppTheme.primaryLight),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 18),

          // Priority
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
          const SizedBox(height: 14),

          // Completion toggle
          GestureDetector(
            onTap: () => setState(() => _isCompleted = !_isCompleted),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _isCompleted
                    ? AppTheme.successColor.withValues(alpha: 0.15)
                    : AppTheme.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isCompleted ? AppTheme.successColor : AppTheme.darkBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: _isCompleted
                        ? AppTheme.successColor
                        : AppTheme.darkTextSecondary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isCompleted ? 'Completed ✓' : 'Mark as completed',
                    style: GoogleFonts.poppins(
                      color: _isCompleted
                          ? AppTheme.successColor
                          : AppTheme.darkTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Buttons
          Consumer<TaskProvider>(
            builder: (context, taskProvider, _) => Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.darkBorder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.poppins(
                            color: AppTheme.darkTextSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _isSaving
                      ? Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: const Text('Save Changes'),
                        ),
                ),
              ],
            ),
          ),
        ],
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
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
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
