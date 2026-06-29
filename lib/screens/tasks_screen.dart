import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/task_provider.dart';
import '../core/services/notification_service.dart';

// ────────────────────────────────────────────────────────────────────────────
// Task type metadata
// ────────────────────────────────────────────────────────────────────────────

const _taskTypes = [
  {'value': 'assignment', 'label': 'Assignment', 'emoji': '📚', 'isSchool': true},
  {'value': 'reading',    'label': 'Reading',    'emoji': '📖', 'isSchool': true},
  {'value': 'project',    'label': 'Project',    'emoji': '💼', 'isSchool': true},
  {'value': 'fun',        'label': 'Fun',        'emoji': '🎮', 'isSchool': false},
  {'value': 'other',      'label': 'Other',      'emoji': '✏️', 'isSchool': false},
];

const _schoolTypes = {'assignment', 'reading', 'project'};

Map<String, dynamic> _typeData(String type) =>
    _taskTypes.firstWhere((t) => t['value'] == type,
        orElse: () => _taskTypes.last);

Color _priorityColor(String priority) {
  switch (priority.toLowerCase()) {
    case 'high':   return const Color(0xFFE53E3E);
    case 'medium': return const Color(0xFFF6AD55);
    default:       return const Color(0xFF68D391);
  }
}

Color _deadlineColor(String? dueDateStr) {
  if (dueDateStr == null) return Colors.grey;
  try {
    final due = DateTime.parse(dueDateStr);
    final diff = due.difference(DateTime.now());
    if (diff.inHours <= 24) return const Color(0xFFE53E3E);
    if (diff.inDays <= 3)   return const Color(0xFFF6AD55);
    return const Color(0xFF68D391);
  } catch (_) {
    return Colors.grey;
  }
}

