import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  List<dynamic> _schools = [];

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  List<dynamic> get schools => _schools;

  AuthProvider() {
    checkAuthStatus();
    fetchSchools();
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      _isAuthenticated = true;
      // Fetch user profile to get school/level info
      try {
        final response = await _apiService.get('/user');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _user = data['user'];
        }
      } catch (e) {
        debugPrint('Error fetching user on start: $e');
      }
      notifyListeners();
    }
  }

  Future<void> fetchSchools() async {
    try {
      final response = await _apiService.get('/schools');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _schools = data['schools'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching schools: $e');
    }
  }

  Future<bool> register(String name, String username, String email, String password, String passwordConfirmation, {int? schoolId, String? level}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/register', {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        if (schoolId != null) 'school_id': schoolId,
        if (level != null) 'level': level,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Registration error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> verifyOtp(String email, String otp) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/verify-otp', {
        'email': email,
        'otp': otp,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        _user = data['user'];
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Verify OTP error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> resendOtp(String email) async {
    try {
      final response = await _apiService.post('/resend-otp', {
        'email': email,
      });
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Resend OTP error: $e');
      return false;
    }
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        _user = data['user'];
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return null;
      } else if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        if (data['email_not_verified'] == true) {
          _isLoading = false;
          notifyListeners();
          return 'unverified';
        }
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return 'Invalid credentials';
  }

  Future<void> logout() async {
    await _apiService.post('/logout', {});
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }

  Future<bool> updateProfile({String? name, String? username, String? level, double? cgpa}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/user/update', {
        if (name != null) 'name': name,
        if (username != null) 'username': username,
        if (level != null) 'level': level,
        if (cgpa != null) 'cgpa': cgpa,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = data['user'];
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> uploadProfilePicture(String filePath) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.multipartPost('/user/profile-picture', filePath);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Refresh user data to get the new profile picture URL
        final userResponse = await _apiService.get('/user');
        if (userResponse.statusCode == 200) {
          final userData = jsonDecode(userResponse.body);
          _user = userData['user'];
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Upload profile picture error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
