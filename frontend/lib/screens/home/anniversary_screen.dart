import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../models/trip.dart';
import '../trip/timeline_screen.dart';

class AnniversaryScreen extends StatelessWidget {
  final Trip trip;
  final int years;

  const AnniversaryScreen({Key? key, required this.trip, required this.years}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          if (trip.coverImageUrl != null)
            CachedNetworkImage(
              imageUrl: trip.coverImageUrl!,
              fit: BoxFit.cover,
            )
          else
            Container(color: AppColors.primary),
            
          // Blur and Dark Overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Text(
                    "\$years Year\${years > 1 ? 's' : ''} Ago 🎉",
                    style: AppTypography.display.copyWith(color: AppColors.white, fontSize: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    trip.title,
                    style: AppTypography.display.copyWith(color: AppColors.primary, fontSize: 48, letterSpacing: 1.2),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat("Memories", "♾️"),
                      _buildStat("Moments", "✨"),
                      _buildStat("Vibes", "🔥"),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TimelineScreen(trip: trip)));
                      },
                      icon: const Icon(Icons.history),
                      label: Text("Relive the Memories", style: AppTypography.button),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      Share.share("Reliving our amazing trip to \${trip.title} exactly \$years year\${years > 1 ? 's' : ''} ago! Created using Ghumakkad. 🚗✨");
                    },
                    icon: const Icon(Icons.share, color: AppColors.white),
                    label: Text("Share", style: AppTypography.button.copyWith(color: AppColors.white)),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Close", style: AppTypography.body.copyWith(color: AppColors.textMuted)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.white)),
      ],
    );
  }
}
