import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../models/trip.dart';
import '../../../providers/docs_provider.dart';

class AddHotelScreen extends ConsumerStatefulWidget {
  final Trip trip;
  
  const AddHotelScreen({Key? key, required this.trip}) : super(key: key);

  @override
  ConsumerState<AddHotelScreen> createState() => _AddHotelScreenState();
}

class _AddHotelScreenState extends ConsumerState<AddHotelScreen> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _confController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _checkIn;
  DateTime? _checkOut;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _confController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365*5)),
    );
    if (picked != null) {
      setState(() {
        _checkIn = picked.start;
        _checkOut = picked.end;
      });
    }
  }

  void _saveHotel() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Hotel name')));
      return;
    }

    final data = {
      'trip_id': widget.trip.id,
      'hotel_name': name,
      'city': _cityController.text.trim(),
      'check_in': _checkIn?.toIso8601String(),
      'check_out': _checkOut?.toIso8601String(),
      'confirmation_no': _confController.text.trim(),
      'amount': double.tryParse(_amountController.text.trim()) ?? 0.0,
      'notes': _notesController.text.trim(),
    };

    final success = await ref.read(docsProvider(widget.trip.id).notifier).addHotel(data);
    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add hotel')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Add Hotel', style: AppTypography.heading.copyWith(fontSize: 20)),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Hotel Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: _pickDateRange,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Check-in / Check-out', border: OutlineInputBorder()),
                child: Text(_checkIn != null && _checkOut != null
                    ? "\${DateFormat('MMM dd').format(_checkIn!)} - \${DateFormat('MMM dd, yyyy').format(_checkOut!)}"
                    : 'Select Dates'),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _confController,
              decoration: const InputDecoration(labelText: 'Confirmation Number', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveHotel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Save Hotel', style: AppTypography.button.copyWith(color: AppColors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
