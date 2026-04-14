import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/api_constants.dart';
import '../../../models/trip.dart';
import '../../../providers/hisaab_provider.dart';
import '../../../providers/auth_provider.dart';

class SettlementScreen extends ConsumerWidget {
  final Trip trip;
  
  const SettlementScreen({Key? key, required this.trip}) : super(key: key);

  Future<void> _markSettled(BuildContext context, WidgetRef ref, Map<String, dynamic> settlement) async {
    final apiService = ref.read(apiServiceProvider);
    try {
      final response = await apiService.post(
        "\${ApiConstants.hisaab}/\${trip.id}/settle",
        data: {
          'from_user_id': settlement['from_user']['id'],
          'to_user_id': settlement['to_user']['id'],
        }
      );
      if (response.data['success'] == true) {
        ref.refresh(hisaabProvider(trip.id));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as settled!')));
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.data['message'] ?? 'Failed to settle')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e')));
      }
    }
  }

  Future<void> _payViaUpi(BuildContext context, Map<String, dynamic> settlement) async {
    final amount = settlement['amount'];
    // In a real app we'd fetch the recipient's UPI ID. For now just placeholder
    final upiUrl = 'upi://pay?am=\$amount&cu=INR&tn=Ghumakkad%3A\${trip.title}';
    final uri = Uri.parse(upiUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No UPI app found on device')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot open UPI app: \$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hisaabAsync = ref.watch(hisaabProvider(trip.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Settle Up', style: AppTypography.heading.copyWith(fontSize: 20)),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: hisaabAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: \$err')),
        data: (data) {
          final settlements = List<Map<String, dynamic>>.from(data['settlements'] ?? []);
          if (settlements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 80, color: AppColors.success),
                  const SizedBox(height: 16),
                  Text("All Settled Up!", style: AppTypography.display.copyWith(fontSize: 24, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text("No one owes anything.", style: AppTypography.body.copyWith(color: AppColors.textMuted)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: settlements.length,
            itemBuilder: (context, index) {
              final settlement = settlements[index];
              return _buildSettlementCard(context, ref, settlement);
            },
          );
        },
      ),
    );
  }

  Widget _buildSettlementCard(BuildContext context, WidgetRef ref, Map<String, dynamic> settlement) {
    final fromUser = settlement['from_user'];
    final toUser = settlement['to_user'];
    final amount = (settlement['amount'] as num).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Text(fromUser['name'][0].toUpperCase(), style: const TextStyle(color: AppColors.primary)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(fromUser['name'], style: AppTypography.body, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.arrow_forward_rounded, color: AppColors.textMuted, size: 20),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(child: Text(toUser['name'], style: AppTypography.body, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: AppColors.secondary.withOpacity(0.2),
                        child: Text(toUser['name'][0].toUpperCase(), style: const TextStyle(color: AppColors.secondary)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "₹\${amount.toStringAsFixed(2)}",
              style: AppTypography.display.copyWith(fontSize: 28, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _payViaUpi(context, settlement),
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text("Pay via UPI"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.secondary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _markSettled(context, ref, settlement),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text("Mark Settled"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
