import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/task_provider.dart';
import '../core/providers/exam_provider.dart';
import 'package:intl/intl.dart';
import 'profile_screen.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchTasks();
      context.read<ExamProvider>().fetchExams().then((_) {
        _checkUpcomingExams();
      });
    });
  }

  void _checkUpcomingExams() {
    final exams = context.read<ExamProvider>().exams;
    if (exams.isNotEmpty) {
      final nextExam = exams.first;
      final daysLeft = nextExam['days_left'];
      
      if (daysLeft != null && daysLeft <= 7 && daysLeft >= 0) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            title: const Text('Exam Reminder! 📚'),
            content: Text('Your exam for ${nextExam['course_code']} is in $daysLeft days. Time to focus!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        );
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, TaskProvider, ExamProvider>(
      builder: (context, auth, taskProvider, examProvider, _) {
        final user = auth.user;
        final name = user?['name'] ?? 'Scholar';
        final username = user?['username'] ?? 'Scholar';
        final displayName = username; // User requested username specifically
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, MMMM d').format(DateTime.now()),
                        style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_getGreeting()}, $displayName 👋',
                        style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(initial, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              if (auth.user?['school_id'] == null)
                _completeProfilePrompt(context),
              
              // Glassmorphism Insight Card
              _glassInsightCard(),
              
              const SizedBox(height: 40),
              
              // Upcoming Exams Section
              _sectionHeader('Upcoming Exams'),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                child: examProvider.exams.isEmpty
                  ? _emptyState('No upcoming exams')
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: examProvider.exams.length,
                      itemBuilder: (context, index) {
                        final exam = examProvider.exams[index];
                        final days = exam['days_left'] ?? 0;
                        return _glassExamCard(
                          exam['course_code'], 
                          days.toString(),
                          isUrgent: days <= 3,
                        );
                      },
                    ),
              ),
              
              const SizedBox(height: 40),
              
              // Today's Tasks
              _sectionHeader('Today\'s Tasks'),
              const SizedBox(height: 16),
              taskProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : taskProvider.tasks.isEmpty
                  ? _emptyState('No tasks for today')
                  : Column(
                      children: taskProvider.tasks.map((task) {
                        return _glassTaskTile(task);
                      }).toList(),
                    ),
              const SizedBox(height: 100), // Space for navbar
            ],
          ),
        );
      },
    );
  }

  Widget _glassInsightCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daily Insight',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              const SizedBox(height: 12),
              const Text(
                '"Focus on the process, not just the outcome."',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Open Calm Space →', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassExamCard(String code, String count, {bool isUrgent = false}) {
    final color = isUrgent ? Colors.red : AppColors.primary;
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next exam', style: GoogleFonts.inter(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(code, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(count, style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: color)),
                    const SizedBox(width: 4),
                    Text('days', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassTaskTile(Map<String, dynamic> task) {
    final isCompleted = task['is_completed'] == 1 || task['is_completed'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.read<TaskProvider>().toggleTask(task['id']),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isCompleted ? AppColors.primary : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: isCompleted ? AppColors.primary : Colors.grey.shade300, width: 2),
                    ),
                    child: Icon(Icons.check, size: 14, color: isCompleted ? Colors.white : Colors.transparent),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['title'],
                        style: GoogleFonts.inter(
                          fontSize: 16, 
                          fontWeight: FontWeight.w600,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted ? Colors.grey : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(task['deadline'] ?? 'Today', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                if (task['is_urgent'] == 1 || task['is_urgent'] == true)
                  _badge('Urgent', Colors.red.withOpacity(0.1), Colors.red),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800));
  }

  Widget _badge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: GoogleFonts.inter(color: text, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }

  Widget _emptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Center(child: Text(message, style: GoogleFonts.inter(color: Colors.grey.shade500))),
    );
  }

  Widget _completeProfilePrompt(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text(
            'Complete your profile to see your official university timetable!',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.read<AuthProvider>().logout(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
            child: const Text('Sign up with University'),
          ),
        ],
      ),
    );
  }
}
