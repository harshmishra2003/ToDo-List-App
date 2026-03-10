import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import 'widgets/add_task_sheet.dart';
import 'widgets/edit_task_dialog.dart';
import 'widgets/task_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTasks());
  }

  Future<void> _loadTasks() async {
    final authProvider = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();
    final uid = authProvider.user?.uid;
    final idToken = await authProvider.getIdToken();
    if (uid != null && idToken != null) {
      await taskProvider.fetchTasks(uid, idToken);
    } else {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.darkCard,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_rounded,
              color: isError ? AppTheme.errorColor : AppTheme.successColor,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                    color: AppTheme.darkTextPrimary, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _showAddTask() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTaskSheet(),
    );
  }

  void _showEditTask(dynamic task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditTaskDialog(task: task),
    );
  }

  Future<void> _deleteTask(String taskId) async {
    final authProvider = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();
    final uid = authProvider.user?.uid;
    final idToken = await authProvider.getIdToken();
    if (uid == null || idToken == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Task',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: AppTheme.darkTextPrimary)),
        content: Text('This task will be permanently deleted.',
            style: GoogleFonts.poppins(color: AppTheme.darkTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppTheme.darkTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final deleted = await taskProvider.deleteTask(uid, idToken, taskId);
      _showSnack(
        deleted ? '🗑️ Task deleted!' : 'Failed to delete task.',
        isError: !deleted,
      );
    }
  }

  Future<void> _toggleTask(dynamic task) async {
    final authProvider = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();
    final uid = authProvider.user?.uid;
    final idToken = await authProvider.getIdToken();
    if (uid != null && idToken != null) {
      await taskProvider.toggleComplete(uid, idToken, task);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: AppTheme.darkTextPrimary)),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.poppins(color: AppTheme.darkTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppTheme.darkTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign Out', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      context.read<TaskProvider>().clearTasks();
      await context.read<AuthProvider>().signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkBgGradient),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadTasks,
            color: AppTheme.primaryColor,
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                _buildStatsBar(),
                _buildFilterChips(),
                _buildOfflineBanner(),
                _buildTaskList(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        // Theme indicator + menu
        Consumer<AuthProvider>(
          builder: (context, auth, _) => PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.3),
              child: Text(
                (auth.user?.email?.substring(0, 1) ?? 'U').toUpperCase(),
                style: GoogleFonts.poppins(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
            ),
            color: AppTheme.darkCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auth.user?.email ?? '',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.darkTextSecondary)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: AppTheme.errorColor, size: 18),
                    const SizedBox(width: 10),
                    Text('Sign Out',
                        style: GoogleFonts.poppins(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
            onSelected: (v) {
              if (v == 'signout') _signOut();
            },
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 0, 16),
        title: Consumer<AuthProvider>(
          builder: (context, auth, _) => Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.darkTextSecondary,
                    fontWeight: FontWeight.w400),
              ),
              Text(
                'My Tasks',
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkTextPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return SliverToBoxAdapter(
      child: Consumer<TaskProvider>(
        builder: (context, taskProvider, _) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Row(
            children: [
              _StatCard(
                label: 'Total',
                value: taskProvider.totalCount,
                color: AppTheme.primaryLight,
                icon: Icons.list_alt_rounded,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Active',
                value: taskProvider.activeCount,
                color: AppTheme.accentColor,
                icon: Icons.pending_actions,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Done',
                value: taskProvider.completedCount,
                color: AppTheme.successColor,
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SliverToBoxAdapter(
      child: Consumer<TaskProvider>(
        builder: (context, taskProvider, _) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: [
              _FilterChip(
                label: '📋 All',
                isSelected: taskProvider.filter == TaskFilter.all,
                onTap: () => taskProvider.setFilter(TaskFilter.all),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: '⏳ Active',
                isSelected: taskProvider.filter == TaskFilter.active,
                onTap: () => taskProvider.setFilter(TaskFilter.active),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: '✅ Done',
                isSelected: taskProvider.filter == TaskFilter.completed,
                onTap: () => taskProvider.setFilter(TaskFilter.completed),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Offline Banner ─────────────────────────────────────────────────────────
  Widget _buildOfflineBanner() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        if (!taskProvider.isOffline) return const SliverToBoxAdapter(child: SizedBox.shrink());
        final remaining = taskProvider.localTasksRemaining;
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📴 Offline Mode — Local Storage',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber,
                          ),
                        ),
                        Text(
                          remaining > 0
                              ? 'You can add $remaining more local task${remaining == 1 ? '' : 's'}. Pull to retry connection.'
                              : 'Local task limit reached (${taskProvider.localTaskCount}/${5}). Pull to retry.',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.amber.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _loadTasks,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.refresh, color: Colors.amber, size: 16),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.2, end: 0, duration: 300.ms),
          ),
        );
      },
    );
  }

  Widget _buildTaskList() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        if (taskProvider.isLoading) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }

        if (taskProvider.loadStatus == TaskLoadStatus.error) {
          return SliverFillRemaining(
            child: _ErrorState(onRetry: _loadTasks),
          );
        }

        final tasks = taskProvider.filteredTasks;
        if (tasks.isEmpty) {
          return SliverFillRemaining(
            child: _EmptyState(filter: taskProvider.filter),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final task = tasks[i];
                return TaskTile(
                  key: ValueKey(task.id),
                  task: task,
                  index: i,
                  onToggle: () => _toggleTask(task),
                  onEdit: () => _showEditTask(task),
                  onDelete: () => _deleteTask(task.id),
                );
              },
              childCount: tasks.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _showAddTask,
      icon: const Icon(Icons.add, size: 22),
      label: Text('Add Task', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    )
        .animate()
        .scale(delay: 400.ms, duration: 400.ms, curve: Curves.elasticOut);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning! ☀️';
    if (hour < 17) return 'Good afternoon! 🌤️';
    return 'Good evening! 🌙';
  }
}

// ── Stat Card Widget ──────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppTheme.darkTextSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Chip Widget ────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.25)
              : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.darkBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppTheme.primaryLight : AppTheme.darkTextSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final TaskFilter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    String icon;
    String title;
    String subtitle;
    switch (filter) {
      case TaskFilter.completed:
        icon = '🏆';
        title = 'No completed tasks yet';
        subtitle = 'Start checking off your tasks!';
        break;
      case TaskFilter.active:
        icon = '🎉';
        title = 'All tasks completed!';
        subtitle = 'Great job! Add more tasks to keep going.';
        break;
      case TaskFilter.all:
        icon = '📝';
        title = 'No tasks yet';
        subtitle = 'Tap the button below to add your first task';
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 64))
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkTextPrimary,
            ),
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.darkTextSecondary,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😵', style: TextStyle(fontSize: 56))
              .animate()
              .scale(duration: 400.ms),
          const SizedBox(height: 16),
          Text(
            'Oops! Failed to load tasks.',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: AppTheme.darkTextPrimary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Check your connection and try again.',
            style: GoogleFonts.poppins(color: AppTheme.darkTextSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
