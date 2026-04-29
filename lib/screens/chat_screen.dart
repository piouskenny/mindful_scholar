import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/chatbot_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatbotProvider>().fetchHistory();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatbotProvider = context.watch<ChatbotProvider>();

    // Scroll to bottom when messages change or while sending
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: (isDark ? Colors.black : Colors.white).withOpacity(0.8),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mindful AI',
                  style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: chatbotProvider.isSending ? Colors.grey : Colors.orange, 
                        shape: BoxShape.circle
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      chatbotProvider.isSending ? 'Thinking...' : 'Online',
                      style: GoogleFonts.inter(
                        color: chatbotProvider.isSending ? Colors.grey : Colors.orange, 
                        fontSize: 12, 
                        fontWeight: FontWeight.w500
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _showClearChatDialog(context),
            tooltip: 'Clear history',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatbotProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : chatbotProvider.messages.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(24),
                        itemCount: chatbotProvider.messages.length,
                        itemBuilder: (context, index) {
                          final message = chatbotProvider.messages[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: message.isBot
                                ? _botMessage(message.message, isDark)
                                : _userMessage(message.message),
                          );
                        },
                      ),
          ),
          
          if (chatbotProvider.messages.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _actionChip('How to study?', isDark),
                  _actionChip('I feel stressed 🧘', isDark),
                  _actionChip('Upcoming exams', isDark),
                ],
              ),
            ),
          
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.black : Colors.white).withOpacity(0.8),
                  border: Border(top: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05))),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 20, offset: const Offset(0, -5)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white10 : Colors.white54),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: (isDark ? Colors.white12 : Colors.black12)),
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          onSubmitted: (value) => _handleSend(),
                          decoration: InputDecoration(
                            hintText: 'Ask anything...',
                            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: chatbotProvider.isSending ? null : _handleSend,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: chatbotProvider.isSending ? Colors.grey : AppColors.primary, 
                          shape: BoxShape.circle
                        ),
                        child: chatbotProvider.isSending 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      context.read<ChatbotProvider>().sendMessage(text);
      _messageController.clear();
    }
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 64, color: AppColors.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'How can I help you today?',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me about your studies, tasks, or exams.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History?'),
        content: const Text('This will delete all your conversations with Mindful AI.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<ChatbotProvider>().clearHistory();
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _botMessage(String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 14),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white10 : Colors.white).withOpacity(0.9),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 15, height: 1.5, color: isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
      ],
    );
  }

  Widget _userMessage(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 15, height: 1.5, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionChip(String label, bool isDark) {
    return GestureDetector(
      onTap: () {
        _messageController.text = label;
        _handleSend();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white10 : Colors.white).withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (isDark ? Colors.white12 : Colors.black12)),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}
