import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/api_constants.dart';
import '../../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _user;
  int _tripCount = 0; // Ideally fetch from tripsProvider or API

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user_data');
    if (userStr != null) {
      setState(() {
        _user = json.decode(userStr);
      });
    }
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _user?['name']);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter new name'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      }
    );

    if (newName != null && newName.isNotEmpty && newName != _user?['name']) {
         // Update via API
         final apiService = ref.read(apiServiceProvider);
         try {
           final res = await apiService.put(ApiConstants.updateProfile, data: {'name': newName});
           if (res.data['success'] == true) {
             final updatedUser = res.data['data'];
             final prefs = await SharedPreferences.getInstance();
             await prefs.setString('user_data', json.encode(updatedUser));
             setState(() {
               _user = updatedUser;
             });
           }
         } catch(e) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating name: \$e')));
         }
    }
  }

  void _logout() {
    ref.read(authProvider.notifier).logout();
    // In real app, it will transition to onboarding/login automatically since authState changes.
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final name = _user!['name'] ?? 'Wanderer';
    final phone = _user!['phone'] ?? '+91 XXX XXX XXXX';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Profile', style: AppTypography.heading.copyWith(fontSize: 20)),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.primary,
                child: Text(
                  name[0].toUpperCase(), 
                  style: AppTypography.display.copyWith(color: AppColors.white, fontSize: 48)
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name, style: AppTypography.display.copyWith(fontSize: 28)),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.textMuted, size: 20),
                  onPressed: _editName,
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(phone, style: AppTypography.body.copyWith(color: AppColors.textMuted, fontSize: 16)),
            
            const SizedBox(height: 48),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('0', style: AppTypography.display.copyWith(fontSize: 32, color: AppColors.secondary)),
                      const Text('Memories', style: TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                  Container(width: 1, height: 40, color: AppColors.textMuted.withOpacity(0.2)),
                  Column(
                    children: [
                      Text(_tripCount.toString(), style: AppTypography.display.copyWith(fontSize: 32, color: AppColors.primary)),
                      const Text('Trips', style: TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
