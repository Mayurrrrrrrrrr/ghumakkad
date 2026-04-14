import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/trip.dart';
import 'trip_map_screen.dart';
import 'hisaab_screen.dart';
import 'timeline_screen.dart';
import 'docs_screen.dart';
import 'members_screen.dart';

class TripDashboardScreen extends ConsumerWidget {
  final Trip trip;
  const TripDashboardScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickStats(),
                  const SizedBox(height: 32),
                  _buildTabGrid(context),
                  const SizedBox(height: 40),
                  _buildMembersSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: AppColors.secondary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(trip.title, style: AppTypography.heading.copyWith(color: AppColors.white, fontSize: 18)),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (trip.coverImageUrl != null)
              Image.network(trip.coverImageUrl!, fit: BoxFit.cover)
            else
              Container(color: AppColors.secondary),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem("0 Pins", Icons.location_on_outlined),
        _buildStatItem("0 Photos", Icons.photo_library_outlined),
        _buildStatItem("₹0 spent", Icons.currency_rupee),
      ],
    );
  }

  Widget _buildStatItem(String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(label, style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTabGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildTabTile(context, "Map", "🗺️", AppColors.accent, () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripMapScreen(trip: trip)));
        }),
        _buildTabTile(context, "Memories", "📸", Colors.blue.withOpacity(0.1), () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => TimelineScreen(trip: trip)));
        }),
        _buildTabTile(context, "Hisaab", "💸", Colors.green.withOpacity(0.1), () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => HisaabScreen(trip: trip)));
        }),
        _buildTabTile(context, "Docs", "📋", Colors.orange.withOpacity(0.1), () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => DocsScreen(trip: trip)));
        }),
      ],
    );
  }

  Widget _buildTabTile(BuildContext context, String title, String emoji, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Wanderers", style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => MembersScreen(trip: trip)));
              }, 
              child: const Text('View All')
            )
          ]
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const CircleAvatar(radius: 18, backgroundColor: AppColors.primary, child: Icon(Icons.person, size: 18, color: AppColors.white)),
            const SizedBox(width: -8),
            const CircleAvatar(radius: 18, backgroundColor: AppColors.secondary, child: Icon(Icons.person, size: 18, color: AppColors.white)),
            const SizedBox(width: 8),
            Text("Trip Members", style: AppTypography.caption),
          ],
        ),
      ],
    );
  }
}
