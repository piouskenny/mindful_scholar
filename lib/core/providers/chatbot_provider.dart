import 'package:flutter/material.dart';
import '../services/chatbot_service.dart';

class ChatMessageModel {
  final int? id;
  final String message;
  final bool isBot;
  final DateTime createdAt;

  ChatMessageModel({
    this.id,
    required this.message,
    required this.isBot,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      message: json['message'],
      isBot: json['is_bot'] == 1 || json['is_bot'] == true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ChatbotProvider with ChangeNotifier {
  final ChatbotService _chatbotService = ChatbotService();
  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;

  List<ChatMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;

  Future<void> fetchHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final history = await _chatbotService.getHistory();
      _messages = history.map((m) => ChatMessageModel.fromJson(m)).toList();
    } catch (e) {
      debugPrint('Error fetching chat history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message locally for immediate feedback
    final tempUserMsg = ChatMessageModel(
      message: text,
      isBot: false,
      createdAt: DateTime.now(),
    );
    _messages.add(tempUserMsg);
    
    _isSending = true;
    notifyListeners();

    try {
      final response = await _chatbotService.sendMessage(text);
      if (response['success'] == true) {
        // Replace temp messages or just refresh history? 
        // Better to just add the bot message from response
        final data = response['data'];
        
        // Remove the temp user message and add the one from server (which has ID and correct timestamp)
        _messages.removeLast();
        _messages.add(ChatMessageModel.fromJson(data['user_message']));
        _messages.add(ChatMessageModel.fromJson(data['bot_message']));
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      // Optionally add an error message from bot
      _messages.add(ChatMessageModel(
        message: 'Sorry, I\'m having trouble connecting right now. Please try again later.',
        isBot: true,
        createdAt: DateTime.now(),
      ));
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    try {
      await _chatbotService.clearHistory();
      _messages.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }
}
