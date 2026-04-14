import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../models/trip.dart';
import '../../../models/expense.dart';
import '../../../providers/hisaab_provider.dart';
import '../../../providers/expenses_provider.dart';
import 'add_expense_screen.dart';
import 'settlement_screen.dart';

class HisaabScreen extends ConsumerWidget {
  final Trip trip;
  
  const HisaabScreen({Key? key, required this.trip}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider(trip.id));
    final hisaabAsync = ref.watch(hisaabProvider(trip.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Hisaab', style: AppTypography.heading.copyWith(fontSize: 20)),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(expensesProvider(trip.id));
              ref.refresh(hisaabProvider(trip.id));
            },
          )
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: hisaabAsync.when(
              data: (data) => _buildTopSummaryCard(context, data),
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              )),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Error: \$err'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text("Recent Expenses", style: AppTypography.heading.copyWith(fontSize: 18)),
            ),
          ),
          expensesAsync.when(
            data: (expenses) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildExpenseCard(context, expenses[index], ref);
                },
                childCount: expenses.length,
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: Center(child: Text("Error: \$err")),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => AddExpenseScreen(trip: trip),
          ));
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => SettlementScreen(trip: trip),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Settle Up', style: AppTypography.button.copyWith(color: AppColors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSummaryCard(BuildContext context, Map<String, dynamic> hisaabData) {
    // Determine current user's balance. Mocking for now as we don't have current user id from authProvider easily here.
    // In a real app we'll get ref.read(authProvider) to find current user id.
    // Assuming the user is part of per_member_summary
    final double tripTotal = double.tryParse(hisaabData['trip_total']?.toString() ?? '0') ?? 0;
    
    // For now we'll just display the trip total and maybe loop through all balances
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFFFFB146)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Text("Total Trip Expenses", style: AppTypography.body.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          Text("₹\${tripTotal.toStringAsFixed(2)}", style: AppTypography.display.copyWith(color: AppColors.white, fontSize: 36)),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, Expense expense, WidgetRef ref) {
    IconData getIcon(String cat) {
      switch (cat.toLowerCase()) {
        case 'transport': return Icons.directions_car;
        case 'food': return Icons.restaurant;
        case 'hotel': return Icons.hotel;
        case 'ticket': return Icons.flight;
        case 'activity': return Icons.local_activity;
        default: return Icons.receipt;
      }
    }

    final dateStr = expense.expenseDate != null 
        ? DateFormat('MMM dd, yyyy').format(expense.expenseDate!) 
        : 'Unknown date';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: AppColors.white,
      child: InkWell(
        onTap: () {
          // Show bottom sheet with split breakdown
          _showSplitBreakdown(context, expense);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.background,
                child: Icon(getIcon(expense.category), color: AppColors.secondary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.title, style: AppTypography.heading.copyWith(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text("Paid by \${expense.paidByName}", style: AppTypography.caption),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("₹\${expense.amount.toStringAsFixed(2)}", style: AppTypography.heading.copyWith(fontSize: 16, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(dateStr, style: AppTypography.caption.copyWith(fontSize: 10)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showSplitBreakdown(BuildContext context, Expense expense) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('\${expense.title} - Splits', style: AppTypography.heading.copyWith(fontSize: 20)),
              const Divider(height: 32),
              ...expense.splits.map((split) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(split.userName, style: AppTypography.body),
                    Text("₹\${split.shareAmount.toStringAsFixed(2)}", style: AppTypography.body),
                  ],
                ),
              )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