String _deadlineLabel(String? dueDateStr) {
  if (dueDateStr == null) return 'No date';
  try {
    final due = DateTime.parse(dueDateStr);
    final diff = due.difference(DateTime.now());
    if (diff.inHours <= 1  && diff.inMinutes > 0) return '< 1 hr left!';
    if (diff.inHours <= 24 && diff.inHours > 0)   return '${diff.inHours}h left';
    if (diff.inDays == 0)                          return 'Due today';
    if (diff.inDays == 1)                          return 'Due tomorrow';
    return DateFormat('MMM d').format(due);
  } catch (_) {
    return dueDateStr;
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Screen
// ────────────────────────────────────────────────────────────────────────────

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heroController;
  late final Animation<double> _heroAnimation;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _heroAnimation = CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOutBack,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchTasks();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  // ── Filter tabs definition ─────────────────────────────────────────────────

  static const _filters = [
    {'value': 'all',        'label': 'All',        'icon': Icons.apps_rounded},
    {'value': 'school',     'label': '⭐ School',   'icon': Icons.school_rounded},
    {'value': 'assignment', 'label': 'Assignment',  'icon': Icons.assignment_rounded},
    {'value': 'reading',    'label': 'Reading',     'icon': Icons.menu_book_rounded},
    {'value': 'project',    'label': 'Project',     'icon': Icons.work_rounded},
    {'value': 'fun',        'label': 'Fun',         'icon': Icons.sports_esports_rounded},
    {'value': 'other',      'label': 'Other',       'icon': Icons.more_horiz_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Consumer<TaskProvider>(
        builder: (context, tp, _) {
          final allTasks    = tp.allTasks;
          final total       = allTasks.length;
          final completed   = allTasks.where((t) =>
              t['is_completed'] == 1 || t['is_completed'] == true).length;
          final progress    = total == 0 ? 0.0 : completed / total;
          final urgent      = tp.urgentTasks;
          final schoolDue   = tp.schoolTasksDueToday;
          final displayedTasks = tp.tasks;

          return Column(
            children: [
              // ── Hero banner ───────────────────────────────────────────────
              _buildHeroBanner(
                progress:   progress,
                total:      total,
                completed:  completed,
                urgent:     urgent.length,
                schoolDue:  schoolDue.length,
                isDark:     isDark,
                onAdd:      () => _showAddTaskSheet(context),
              ),
              // ── Filter tabs ───────────────────────────────────────────────
              _buildFilterTabs(tp.activeFilter, isDark, tp),
              // ── Task list ─────────────────────────────────────────────────
              Expanded(
                child: tp.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : displayedTasks.isEmpty
                        ? _emptyState(isDark, tp.activeFilter)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                            itemCount: displayedTasks.length,
                            itemBuilder: (context, index) {
                              final task = displayedTasks[index];
                              return _TaskCard(
                                task: task,
                                isDark: isDark,
                                onToggle: () => tp.toggleTask(task['id']),
                                onDelete: () => tp.deleteTask(task['id']),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Hero Banner ─────────────────────────────────────────────────────────────

  Widget _buildHeroBanner({
    required double progress,
    required int total,
    required int completed,
    required int urgent,
    required int schoolDue,
    required bool isDark,
    required VoidCallback onAdd,
  }) {
    return ScaleTransition(
      scale: _heroAnimation,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF436850)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Progress ring
            SizedBox(
              width: 90,
              height: 90,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(progress * 100).round()}%',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'done',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Stats + chips
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Tasks',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completed of $total completed',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (urgent > 0)
                        _heroBadge('⚠️ $urgent urgent', const Color(0xFFFC8181)),
                      if (schoolDue > 0)
                        _heroBadge('📚 $schoolDue school due today',
                            const Color(0xFFFBD38D)),
                      if (urgent == 0 && schoolDue == 0)
                        _heroBadge('✅ On track!', Colors.white.withOpacity(0.3)),
                    ],
                  ),
                ],
              ),
            ),
            // Add button
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 26),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  // ── Filter Tabs ─────────────────────────────────────────────────────────────

  Widget _buildFilterTabs(
      String active, bool isDark, TaskProvider tp) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: _filters.map((f) {
            final isActive = active == f['value'];
            return GestureDetector(
              onTap: () => tp.setFilter(f['value'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : (isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(20),
                  border: isActive
                      ? null
                      : Border.all(
                          color: isDark
                              ? Colors.white12
                              : Colors.grey.shade200,
                        ),
                ),
                child: Text(
                  f['label'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? Colors.white
                        : (isDark
                            ? Colors.white54
                            : Colors.grey.shade600),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────

  Widget _emptyState(bool isDark, String filter) {
    final message = filter == 'all'
        ? 'No tasks yet — tap + to add one!'
        : 'No ${filter == "school" ? "school" : filter} tasks yet.';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('📋', style: GoogleFonts.inter(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              color: isDark ? Colors.white38 : Colors.grey.shade500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ── Add Task Bottom Sheet ───────────────────────────────────────────────────

  void _showAddTaskSheet(BuildContext context) {
    final titleController = TextEditingController();
    final courseController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay selectedTime = TimeOfDay.now();
    String selectedType = 'assignment';
    String priority = 'medium';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final typeData = _typeData(selectedType);
          final isSchool = _schoolTypes.contains(selectedType);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1A1A2E)
                    : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 30,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white24
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            typeData['emoji'] as String,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Task',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              typeData['label'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Task type selector
                    Text(
                      'Task Type',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _typeGrid(
                      selectedType: selectedType,
                      isDark: isDark,
                      onSelect: (t) =>
                          setSheetState(() => selectedType = t),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    _inputLabel('Title', isDark),
                    const SizedBox(height: 8),
                    _textField(
                      controller: titleController,
                      hint: 'e.g. Write chapter 3 report',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    // Course code (school only)
                    if (isSchool) ...[
                      _inputLabel('Course Code (optional)', isDark),
                      const SizedBox(height: 8),
                      _textField(
                        controller: courseController,
                        hint: 'e.g. CS301',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Priority
                    _inputLabel('Priority', isDark),
                    const SizedBox(height: 8),
                    Row(
                      children: ['low', 'medium', 'high'].map((p) {
                        final isActive = priority == p;
                        final color = _priorityColor(p);
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => priority = p),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? color.withOpacity(0.15)
                                  : (isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(12),
                              border: isActive
                                  ? Border.all(color: color, width: 1.5)
                                  : null,
                            ),
                            child: Text(
                              p[0].toUpperCase() + p.substring(1),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: isActive
                                    ? color
                                    : (isDark
                                        ? Colors.white54
                                        : Colors.grey.shade600),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Deadline (date + time)
                    _inputLabel('Deadline', isDark),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null) {
                          if (!ctx.mounted) return;
                          final timePicked = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.now(),
                          );
                          setSheetState(() {
                            selectedDate = picked;
                            if (timePicked != null) selectedTime = timePicked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.07)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selectedDate != null
                                ? AppColors.primary.withOpacity(0.6)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              selectedDate == null
                                  ? 'Select date & time'
                                  : '${DateFormat('MMM dd, yyyy').format(selectedDate!)} at ${selectedTime.format(ctx)}',
                              style: GoogleFonts.inter(
                                color: selectedDate == null
                                    ? (isDark
                                        ? Colors.white38
                                        : Colors.grey.shade400)
                                    : (isDark ? Colors.white : Colors.black),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (titleController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please enter a task title')),
                            );
                            return;
                          }
                          if (selectedDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please select a deadline')),
                            );
                            return;
                          }

                          final deadlineWithTime = DateTime(
                            selectedDate!.year,
                            selectedDate!.month,
                            selectedDate!.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                          // Request notification permission first
                          await NotificationService().requestPermission();

                          final success = await context
                              .read<TaskProvider>()
                              .addTask(
                                titleController.text.trim(),
                                DateFormat('yyyy-MM-dd').format(selectedDate!),
                                priority,
                                taskType: selectedType,
                                courseCode: courseController.text.trim().isEmpty
                                    ? null
                                    : courseController.text.trim(),
                                deadlineWithTime: deadlineWithTime,
                              );

                          if (success && ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Add Task',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Type grid ───────────────────────────────────────────────────────────────

  Widget _typeGrid({
    required String selectedType,
    required bool isDark,
    required ValueChanged<String> onSelect,
  }) {
    return GridView.count(
      crossAxisCount: 5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: _taskTypes.map((type) {
        final isSelected = selectedType == type['value'];
        final isSchool = type['isSchool'] == true;
        return GestureDetector(
          onTap: () => onSelect(type['value'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.15)
                  : (isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(14),
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 1.8)
                  : (isSchool
                      ? Border.all(
                          color: AppColors.primary.withOpacity(0.25),
                          width: 1)
                      : null),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(type['emoji'] as String,
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(
                  (type['label'] as String).split(' ').first,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? Colors.white54 : Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _inputLabel(String label, bool isDark) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white60 : Colors.grey.shade600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400),
        filled: true,
        fillColor:
            isDark ? Colors.white.withOpacity(0.07) : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.primary.withOpacity(0.6), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Task Card widget
// ────────────────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.isDark,
    required this.onToggle,
    required this.onDelete,
  });

  final Map<String, dynamic> task;
  final bool isDark;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isCompleted =
        task['is_completed'] == 1 || task['is_completed'] == true;
    final type = task['task_type'] ?? 'other';
    final typeData = _typeData(type);
    final isSchool = _schoolTypes.contains(type);
    final priority = task['priority'] ?? 'medium';
    final dueDateStr = task['due_date'] as String?;
    final dlColor = isCompleted ? Colors.grey : _deadlineColor(dueDateStr);
    final dlLabel = isCompleted
        ? DateFormat('MMM d').format(DateTime.tryParse(dueDateStr ?? '') ?? DateTime.now())
        : _deadlineLabel(dueDateStr);
    final isUrgent = !isCompleted &&
        (dueDateStr != null) &&
        (() {
          try {
            return DateTime.parse(dueDateStr)
                .difference(DateTime.now())
                .inHours <=
                24;
          } catch (_) {
            return false;
          }
        })();

    return Dismissible(
      key: Key('task_${task['id']}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete task?'),
            content: Text(
                'Remove "${task['title']}"? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white),
            SizedBox(height: 4),
            Text('Delete',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!isCompleted && isSchool)
              BoxShadow(
                color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? Colors.black : Colors.white)
                    .withOpacity(0.88),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSchool && !isCompleted
                      ? AppColors.primary.withOpacity(0.2)
                      : (isDark ? Colors.white : Colors.black)
                          .withOpacity(0.05),
                  width: 1.3,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Checkbox
                  GestureDetector(
                    onTap: onToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: isCompleted
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.white24
                                  : Colors.grey.shade300),
                          width: 1.8,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check_rounded,
                              size: 17, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isSchool && !isCompleted)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Text(typeData['emoji'] as String,
                                    style: const TextStyle(fontSize: 14)),
                              ),
                            Expanded(
                              child: Text(
                                task['title'] ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isCompleted
                                      ? Colors.grey
                                      : (isDark
                                          ? Colors.white
                                          : Colors.black87),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            // Type badge
                            _badge(
                              typeData['label'] as String,
                              isSchool
                                  ? AppColors.primary.withOpacity(0.12)
                                  : (isDark
                                      ? Colors.white12
                                      : Colors.grey.shade100),
                              isSchool
                                  ? AppColors.primary
                                  : (isDark
                                      ? Colors.white54
                                      : Colors.grey.shade600),
                            ),
                            // Course code
                            if ((task['course_code'] ?? '').isNotEmpty)
                              _badge(
                                task['course_code'],
                                Colors.blue.withOpacity(0.1),
                                Colors.blue,
                              ),
                            // Priority
                            _badge(
                              priority[0].toUpperCase() + priority.substring(1),
                              _priorityColor(priority).withOpacity(0.12),
                              _priorityColor(priority),
                            ),
                            // Deadline
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isUrgent
                                      ? Icons.warning_amber_rounded
                                      : Icons.schedule_rounded,
                                  size: 12,
                                  color: dlColor,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  dlLabel,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: dlColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: GoogleFonts.inter(
            color: text, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
