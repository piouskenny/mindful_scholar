import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/theme_provider.dart';
import '../core/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _levelController;
  late TextEditingController _cgpaController;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?['name'] ?? '');
    _usernameController = TextEditingController(text: user?['username'] ?? '');
    _levelController = TextEditingController(text: user?['level'] ?? '');
    _cgpaController = TextEditingController(text: (user?['cgpa'] ?? '').toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _levelController.dispose();
    _cgpaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
      
      // Upload immediately
      if (mounted) {
        final success = await context.read<AuthProvider>().uploadProfilePicture(image.path);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated!')),
          );
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    final success = await context.read<AuthProvider>().updateProfile(
      name: _nameController.text,
      username: _usernameController.text,
      level: _levelController.text,
      cgpa: double.tryParse(_cgpaController.text),
    );

    if (success) {
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final user = auth.user;
    final name = user?['name'] ?? 'Scholar';
    final username = user?['username'] ?? 'scholar';
    final email = user?['email'] ?? '';
    final schoolId = user?['school_id'];
    final level = user?['level'] ?? 'Not set';
    final cgpa = user?['cgpa'] ?? '0.00';
    final profilePicture = user?['profile_picture'];
    
    final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
    final profileUrl = profilePicture != null ? '$baseUrl/storage/$profilePicture' : null;

    String schoolName = 'Not selected';
    if (schoolId != null) {
      final school = auth.schools.firstWhere(
        (s) => s['id'] == schoolId,
        orElse: () => null,
      );
      if (school != null) {
        schoolName = school['name'];
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit_outlined, color: AppColors.primary),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: auth.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              Positioned(
                top: 50,
                left: -50,
                child: _blob(200, AppColors.primary.withOpacity(isDark ? 0.1 : 0.04)),
              ),
              Positioned(
                bottom: 100,
                right: -80,
                child: _blob(300, AppColors.accent.withOpacity(isDark ? 0.1 : 0.04)),
              ),
              
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.1),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                                    backgroundImage: _imageFile != null 
                                      ? FileImage(_imageFile!) as ImageProvider
                                      : (profileUrl != null ? NetworkImage(profileUrl) : null),
                                    child: (_imageFile == null && profileUrl == null)
                                      ? Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                          style: GoogleFonts.inter(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (!_isEditing) ...[
                            Text(
                              name,
                              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                            ),
                            Text(
                              '@$username',
                              style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                            ),
                          ] else ...[
                            Text('Edit Profile Details', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),

                    // Theme Toggle
                    _glassContainer(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: AppColors.primary),
                              const SizedBox(width: 16),
                              Text(
                                'Dark Mode',
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black),
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            value: themeProvider.isDarkMode,
                            activeColor: AppColors.primary,
                            onChanged: (val) => themeProvider.toggleTheme(val),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    if (_isEditing) ...[
                      _editField('Full Name', _nameController, Icons.person_outline, isDark),
                      _editField('Username', _usernameController, Icons.alternate_email, isDark),
                      _editField('Academic Level', _levelController, Icons.leaderboard_outlined, isDark),
                      _editField('Current CGPA', _cgpaController, Icons.analytics_outlined, isDark, keyboardType: TextInputType.number),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text('Save Changes'),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _isEditing = false),
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      ),
                    ] else ...[
                      _glassProfileItem('Email', email, Icons.email_outlined, isDark),
                      _glassProfileItem('University', schoolName, Icons.school_outlined, isDark),
                      _glassProfileItem('Academic Level', level, Icons.leaderboard_outlined, isDark),
                      _glassProfileItem('Current CGPA', cgpa.toString(), Icons.analytics_outlined, isDark),
                    ],
                    
                    const SizedBox(height: 40),
                    
                    if (!_isEditing)
                      ElevatedButton(
                        onPressed: () {
                          auth.logout();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.red.withOpacity(0.1) : Colors.red.shade50,
                          foregroundColor: Colors.red,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _glassContainer({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _editField(String label, TextEditingController controller, IconData icon, bool isDark, {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: (isDark ? Colors.black : Colors.white).withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _glassProfileItem(String label, String value, IconData icon, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(color: isDark ? Colors.white60 : Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
}
