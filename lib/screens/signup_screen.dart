import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  int? _selectedSchoolId;
  String? _selectedLevel;
  bool _obscurePassword = true;

  final List<String> _levels = ['100L', '200L', '300L', '400L', '500L', '600L', 'Masters', 'PhD'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
              // Header
              Text(
                'Create account',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Start your mindful academic journey.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              
              // Name Field
              _label('FULL NAME'),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Chidi Okeke'),
              ),
              const SizedBox(height: 24),

              // Username Field
              _label('USERNAME'),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(hintText: 'chidi_scholar'),
              ),
              const SizedBox(height: 24),

              // Email Field
              _label('EMAIL'),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(hintText: 'you@university.edu'),
              ),
              const SizedBox(height: 24),

              // School Selection
              _label('SELECT UNIVERSITY'),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return DropdownButtonFormField<int>(
                    value: _selectedSchoolId,
                    items: auth.schools.map((school) {
                      return DropdownMenuItem<int>(
                        value: school['id'],
                        child: Text(school['name']),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedSchoolId = val),
                    decoration: const InputDecoration(hintText: 'Choose your school'),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Level Selection
              _label('CURRENT LEVEL'),
              DropdownButtonFormField<String>(
                value: _selectedLevel,
                items: _levels.map((level) {
                  return DropdownMenuItem<String>(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedLevel = val),
                decoration: const InputDecoration(hintText: 'Choose your level'),
              ),
              const SizedBox(height: 24),

              // Password Field
              _label('PASSWORD'),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Confirm Password Field
              _label('CONFIRM PASSWORD'),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscurePassword,
                decoration: const InputDecoration(hintText: '••••••••'),
              ),
              const SizedBox(height: 32),

              // Sign Up Button
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return ElevatedButton(
                    onPressed: auth.isLoading 
                      ? null 
                      : () async {
                          if (_passwordController.text != _confirmPasswordController.text) {
                            _showError('Passwords do not match');
                            return;
                          }
                          
                          final success = await auth.register(
                            _nameController.text,
                            _usernameController.text,
                            _emailController.text, 
                            _passwordController.text,
                            _confirmPasswordController.text,
                            schoolId: _selectedSchoolId,
                            level: _selectedLevel,
                          );
                          
                          if (success && mounted) {
                            Navigator.pop(context);
                          } else if (mounted) {
                            _showError('Registration failed. Please try again.');
                          }
                        },
                    child: auth.isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('Create Account'),
                  );
                },
              ),
              const SizedBox(height: 40),
              
              // Login link
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: const TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: AppColors.textSecondary),
                      children: [
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.black54,
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
