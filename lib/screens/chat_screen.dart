import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
      drawer: _buildHistoryDrawer(context, isDark, chatbotProvider),
      appBar: AppBar(
        backgroundColor: (isDark ? Colors.black : Colors.white).withOpacity(0.8),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mindful AI',
                  style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
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
                        fontSize: 11, 
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
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<ChatbotProvider>().fetchHistory(),
            tooltip: 'Refresh chat',
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

  Widget _buildHistoryDrawer(BuildContext context, bool isDark, ChatbotProvider provider) {
    return Drawer(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      child: Column(
        children: [
          _buildDrawerHeader(isDark),
          Expanded(
            child: provider.messages.isEmpty
                ? _buildEmptyHistory(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: provider.messages.length,
                    itemBuilder: (context, index) {
                      final message = provider.messages[index];
                      if (message.isBot) return const SizedBox.shrink(); // Only show user prompts in history list
                      return ListTile(
                        leading: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                        title: Text(
                          message.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
                        ),
                        subtitle: Text(
                          _formatDate(message.createdAt),
                          style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
                        ),
                        onTap: () {
                          Navigator.pop(context); // Close drawer
                          // Optionally scroll to this message in the main list
                        },
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
            title: Text(
              'Clear History',
              style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            onTap: () {
              Navigator.pop(context);
              _showClearChatDialog(context);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(bool isDark) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05))),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                'Chat History',
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your recent conversations with Mindful AI',
            style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 48, color: isDark ? Colors.white10 : Colors.black12),
          const SizedBox(height: 12),
          Text(
            'No history yet',
            style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
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
            child: MarkdownBody(
              data: text,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.inter(fontSize: 15, height: 1.5, color: isDark ? Colors.white : Colors.black87),
                h1: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                h2: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                listBullet: GoogleFonts.inter(fontSize: 15, color: isDark ? Colors.white70 : Colors.black54),
                strong: const TextStyle(fontWeight: FontWeight.bold),
                em: const TextStyle(fontStyle: FontStyle.italic),
                code: TextStyle(
                  backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                  fontFamily: 'monospace',
                ),
              ),
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
