import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../models/trip.dart';
import '../trip/trip_dashboard_screen.dart';

import '../home/create_trip_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(context),
          _buildPlaceholderTab("Explore"),
          _buildPlaceholderTab("Alerts"),
          _buildPlaceholderTab("Profile"),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Explore"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Alerts"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateTripScreen()));
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("नमस्ते, Wanderer 👋", style: AppTypography.heading),
                    Text("Where to next?", style: AppTypography.caption),
                  ],
                ),
                InkWell(
                  onTap: () => setState(() => _currentIndex = 3), // Go to profile
                  child: const CircleAvatar(
                    backgroundColor: AppColors.secondary,
                    child: Icon(Icons.person, color: AppColors.white),
                  ),
                ),
              ],
            ),
          ),
          // Trip sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildSectionHeader("Active Trips"),
                const SizedBox(height: 16),
                _buildTripCard(context, "Spiti Valley 2024", "Apr 15 - Apr 22", true),
                const SizedBox(height: 32),
                _buildSectionHeader("Past Wanderings"),
                const SizedBox(height: 16),
                _buildTripCard(context, "Manali Weekend", "Jan 2024", false),
                _buildTripCard(context, "Goa New Year", "Dec 2023", false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            title == "Explore" ? Icons.explore : (title == "Alerts" ? Icons.notifications : Icons.person),
            size: 64,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "$title Screen Coming Soon",
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
          ),
          if (title == "Profile") ...[
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Logout", style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.body.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
    );
  }

  Widget _buildTripCard(BuildContext context, String title, String date, bool isActive) {
    return InkWell(
      onTap: () {
        // For testing, create a dummy trip object
        final dummyTrip = Trip(
          id: 1, 
          uuid: "test-uuid", 
          title: title, 
          creatorId: 1, 
          status: isActive ? "active" : "archived", 
          inviteCode: "XYZ123"
        );
         Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripDashboardScreen(trip: dummyTrip)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isActive ? Icons.landscape : Icons.history,
                color: isActive ? AppColors.primary : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                  Text(date, style: AppTypography.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
