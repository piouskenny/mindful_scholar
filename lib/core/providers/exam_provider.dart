import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ExamProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<dynamic> _exams = [];
  bool _isLoading = false;

  List<dynamic> get exams => _exams;
  bool get isLoading => _isLoading;

  Future<void> fetchExams() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/exams');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _exams = data['exams'] ?? [];
      }
    } catch (e) {
      debugPrint('Error fetching exams: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addExam(String courseCode, String courseName, String examDate, {String? venue}) async {
    try {
      final response = await _apiService.post('/exams', {
        'course_code': courseCode,
        'course_name': courseName,
        'exam_date': examDate,
        'venue': venue ?? '',
      });

      if (response.statusCode == 201) {
        await fetchExams();
        return true;
      } else {
        debugPrint('Error adding exam. Status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception adding exam: $e');
    }
    return false;
  }
}
