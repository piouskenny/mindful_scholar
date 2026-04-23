import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/task_provider.dart';
import '../core/providers/exam_provider.dart';
import 'package:intl/intl.dart';
import 'tasks_screen.dart';
import 'exams_screen.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchTasks();
      context.read<ExamProvider>().fetchExams();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer3<AuthProvider, TaskProvider, ExamProvider>(
        builder: (context, auth, taskProvider, examProvider, _) {
          final user = auth.user;
          final displayName = user?['name'] ?? user?['username'] ?? 'Scholar';
          final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wednesday, April 22',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Good morning, $displayName 👋',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: Text(
                        initial, 
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Daily Insight Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DAILY INSIGHT',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '"Focus on progress, not perfection."',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(140, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Open Calm Space →', style: TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Upcoming Exams
                _sectionHeader(
                  'Upcoming Exams', 
                  onSeeAll: () {
                    // Navigate to Exams Screen (handled by Navbar usually, but here for direct access)
                  },
                ),
                const SizedBox(height: 16),
                examProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : examProvider.exams.isEmpty
                    ? _emptyState('No upcoming exams')
                    : SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: examProvider.exams.length,
                          itemBuilder: (context, index) {
                            final exam = examProvider.exams[index];
                            return _examCard(
                              exam['course_code'], 
                              'Soon', // You could calculate days remaining here
                              'days'
                            );
                          },
                        ),
                      ),
                
                const SizedBox(height: 40),
                
                // Today's Tasks
                _sectionHeader(
                  'Today\'s Tasks',
                  onAdd: () => _showAddTaskDialog(context),
                  onSeeAll: () {
                     // Navigate to Tasks Screen
                  },
                ),
                const SizedBox(height: 16),
                taskProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : taskProvider.tasks.isEmpty
                    ? _emptyState('No tasks for today')
                    : Column(
                        children: taskProvider.tasks.map((task) {
                          return _taskTile(
                            task['id'],
                            task['title'], 
                            task['deadline'] ?? 'Today', 
                            task['is_urgent'] == 1 || task['is_urgent'] == true,
                            isCompleted: task['is_completed'] == 1 || task['is_completed'] == true,
                            onToggle: () => context.read<TaskProvider>().toggleTask(task['id']),
                          );
                        }).toList(),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onAdd, VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            if (onAdd != null)
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                onPressed: onAdd,
              ),
            TextButton(
              onPressed: onSeeAll,
              child: const Text('See all', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _emptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey.shade500),
        ),
      ),
    );
  }

  Widget _examCard(String code, String count, String unit) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Next exam', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            code,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                count,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentOrange,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _taskTile(int id, String title, String deadline, bool isUrgent, {bool isCompleted = false, VoidCallback? onToggle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.primary.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCompleted ? AppColors.primary : Colors.grey.shade300,
                ),
              ),
              child: isCompleted 
                ? const Icon(Icons.check, size: 16, color: AppColors.primary) 
                : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? Colors.grey : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  deadline,
                  style: TextStyle(
                    fontSize: 12,
                    color: isUrgent ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final deadlineController = TextEditingController();
    DateTime? selectedDate;
    String priority = 'Medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: 'Task title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: deadlineController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Select Deadline',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today, color: AppColors.primary),
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                          deadlineController.text = DateFormat('MMM dd, yyyy').format(picked);
                        });
                      }
                    },
                  ),
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                      deadlineController.text = DateFormat('MMM dd, yyyy').format(picked);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: ['Low', 'Medium', 'High'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (val) => setState(() => priority = val ?? 'Medium'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty && selectedDate != null) {
                  final success = await context.read<TaskProvider>().addTask(
                    titleController.text,
                    DateFormat('yyyy-MM-dd').format(selectedDate!),
                    priority,
                  );
                  if (success && mounted) {
                    Navigator.pop(context);
                  }
                } else if (selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a deadline')),
                  );
                }
              },
              child: const Text('Add Task'),
            ),
          ],
        ),
      ),
    );
  }
}
