import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class InviteFriendsScreen extends StatefulWidget {
  const InviteFriendsScreen({super.key});

  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Invite Friends", style: AppTypography.heading.copyWith(fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Building your gang", style: AppTypography.body),
            const SizedBox(height: 24),
            _buildInviteLinkCard(),
            const SizedBox(height: 40),
            _buildLabel("Search by Phone"),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: "Enter 10-digit phone number",
                prefixIcon: const Icon(Icons.search),
                fillColor: AppColors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.textMuted.withOpacity(0.2)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildLabel("Waitlisted (0)"),
            const SizedBox(height: 16),
            const Center(
              child: Text("No one invited yet", style: TextStyle(color: AppColors.textMuted)),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Done, Open Trip", style: AppTypography.button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(label, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold));
  }

  Widget _buildInviteLinkCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.link, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Trip Invite Code", style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                    Text("X7K9LP02", style: AppTypography.heading.copyWith(fontSize: 18, color: AppColors.primary)),
                  ],
                ),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.copy, size: 20, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {}, // Link to WhatsApp
              icon: const Icon(Icons.whatsapp, color: Colors.white),
              label: const Text("Invite via WhatsApp"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
