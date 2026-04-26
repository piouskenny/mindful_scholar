import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class CalmScreen extends StatefulWidget {
  const CalmScreen({super.key});

  @override
  State<CalmScreen> createState() => _CalmScreenState();
}

class _CalmScreenState extends State<CalmScreen> {
  bool _isBreathing = false;
  String _breathStatus = 'Tap to begin';
  int _counter = 4;
  Timer? _timer;
  int _phase = 0; // 0: Inhale, 1: Hold, 2: Exhale, 3: Hold

  final List<String> _phases = ['Inhale', 'Hold', 'Exhale', 'Hold'];

  void _startBreathing() {
    setState(() {
      _isBreathing = true;
      _counter = 4;
      _phase = 0;
      _breathStatus = _phases[_phase];
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_counter > 1) {
          _counter--;
        } else {
          _counter = 4;
          _phase = (_phase + 1) % 4;
          _breathStatus = _phases[_phase];
        }
      });
    });
  }

  void _stopBreathing() {
    _timer?.cancel();
    setState(() {
      _isBreathing = false;
      _breathStatus = 'Tap to begin';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calm Space',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Take a moment for yourself',
                style: GoogleFonts.inter(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 16),
              ),
              const SizedBox(height: 32),

              // Box Breathing Card
              GestureDetector(
                onTap: _isBreathing ? _stopBreathing : _startBreathing,
                child: Container(
                  width: double.infinity,
                  height: 240,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'BOX BREATHING',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(seconds: 4),
                            width: _isBreathing && (_phase == 0 || _phase == 1) ? 140 : 110,
                            height: _isBreathing && (_phase == 0 || _phase == 1) ? 140 : 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24, width: 2),
                            ),
                          ),
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _breathStatus,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_isBreathing)
                                    Text(
                                      '$_counter',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Wellness Tips Section
              Text(
                'Wellness Tips',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              _tipTile('Pomodoro Technique', Colors.orange.withOpacity(0.1), Colors.orange, isDark),
              _tipTile('Progressive Relaxation', Colors.deepOrange.withOpacity(0.1), Colors.deepOrange, isDark),
              _tipTile('Active Recall', Colors.blue.withOpacity(0.1), Colors.blue, isDark),

              const SizedBox(height: 32),

              // Daily Affirmation Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : AppColors.surface).withOpacity(isDark ? 0.05 : 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border(
                    left: BorderSide(color: AppColors.accent, width: 4),
                    top: isDark ? BorderSide(color: Colors.white.withOpacity(0.05)) : BorderSide.none,
                    right: isDark ? BorderSide(color: Colors.white.withOpacity(0.05)) : BorderSide.none,
                    bottom: isDark ? BorderSide(color: Colors.white.withOpacity(0.05)) : BorderSide.none,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"The secret of getting ahead is getting started."',
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white70 : AppColors.primary.withOpacity(0.8),
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '— Daily affirmation',
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white38 : Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100), // Space for bottom navbar
            ],
          ),
        ),
      ),
    );
  }

  Widget _tipTile(String title, Color bgColor, Color iconColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.white).withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.play_arrow_outlined, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.grey, size: 20),
        ],
      ),
    );
  }
}
