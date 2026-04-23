import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'dashboard_view.dart';
import 'tasks_screen.dart';
import 'exams_screen.dart';
import 'chat_screen.dart';
import 'calm_screen.dart';
import 'package:provider/provider.dart';
import '../core/providers/navigation_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<Widget> _pages = [
    DashboardView(),
    TasksScreen(),
    ExamsScreen(),
    ChatScreen(),
    CalmScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Decorative Background Blobs
          Positioned(
            top: -100,
            right: -50,
            child: _blob(250, AppColors.primary.withOpacity(0.08)),
          ),
          Positioned(
            bottom: 200,
            left: -100,
            child: _blob(300, Colors.orange.withOpacity(0.05)),
          ),
          Positioned(
            top: 300,
            right: -150,
            child: _blob(400, AppColors.accent.withOpacity(0.06)),
          ),
          
          // Main Content
          IndexedStack(
            index: nav.currentIndex,
            children: _pages,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
              ),
              child: BottomNavigationBar(
                currentIndex: nav.currentIndex,
                onTap: (index) => nav.setTab(index),
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: Colors.grey.shade400,
                showSelectedLabels: true,
                showUnselectedLabels: false,
                elevation: 0,
                selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment_rounded), label: 'Tasks'),
                  BottomNavigationBarItem(icon: Icon(Icons.timer_outlined), activeIcon: Icon(Icons.timer_rounded), label: 'Exams'),
                  BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), activeIcon: Icon(Icons.chat_bubble_rounded), label: 'Chat'),
                  BottomNavigationBarItem(icon: Icon(Icons.spa_outlined), activeIcon: Icon(Icons.spa_rounded), label: 'Calm'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
