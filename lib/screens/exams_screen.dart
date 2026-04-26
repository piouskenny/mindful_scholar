import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/exam_provider.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExamProvider>().fetchExams();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Consumer<ExamProvider>(
          builder: (context, examProvider, _) {
            final exams = examProvider.exams;
            final nextExam = exams.isNotEmpty ? exams.first : null;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exam Countdown',
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${exams.length} exams scheduled this semester',
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        if (nextExam != null)
                          _glassHeroCard(nextExam, isDark)
                        else
                          _emptyState('No exams scheduled', isDark),
                        
                        const SizedBox(height: 40),
                        
                        Text(
                          'Upcoming Schedule',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                
                examProvider.isLoading
                  ? const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final exam = exams[index];
                            return _glassListItem(exam, isDark);
                          },
                          childCount: exams.length,
                        ),
                      ),
                    ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _glassHeroCard(Map<String, dynamic> exam, bool isDark) {
    final days = exam['days_left'] ?? 0;
    final isUrgent = days <= 3;

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: isUrgent 
            ? [Colors.red.shade400, Colors.red.shade700]
            : [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isUrgent ? Colors.red : AppColors.primary).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT EXAM',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${exam['course_code']} — ${exam['course_name']}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$days',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'days left',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            exam['exam_date_formatted'] ?? '',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassListItem(Map<String, dynamic> exam, bool isDark) {
    final days = exam['days_left'] ?? 0;
    final urgency = exam['urgency'] ?? 'low';
    
    Color urgencyColor;
    String urgencyLabel;
    
    if (urgency == 'high' || days <= 3) {
      urgencyColor = Colors.red;
      urgencyLabel = 'Urgent';
    } else if (urgency == 'medium' || days <= 7) {
      urgencyColor = Colors.orange;
      urgencyLabel = 'Soon';
    } else {
      urgencyColor = isDark ? AppColors.accentOrange : AppColors.primary;
      urgencyLabel = 'Upcoming';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withOpacity(0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: urgencyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$days',
                        style: GoogleFonts.inter(
                          fontSize: 22, 
                          fontWeight: FontWeight.w800, 
                          color: urgencyColor
                        ),
                      ),
                      Text(
                        'days',
                        style: GoogleFonts.inter(fontSize: 10, color: urgencyColor.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            exam['course_code'] ?? '',
                            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                          ),
                          const SizedBox(width: 8),
                          _badge(urgencyLabel, urgencyColor.withOpacity(0.1), urgencyColor),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exam['course_name'] ?? '',
                        style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white60 : Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: isDark ? Colors.white38 : Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            exam['exam_date_formatted'] ?? '',
                            style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade500),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.location_on_outlined, size: 14, color: isDark ? Colors.white38 : Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            exam['venue'] ?? 'TBD',
                            style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: GoogleFonts.inter(color: text, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }

  Widget _emptyState(String message, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: Center(
        child: Text(
          message, 
          style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.grey.shade500, fontWeight: FontWeight.w500)
        ),
      ),
    );
  }
}
