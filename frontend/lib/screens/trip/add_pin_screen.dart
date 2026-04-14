import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/location_service.dart';
import '../../providers/pins_provider.dart';

class AddPinScreen extends ConsumerStatefulWidget {
  final int tripId;
  final double? initialLat;
  final double? initialLng;

  const AddPinScreen({
    super.key,
    required this.tripId,
    this.initialLat,
    this.initialLng,
  });

  @override
  ConsumerState<AddPinScreen> createState() => _AddPinScreenState();
}

class _AddPinScreenState extends ConsumerState<AddPinScreen> {
  final _titleController = TextEditingController();
  String _selectedType = 'memory';
  String _address = "Fetching address...";
  double? _lat;
  double? _lng;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _pinTypes = [
    {'type': 'memory', 'icon': Icons.camera_alt, 'label': 'Memory'},
    {'type': 'hotel', 'icon': Icons.hotel, 'label': 'Hotel'},
    {'type': 'food', 'icon': Icons.restaurant, 'label': 'Food'},
    {'type': 'viewpoint', 'icon': Icons.landscape, 'label': 'View'},
    {'type': 'ticket', 'icon': Icons.airplane_ticket, 'label': 'Travel'},
  ];

  @override
  void initState() {
    super.initState();
    _lat = widget.initialLat;
    _lng = widget.initialLng;
    _initLocation();
  }

  Future<void> _initLocation() async {
    final locationService = LocationService();
    if (_lat == null || _lng == null) {
      final pos = await locationService.getCurrentLocation();
      if (pos != null) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
        });
      }
    }
    
    if (_lat != null && _lng != null) {
      final addr = await locationService.getAddressFromLatLng(_lat!, _lng!);
      setState(() {
        _address = addr ?? "Unknown Location";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Drop a New Pin", style: AppTypography.heading.copyWith(fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMapPreview(),
            const SizedBox(height: 32),
            _buildLabel("Pin Type"),
            const SizedBox(height: 12),
            _buildTypeSelector(),
            const SizedBox(height: 32),
            _buildLabel("Title"),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: "e.g., Best Maggi here!",
                fillColor: AppColors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            _buildLabel("Travel Notes"),
            const SizedBox(height: 8),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "What makes this moment special?",
                fillColor: AppColors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            _buildLabel("Photos"),
            const SizedBox(height: 12),
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.2), style: BorderStyle.none),
              ),
              child: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: AppColors.white)
                  : Text("Save Moment", style: AppTypography.button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPreview() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textMuted.withOpacity(0.2)),
      ),
      child: Center(
        child: Icon(Icons.location_on, size: 40, color: AppColors.primary),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(label, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold));
  }

  Widget _buildTypeSelector() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _pinTypes.length,
        itemBuilder: (context, index) {
          final item = _pinTypes[index];
          final isSelected = _selectedType == item['type'];
          return GestureDetector(
            onTap: () => setState(() => _selectedType = item['type']),
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.textMuted.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'], color: isSelected ? AppColors.white : AppColors.textMuted),
                  const SizedBox(height: 4),
                  Text(item['label'], style: AppTypography.caption.copyWith(color: isSelected ? AppColors.white : AppColors.textMuted, fontSize: 10)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _savePin() async {
    if (_lat == null || _lng == null) return;
    
    setState(() => _isLoading = true);
    final success = await ref.read(pinsProvider(widget.tripId).notifier).addPin({
      'pin_type': _selectedType,
      'title': _titleController.text.trim(),
      'latitude': _lat,
      'longitude': _lng,
      'address': _address,
    });
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
    }
  }
}
