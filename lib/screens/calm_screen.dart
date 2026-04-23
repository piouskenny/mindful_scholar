import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class CalmScreen extends StatelessWidget {
  const CalmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calm Space',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Take a moment for yourself',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 40),
            
            // Breathing Exercise Card
            _calmCard(
              'Breathing Exercise',
              '4-7-8 Technique to reduce anxiety',
              Icons.air,
              AppColors.primary,
            ),
            const SizedBox(height: 20),
            
            // Relaxation Sounds
            _calmCard(
              'Ambient Sounds',
              'Rain, Forest, and White Noise',
              Icons.music_note,
              Colors.blue.shade400,
            ),
            const SizedBox(height: 20),
            
            // Quick Tips
            _calmCard(
              'Quick Stress Tips',
              'Simple ways to stay grounded',
              Icons.lightbulb_outline,
              Colors.orange.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _calmCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade300),
        ],
      ),
    );
  }
}
