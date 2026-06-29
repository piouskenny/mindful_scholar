import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();

  List<dynamic> _tasks = [];
  bool _isLoading = false;
  String _activeFilter = 'all'; // all | school | assignment | reading | fun | project | other

  List<dynamic> get tasks => _filteredTasks();
  List<dynamic> get allTasks => _tasks;
  bool get isLoading => _isLoading;
  String get activeFilter => _activeFilter;

  /// School tasks (assignment + reading + project) sorted first
  List<dynamic> get schoolTasks => _tasks
      .where((t) => ['assignment', 'reading', 'project'].contains(t['task_type']))
      .toList();

  /// Tasks due within 24 hours and not completed
  List<dynamic> get urgentTasks {
    final now = DateTime.now();
    return _tasks.where((t) {
      if (t['is_completed'] == true || t['is_completed'] == 1) return false;
      try {
        final due = DateTime.parse(t['due_date']);
        return due.difference(now).inHours <= 24 && due.isAfter(now);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  /// School tasks due today
  List<dynamic> get schoolTasksDueToday {
    final today = DateTime.now();
    return _tasks.where((t) {
      if (t['is_completed'] == true || t['is_completed'] == 1) return false;
      if (!['assignment', 'reading', 'project'].contains(t['task_type'])) return false;
      try {
        final due = DateTime.parse(t['due_date']);
        return due.year == today.year &&
            due.month == today.month &&
            due.day == today.day;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  List<dynamic> _filteredTasks() {
    List<dynamic> result;
    if (_activeFilter == 'all') {
      result = List.from(_tasks);
    } else if (_activeFilter == 'school') {
      result = _tasks
          .where((t) => ['assignment', 'reading', 'project'].contains(t['task_type']))
          .toList();
    } else {
      result = _tasks.where((t) => t['task_type'] == _activeFilter).toList();
    }

    // School-related tasks always float to the top
    result.sort((a, b) {
      final aIsSchool = ['assignment', 'reading', 'project'].contains(a['task_type']);
      final bIsSchool = ['assignment', 'reading', 'project'].contains(b['task_type']);
      if (aIsSchool && !bIsSchool) return -1;
      if (!aIsSchool && bIsSchool) return 1;
      // Secondary sort: incomplete first
      final aComplete = a['is_completed'] == 1 || a['is_completed'] == true;
      final bComplete = b['is_completed'] == 1 || b['is_completed'] == true;
      if (!aComplete && bComplete) return -1;
      if (aComplete && !bComplete) return 1;
      return 0;
    });

    return result;
  }

  void setFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  Future<void> fetchTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/tasks');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _tasks = data['tasks'] ?? [];
      }
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addTask(
    String title,
    String dueDate,
    String priority, {
    String taskType = 'assignment',
    String? courseCode,
    DateTime? deadlineWithTime,
  }) async {
    try {
      final response = await _apiService.post('/tasks', {
        'title': title,
        'due_date': dueDate,
        'priority': priority.toLowerCase(),
        'task_type': taskType,
        'course_code': courseCode ?? '',
      });

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final newTask = data['task'];
        await fetchTasks();

        // Schedule push notifications if deadline is in the future
        if (deadlineWithTime != null && deadlineWithTime.isAfter(DateTime.now())) {
          await _notificationService.scheduleDeadlineNotifications(
            taskId: newTask['id'],
            taskTitle: title,
            taskType: taskType,
            deadline: deadlineWithTime,
          );
        }
        return true;
      } else {
        debugPrint('Error adding task. Status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception adding task: $e');
    }
    return false;
  }

  Future<void> toggleTask(int id) async {
    try {
      final response = await _apiService.patch('/tasks/$id/toggle', {});
      if (response.statusCode == 200) {
        final index = _tasks.indexWhere((t) => t['id'] == id);
        if (index != -1) {
          _tasks[index]['is_completed'] = !(_tasks[index]['is_completed'] == true || _tasks[index]['is_completed'] == 1);
          notifyListeners();
          // Cancel notifications when task completed
          if (_tasks[index]['is_completed'] == true) {
            await _notificationService.cancelTaskNotifications(id);
          }
        }
      }
    } catch (e) {
      debugPrint('Error toggling task: $e');
    }
  }

  Future<bool> deleteTask(int id) async {
    try {
      final response = await _apiService.delete('/tasks/$id');
      if (response.statusCode == 200) {
        _tasks.removeWhere((t) => t['id'] == id);
        notifyListeners();
        // Cancel any scheduled notifications
        await _notificationService.cancelTaskNotifications(id);
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting task: $e');
    }
    return false;
  }
}
