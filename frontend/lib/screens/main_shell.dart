import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../providers/auth_provider.dart';
import 'home/home_screen.dart';
import 'home/create_trip_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const _PlaceholderScreen(title: "Explore", icon: Icons.explore),
    const _PlaceholderScreen(title: "Alerts", icon: Icons.notifications),
    const _PlaceholderScreen(title: "Profile", icon: Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (isDesktop) _buildPremiumSidebar(),
          Expanded(
            child: ClipRRect(
              borderRadius: isDesktop 
                ? const BorderRadius.horizontal(left: Radius.circular(32))
                : BorderRadius.zero,
              child: Container(
                color: AppColors.white,
                child: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop 
          ? _buildFloatingBottomNav()
          : null,
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateTripScreen())
        ),
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ) : null,
    );
  }

  Widget _buildFloatingBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          elevation: 0,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: "Explore"),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_none_rounded), label: "Alerts"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: "Profile"),
          ],
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }

  Widget _buildPremiumSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.background,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: AppColors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  "Ghumakkad", 
                  style: AppTypography.heading.copyWith(
                    fontSize: 22, 
                    letterSpacing: -0.5,
                  )
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildSidebarItem(0, Icons.home_rounded, "Home"),
          _buildSidebarItem(1, Icons.explore_outlined, "Explore"),
          _buildSidebarItem(2, Icons.notifications_none_rounded, "Alerts"),
          _buildSidebarItem(3, Icons.person_outline_rounded, "Profile"),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: _buildLogoutButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ] : null,
          ),
          child: Row(
            children: [
              Icon(
                icon, 
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: AppTypography.body.copyWith(
                  color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: () => ref.read(authProvider.notifier).logout(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.error.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 12),
            Text(
              "Sign Out", 
              style: AppTypography.body.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppColors.textMuted.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text("$title Coming Soon", style: AppTypography.heading.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
