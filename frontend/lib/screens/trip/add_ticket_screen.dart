import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../models/trip.dart';
import '../../../providers/docs_provider.dart';

class AddTicketScreen extends ConsumerStatefulWidget {
  final Trip trip;
  
  const AddTicketScreen({Key? key, required this.trip}) : super(key: key);

  @override
  ConsumerState<AddTicketScreen> createState() => _AddTicketScreenState();
}

class _AddTicketScreenState extends ConsumerState<AddTicketScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _pnrController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _ticketType = 'Flight';
  DateTime? _travelDate;
  TimeOfDay? _travelTime;
  
  final List<String> _types = ['Flight', 'Train', 'Bus', 'Other'];

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _pnrController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _travelDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365*5)),
    );
    if (picked != null) {
      setState(() => _travelDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _travelTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _travelTime = picked);
    }
  }

  void _saveTicket() async {
    final fromPlace = _fromController.text.trim();
    final toPlace = _toController.text.trim();
    if (fromPlace.isEmpty || toPlace.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter From and To locations')));
      return;
    }

    final data = {
      'trip_id': widget.trip.id,
      'ticket_type': _ticketType,
      'from_place': fromPlace,
      'to_place': toPlace,
      'travel_date': _travelDate?.toIso8601String(),
      'travel_time': _travelTime != null ? "\${_travelTime!.hour.toString().padLeft(2,'0')}:\${_travelTime!.minute.toString().padLeft(2,'0')}" : null,
      'pnr_number': _pnrController.text.trim(),
      'amount': double.tryParse(_amountController.text.trim()) ?? 0.0,
      'notes': _notesController.text.trim(),
    };

    final success = await ref.read(docsProvider(widget.trip.id).notifier).addTicket(data);
    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add ticket')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Add Ticket', style: AppTypography.heading.copyWith(fontSize: 20)),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _types.map((type) {
                  final isSelected = _ticketType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _ticketType = type);
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: isSelected ? AppColors.white : AppColors.textPrimary),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fromController,
                    decoration: const InputDecoration(labelText: 'From', border: OutlineInputBorder()),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Icon(Icons.arrow_forward),
                ),
                Expanded(
                  child: TextField(
                    controller: _toController,
                    decoration: const InputDecoration(labelText: 'To', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Travel Date', border: OutlineInputBorder()),
                      child: Text(_travelDate != null ? DateFormat('MMM dd, yyyy').format(_travelDate!) : 'Select Date'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Time', border: OutlineInputBorder()),
                      child: Text(_travelTime?.format(context) ?? 'Select Time'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _pnrController,
              decoration: const InputDecoration(labelText: 'PNR / Booking Ref', border: OutlineInputBorder()),
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
                onPressed: _saveTicket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Save Ticket', style: AppTypography.button.copyWith(color: AppColors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
