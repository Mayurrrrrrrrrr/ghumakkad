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
  bool _isDrawingRoute = false;
  List<LatLng> _currentRoutePoints = [];

  @override
  Widget build(BuildContext context) {
    final pinsAsync = ref.watch(pinsProvider(widget.trip.id));
    final routeAsync = ref.watch(routeProvider(widget.trip.id));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildMap(pinsAsync, routeAsync),
          _buildFloatingTopBar(context),
          _buildRightControls(),
          if (_isDrawingRoute) _buildDrawingToolbar(),
          _buildBottomSummary(pinsAsync),
        ],
      ),
      floatingActionButton: !_isDrawingRoute ? FloatingActionButton.extended(
        onPressed: () => _navigateToAddPin(),
        elevation: 6,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_location_alt_rounded, color: AppColors.white),
        label: Text("Drop Memory", style: AppTypography.button),
      ) : null,
    );
  }

  Widget _buildMap(AsyncValue<List<TripPin>> pinsAsync, AsyncValue<List<LatLng>> routeAsync) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(32.2432, 77.1892),
        initialZoom: 13,
        onTap: (tapPosition, point) => _handleMapTap(point),
        onLongPress: (tapPosition, point) => _handleMapLongPress(point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'in.ghumakkad.app',
        ),
        // Existing saved route
        routeAsync.when(
          data: (List<LatLng> points) => PolylineLayer(
            polylines: <Polyline>[
              Polyline(
                points: points,
                color: AppColors.secondary.withOpacity(0.6),
                strokeWidth: 5,
                pattern: const StrokePattern.dotted(),
              ),
            ],
          ),
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        ),
        // Current drawing route
        if (_currentRoutePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _currentRoutePoints,
                color: AppColors.primary,
                strokeWidth: 4,
              ),
            ],
          ),
        pinsAsync.when(
          data: (List<TripPin> pins) => MarkerLayer(
            markers: pins.map((pin) => _buildMarker(pin)).toList(),
          ),
          loading: () => const MarkerLayer(markers: <Marker>[]),
          error: (_, __) => const MarkerLayer(markers: <Marker>[]),
        ),
      ],
    );
  }

  Widget _buildFloatingTopBar(BuildContext context) {
    return Positioned(
      top: 40,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Row(
          children: [
            _buildGlassButton(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.trip.title,
                        style: AppTypography.heading.copyWith(fontSize: 16, letterSpacing: -0.2),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildGlassButton(Icons.share_rounded, () => _shareTrip()),
          ],
        ),
      ),
    );
  }

  Widget _buildRightControls() {
    return Positioned(
      top: 150,
      right: 16,
      child: Column(
        children: [
          _buildGlassButton(
            _isDrawingRoute ? Icons.close_rounded : Icons.edit_road_rounded, 
            () => setState(() => _isDrawingRoute = !_isDrawingRoute),
            color: _isDrawingRoute ? AppColors.error : AppColors.primary,
          ),
          const SizedBox(height: 12),
          _buildGlassButton(Icons.layers_outlined, () {}),
          const SizedBox(height: 12),
          _buildGlassButton(Icons.my_location_rounded, () {}),
        ],
      ),
    );
  }

  Widget _buildGlassButton(IconData icon, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: color ?? AppColors.textPrimary, size: 22),
      ),
    );
  }

  Widget _buildDrawingToolbar() {
    return Positioned(
      bottom: 40,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 30, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.gesture_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Route Designer", style: AppTypography.heading.copyWith(fontSize: 15)),
                  Text("${_currentRoutePoints.length} points added", style: AppTypography.caption),
                ],
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _currentRoutePoints = []),
              child: Text("Clear", style: TextStyle(color: AppColors.textMuted)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _currentRoutePoints.length < 2 ? null : () => _saveCurrentRoute(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Done"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSummary(AsyncValue<List<TripPin>> pinsAsync) {
    if (_isDrawingRoute) return const SizedBox();
    
    return Positioned(
      bottom: 40,
      left: 16,
      child: pinsAsync.when(
        data: (pins) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
          ),
          child: Row(
            children: [
              const Icon(Icons.push_pin_rounded, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                "${pins.length} Memories", 
                style: AppTypography.body.copyWith(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.bold)
              ),
            ],
          ),
        ),
        loading: () => const SizedBox(),
        error: (_, __) => const SizedBox(),
      ),
    );
  }

  Marker _buildMarker(TripPin pin) {
    return Marker(
      point: LatLng(pin.latitude, pin.longitude),
      width: 50,
      height: 50,
      child: GestureDetector(
        onTap: () => _showPinDetails(pin),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 3),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10)],
              ),
              child: Center(child: Icon(_getIconForType(pin.pinType), color: AppColors.white, size: 20)),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'hotel': return Icons.hotel_rounded;
      case 'food': return Icons.restaurant_rounded;
      case 'viewpoint': return Icons.landscape_rounded;
      case 'ticket': return Icons.airplane_ticket_rounded;
      default: return Icons.auto_awesome_rounded;
    }
  }

  void _showPinDetails(TripPin pin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 50)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(_getIconForType(pin.pinType), color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pin.title ?? "Spontaneous Moment", style: AppTypography.heading.copyWith(fontSize: 22, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text(pin.address ?? "Pinned location", style: AppTypography.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (pin.photoUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  pin.photoUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: AppColors.background,
                    child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notes_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text("NOTES", style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pin.notes ?? "No notes added for this moment yet. Share your experience here!",
                    style: AppTypography.body.copyWith(fontSize: 14, color: AppColors.textPrimary, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text("Edit Memory"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMapTap(LatLng point) {
    if (_isDrawingRoute) {
      setState(() => _currentRoutePoints.add(point));
    }
  }

  void _handleMapLongPress(LatLng point) {
    if (!_isDrawingRoute) {
      _navigateToAddPin(latitude: point.latitude, longitude: point.longitude);
    }
  }

  void _saveCurrentRoute() async {
    final success = await ref.read(routeProvider(widget.trip.id).notifier).saveRoute(_currentRoutePoints);
    if (success) {
      setState(() {
        _isDrawingRoute = false;
        _currentRoutePoints = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Trail blazed! Route saved successfully."), backgroundColor: AppColors.success),
      );
    }
  }

  void _shareTrip() {
    final text = "Check out my trip: ${widget.trip.title} on Ghumakkad! https://ghumakkad.yuktaa.com/trip/${widget.trip.id}";
    // Simple WhatsApp share launcher
    // In a real app, use url_launcher or share_plus
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Trip summary copied for sharing!"), action: SnackBarAction(label: "Open WhatsApp", onPressed: () {})),
    );
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
