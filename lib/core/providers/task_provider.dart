import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TaskProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<dynamic> _tasks = [];
  bool _isLoading = false;

  List<dynamic> get tasks => _tasks;
  bool get isLoading => _isLoading;

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

  Future<bool> addTask(String title, String dueDate, String priority, {String? courseCode}) async {
    try {
      final response = await _apiService.post('/tasks', {
        'title': title,
        'due_date': dueDate,
        'priority': priority.toLowerCase(),
        'course_code': courseCode ?? '',
      });

      if (response.statusCode == 201) {
        await fetchTasks();
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
          _tasks[index]['is_completed'] = !_tasks[index]['is_completed'];
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error toggling task: $e');
    }
  }
}
