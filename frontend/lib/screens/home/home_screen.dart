import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/trip.dart';
import '../trip/trip_dashboard_screen.dart';
import '../../providers/trips_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;
    final tripsAsync = ref.watch(tripsProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 40 : 24,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(ref),
                const SizedBox(height: 32),
                Expanded(
                  child: tripsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => const Center(child: Text('Could not load trips')),
                    data: (trips) {
                      final active = trips.where((t) => t.status == 'active').toList();
                      final past = trips.where((t) => t.status != 'active').toList();
                      
                      return ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          if (active.isNotEmpty) ...[
                            _buildSectionHeader("Active Trips"),
                            const SizedBox(height: 16),
                            ...active.map((t) => _buildTripCard(context, t)),
                            const SizedBox(height: 40),
                          ],
                          if (past.isNotEmpty) ...[
                            _buildSectionHeader("Past Wanderings"),
                            const SizedBox(height: 16),
                            ...past.map((t) => _buildTripCard(context, t)),
                          ],
                          if (trips.isEmpty) const Center(child: Text("No trips yet. Create one!")),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        String name = 'Wanderer';
        if (snapshot.hasData) {
          final userDataStr = snapshot.data!.getString('user_data');
          if (userDataStr != null) {
            try {
              final userData = json.decode(userDataStr);
              name = userData['name'] ?? 'Wanderer';
            } catch (_) {}
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("नमस्ते, \$name 👋", style: AppTypography.display.copyWith(fontSize: 36)),
            const SizedBox(height: 4),
            Text("Your travel memories, perfectly curated.", 
              style: AppTypography.body.copyWith(color: AppColors.textMuted)),
          ],
        );
      }
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(title, style: AppTypography.heading.copyWith(fontSize: 20)),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: AppColors.textMuted.withOpacity(0.1))),
      ],
    );
  }

  Widget _buildTripCard(BuildContext context, Trip trip) {
    final bool isActive = trip.status == 'active';
    // Format date string beautifully (mock format for now)
    final String dateStr = trip.startDate != null 
        ? "\${trip.startDate!.year}-\${trip.startDate!.month}-\${trip.startDate!.day}" 
        : "Dates pending";

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => TripDashboardScreen(trip: trip)
          ));
        },
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildTripIcon(isActive),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.title, style: AppTypography.heading.copyWith(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(dateStr, style: AppTypography.caption),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripIcon(bool isActive) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive 
            ? [AppColors.primary.withOpacity(0.8), AppColors.primary]
            : [Colors.grey.withOpacity(0.5), Colors.grey],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        isActive ? Icons.explore : Icons.history,
        color: AppColors.white,
        size: 32,
      ),
    );
  }
}
