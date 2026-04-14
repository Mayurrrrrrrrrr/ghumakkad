import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/api_constants.dart';
import '../../../models/trip.dart';
import '../../../providers/members_provider.dart';
import '../../../providers/auth_provider.dart';

class MembersScreen extends ConsumerWidget {
  final Trip trip;
  
  const MembersScreen({Key? key, required this.trip}) : super(key: key);

  void _removeMember(BuildContext context, WidgetRef ref, int userId) async {
    final apiService = ref.read(apiServiceProvider);
    try {
      final res = await apiService.delete(ApiConstants.members, data: {
        'trip_id': trip.id,
        'user_id': userId,
      });
      if (res.data['success'] == true) {
        ref.refresh(membersProvider(trip.id));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member removed')));
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.data['message'] ?? 'Failed to remove')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e')));
      }
    }
  }

  void _transferOwnership(BuildContext context, WidgetRef ref, int newCreatorId) async {
    final apiService = ref.read(apiServiceProvider);
    try {
      final res = await apiService.put("\${ApiConstants.trips}/\${trip.id}/transfer", data: {
        'new_creator_user_id': newCreatorId,
      });
      if (res.data['success'] == true) {
        ref.refresh(membersProvider(trip.id));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ownership transferred')));
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.data['message'] ?? 'Failed to transfer')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e')));
      }
    }
  }

  void _showInviteSheet(BuildContext context) {
    final inviteLink = 'https://ghumakkad.yuktaa.com/join/\${trip.inviteCode}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Invite Friends', style: AppTypography.heading.copyWith(fontSize: 24)),
              const SizedBox(height: 8),
              Text('Share this code with your travel buddies', style: AppTypography.body.copyWith(color: AppColors.textMuted), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              // QR Code
              QrImageView(
                data: inviteLink,
                version: QrVersions.auto,
                size: 200.0,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(trip.inviteCode, style: AppTypography.display.copyWith(fontSize: 24, letterSpacing: 4)),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.copy, color: AppColors.primary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: trip.inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied!')));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Share.share('Join my trip "\${trip.title}" on Ghumakkad! Code: \${trip.inviteCode}\n\$inviteLink');
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share Link'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showMemberOptions(BuildContext context, WidgetRef ref, Map<String, dynamic> member, bool isCurrentUserCreator) {
    if (!isCurrentUserCreator) return;
    
    final userId = (member['id'] ?? member['user_id']) as int;
    final role = member['role'];
    if (role == 'creator') return; // Can't remove yourself here
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: AppColors.primary),
                title: const Text('Make Creator'),
                onTap: () {
                  Navigator.pop(context);
                  _transferOwnership(context, ref, userId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_remove, color: AppColors.error),
                title: const Text('Remove from Trip', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _removeMember(context, ref, userId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersProvider(trip.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Travellers', style: AppTypography.heading.copyWith(fontSize: 20)),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: \$err')),
        data: (members) {
          // Dummy check for current user creator status.
          // Ideally fetch current user from auth provider.
          bool isCurrentUserCreator = trip.creatorId > 0; // True by default for mock.
          
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: members.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final role = member['role'];
                    final isCreator = role == 'creator';
                    
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onLongPress: () => _showMemberOptions(context, ref, member, isCurrentUserCreator),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: isCreator ? AppColors.primary.withOpacity(0.2) : AppColors.secondary.withOpacity(0.2),
                                child: Text(member['name'][0].toUpperCase(), 
                                    style: TextStyle(color: isCreator ? AppColors.primary : AppColors.secondary, fontSize: 20, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(member['name'], style: AppTypography.heading.copyWith(fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text(member['phone'] ?? 'No phone', style: AppTypography.caption),
                                  ],
                                ),
                              ),
                              if (isCreator)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('👑', style: TextStyle(fontSize: 12)),
                                      const SizedBox(width: 4),
                                      Text('Creator', style: AppTypography.body.copyWith(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text('Member', style: AppTypography.body.copyWith(color: AppColors.secondary, fontSize: 12)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showInviteSheet(context),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Invite More Friends'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
