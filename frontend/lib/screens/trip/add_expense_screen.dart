import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../models/trip.dart';
import '../../../providers/expenses_provider.dart';
import '../../../providers/members_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final Trip trip;
  
  const AddExpenseScreen({Key? key, required this.trip}) : super(key: key);

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  
  String _category = 'Other';
  DateTime _expenseDate = DateTime.now();
  int? _paidByUserId;
  String _splitType = 'equal';
  
  // Maps userId to amount for custom splits
  Map<int, double> _customSplits = {};
  int? _individualUserId;

  final List<String> _categories = ['Transport', 'Food', 'Hotel', 'Ticket', 'Activity', 'Other'];

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Transport': return Icons.directions_car;
      case 'Food': return Icons.restaurant;
      case 'Hotel': return Icons.hotel;
      case 'Ticket': return Icons.flight;
      case 'Activity': return Icons.local_activity;
      default: return Icons.receipt;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _expenseDate = picked);
    }
  }

  void _saveExpense() async {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();
    if (title.isEmpty || amountText.isEmpty || _paidByUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }
    
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount')));
      return;
    }

    if (_splitType == 'individual' && _individualUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select an individual')));
      return;
    }

    if (_splitType == 'custom') {
      double totalCustom = _customSplits.values.fold(0, (a, b) => a + b);
      if ((totalCustom - amount).abs() > 0.02) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Custom splits sum (\${totalCustom.toStringAsFixed(2)}) does not match amount (\${amount.toStringAsFixed(2)})')));
        return;
      }
    }

    final data = {
      'trip_id': widget.trip.id,
      'title': title,
      'amount': amount,
      'paid_by': _paidByUserId,
      'split_type': _splitType,
      'expense_date': _expenseDate.toIso8601String(),
      'category': _category,
    };

    if (_splitType == 'individual') {
      data['individual_user_id'] = _individualUserId!;
    } else if (_splitType == 'custom') {
      data['custom_splits'] = _customSplits.entries.map((e) => {
        'user_id': e.key,
        'amount': e.value
      }).toList();
    }

    final success = await ref.read(expensesProvider(widget.trip.id).notifier).addExpense(data);
    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add expense')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersProvider(widget.trip.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Add Expense', style: AppTypography.heading.copyWith(fontSize: 20)),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading members: \$err')),
        data: (members) {
          if (_paidByUserId == null && members.isNotEmpty) {
            _paidByUserId = members.first['id'] ?? members.first['user_id'];
          }
          if (_splitType == 'individual' && _individualUserId == null && members.isNotEmpty) {
            _individualUserId = members.first['id'] ?? members.first['user_id'];
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: AppTypography.display.copyWith(fontSize: 48, color: AppColors.primary),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '0.00',
                        hintStyle: AppTypography.display.copyWith(fontSize: 48, color: AppColors.textMuted.withOpacity(0.3)),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(top: 8.0, left: 16),
                          child: Text('₹', style: AppTypography.display.copyWith(fontSize: 32, color: AppColors.textPrimary)),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'What was this for?',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Paid By',
                          border: OutlineInputBorder(),
                        ),
                        value: _paidByUserId,
                        items: members.map((m) {
                          return DropdownMenuItem<int>(
                            value: (m['id'] ?? m['user_id']) as int,
                            child: Text(m['name']?.toString() ?? 'Unknown'),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _paidByUserId = val),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(DateFormat('MMM dd, yyyy').format(_expenseDate)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text('Category', style: AppTypography.heading.copyWith(fontSize: 16)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _category == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          avatar: Icon(_getCategoryIcon(cat), size: 18, color: isSelected ? AppColors.white : AppColors.textPrimary),
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _category = cat);
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: isSelected ? AppColors.white : AppColors.textPrimary),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                Text('Split Type', style: AppTypography.heading.copyWith(fontSize: 16)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'equal', label: Text('Equal')),
                    ButtonSegment(value: 'custom', label: Text('Custom')),
                    ButtonSegment(value: 'individual', label: Text('Individual')),
                  ],
                  selected: {_splitType},
                  onSelectionChanged: (val) => setState(() => _splitType = val.first),
                ),
                const SizedBox(height: 16),

                if (_splitType == 'individual')
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Who owes this?',
                      border: OutlineInputBorder(),
                    ),
                    value: _individualUserId,
                    items: members.map((m) {
                      return DropdownMenuItem<int>(
                        value: (m['id'] ?? m['user_id']) as int,
                        child: Text(m['name']?.toString() ?? 'Unknown'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _individualUserId = val),
                  ),

                if (_splitType == 'custom')
                  Column(
                    children: members.map((m) {
                      final userId = (m['id'] ?? m['user_id']) as int;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(child: Text(m['name']?.toString() ?? 'Unknown')),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  prefixText: '₹',
                                ),
                                onChanged: (val) {
                                  _customSplits[userId] = double.tryParse(val) ?? 0;
                                  setState((){});
                                },
                              ),
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Save Expense', style: AppTypography.button.copyWith(color: AppColors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
