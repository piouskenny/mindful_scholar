import 'dart:convert';
import 'api_service.dart';

class ChatbotService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> sendMessage(String message) async {
    final response = await _apiService.post('/chatbot/send', {
      'message': message,
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  Future<List<dynamic>> getHistory() async {
    final response = await _apiService.get('/chatbot/history');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['messages'];
    } else {
      throw Exception('Failed to load chat history');
    }
  }

  Future<void> clearHistory() async {
    final response = await _apiService.post('/chatbot/clear', {});

    if (response.statusCode != 200) {
      throw Exception('Failed to clear chat history');
    }
  }
}
