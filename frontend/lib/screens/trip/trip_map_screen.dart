import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/trip.dart';
import '../../models/trip_pin.dart';
import '../../providers/pins_provider.dart';
import '../../providers/route_provider.dart';
import 'add_pin_screen.dart';

class TripMapScreen extends ConsumerStatefulWidget {
  final Trip trip;
  const TripMapScreen({super.key, required this.trip});

  @override
  ConsumerState<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends ConsumerState<TripMapScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final pinsAsync = ref.watch(pinsProvider(widget.trip.id));
    final routeAsync = ref.watch(routeProvider(widget.trip.id));

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(32.2432, 77.1892), // Default Manali area
              initialZoom: 13,
              onLongPress: (tapPosition, point) => _handleMapLongPress(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'in.ghumakkad.app',
              ),
              routeAsync.when(
                data: (points) => PolylineLayer(
                  polylines: [
                    Polyline(
                      points: points,
                      color: AppColors.primary,
                      strokeWidth: 4,
                    ),
                  ],
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              pinsAsync.when(
                data: (pins) => MarkerLayer(
                  markers: pins.map((pin) => _buildMarker(pin)).toList(),
                ),
                loading: () => const MarkerLayer(markers: []),
                error: (_, __) => const MarkerLayer(markers: []),
              ),
            ],
          ),
          _buildTopBar(context),
          _buildFloatingControls(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddPin(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_location_alt, color: AppColors.white),
        label: Text("Drop Pin", style: AppTypography.button),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 40,
      left: 16,
      right: 16,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
                ],
              ),
              child: Text(
                widget.trip.title,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingControls() {
    return Positioned(
      bottom: 100,
      right: 16,
      child: Column(
        children: [
          _buildRoundButton(Icons.my_location, () {}),
          const SizedBox(height: 12),
          _buildRoundButton(Icons.edit_road, () {}),
        ],
      ),
    );
  }

  Widget _buildRoundButton(IconData icon, VoidCallback onTap) {
    return CircleAvatar(
      backgroundColor: AppColors.white,
      radius: 24,
      child: IconButton(
        icon: Icon(icon, color: AppColors.secondary),
        onPressed: onTap,
      ),
    );
  }

  Marker _buildMarker(TripPin pin) {
    return Marker(
      point: LatLng(pin.latitude, pin.longitude),
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () => _showPinSummary(pin),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Icon(_getIconForType(pin.pinType), color: AppColors.white, size: 20),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'hotel': return Icons.hotel;
      case 'food': return Icons.restaurant;
      case 'viewpoint': return Icons.landscape;
      case 'ticket': return Icons.airplane_ticket;
      default: return Icons.camera_alt;
    }
  }

  void _showPinSummary(TripPin pin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getIconForType(pin.pinType), color: AppColors.primary),
                const SizedBox(width: 8),
                Text(pin.title ?? "Untitled Moment", style: AppTypography.heading.copyWith(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 8),
            Text(pin.address ?? "Somewhere on the road", style: AppTypography.caption),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: AppColors.white),
                    child: const Text("View Details"),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleMapLongPress(LatLng point) {
    // Navigate to AddPinScreen with pre-filled coordinates
    _navigateToAddPin(latitude: point.latitude, longitude: point.longitude);
  }

  void _navigateToAddPin({double? latitude, double? longitude}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddPinScreen(
          tripId: widget.trip.id,
          initialLat: latitude,
          initialLng: longitude,
        ),
      ),
    );
  }
}
