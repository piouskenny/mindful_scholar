import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/task_provider.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<TaskProvider>(
        builder: (context, taskProvider, _) {
          final tasks = taskProvider.tasks;
          final completedCount = tasks.where((t) => t['is_completed'] == 1 || t['is_completed'] == true).length;
          final progress = tasks.isEmpty ? 0.0 : completedCount / tasks.length;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Tasks',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$completedCount/${tasks.length} completed',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _showAddTaskDialog(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade100,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),
                // Filters
                Row(
                  children: [
                    _filterChip('All', true),
                    const SizedBox(width: 8),
                    _filterChip('Pending', false),
                    const SizedBox(width: 8),
                    _filterChip('Done', false),
                  ],
                ),
                const SizedBox(height: 32),
                // Task List
                Expanded(
                  child: taskProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : tasks.isEmpty
                      ? const Center(child: Text('No tasks found. Add one!'))
                      : ListView.builder(
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            final isUrgent = task['is_urgent'] == 1 || task['is_urgent'] == true;
                            
                            return _taskItem(
                              task['id'],
                              task['title'],
                              task['course_code'] ?? '',
                              isUrgent ? 'High' : 'Low',
                              task['deadline'] ?? 'No date',
                              isUrgent ? Colors.red.shade100 : Colors.blue.shade100,
                              isUrgent ? const Color(0xFFE85D4A) : Colors.blue.shade400,
                              isCompleted: task['is_completed'] == 1 || task['is_completed'] == true,
                              onToggle: () => taskProvider.toggleTask(task['id']),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filterChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.grey.shade600,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _taskItem(
    int id,
    String title,
    String code,
    String priority,
    String date,
    Color priorityBg,
    Color priorityText, {
    bool isCompleted = false,
    VoidCallback? onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCompleted ? AppColors.primary : Colors.grey.shade300,
                ),
              ),
              child: isCompleted 
                ? const Icon(Icons.check, size: 18, color: Colors.white) 
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? Colors.grey : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (code.isNotEmpty) ...[
                      _badge(code, Colors.blue.shade50, Colors.blue.shade600),
                      const SizedBox(width: 8),
                    ],
                    _badge(priority, priorityBg, priorityText),
                    const SizedBox(width: 12),
                    Text(
                      date,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.delete_outline, color: Colors.grey.shade300),
        ],
      ),
    );
  }

  Widget _badge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
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
