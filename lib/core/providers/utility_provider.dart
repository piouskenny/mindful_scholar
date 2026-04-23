import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UtilityProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _dailyAffirmation;
  List<dynamic> _notifications = [];
  bool _isLoading = false;
  bool _hasNewNotifications = false;

  Map<String, dynamic>? get dailyAffirmation => _dailyAffirmation;
  List<dynamic> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get hasNewNotifications => _hasNewNotifications;

  void markAsRead() {
    _hasNewNotifications = false;
    notifyListeners();
  }

  Future<void> fetchDailyAffirmation() async {
    _isLoading = true;
    try {
      final response = await _apiService.get('/daily-affirmation');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _dailyAffirmation = data['affirmation'];
      }
    } catch (e) {
      debugPrint('Error fetching affirmation: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    try {
      final response = await _apiService.get('/notifications');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _notifications = data['notifications'];
        if (_notifications.isNotEmpty) {
          _hasNewNotifications = true;
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
    _isLoading = false;
    notifyListeners();
  }
}
