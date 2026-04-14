import 'expense_split.dart';

class Expense {
  final int id;
  final int tripId;
  final int paidBy;
  final String paidByName;
  final String? paidByAvatar;
  final String title;
  final double amount;
  final String splitType;
  final DateTime? expenseDate;
  final String category;
  final String? receiptUrl;
  final List<ExpenseSplit> splits;

  Expense({
    required this.id,
    required this.tripId,
    required this.paidBy,
    required this.paidByName,
    this.paidByAvatar,
    required this.title,
    required this.amount,
    required this.splitType,
    this.expenseDate,
    required this.category,
    this.receiptUrl,
    required this.splits,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      tripId: json['trip_id'],
      paidBy: json['paid_by'],
      paidByName: json['paid_by_name'] ?? 'Unknown',
      paidByAvatar: json['paid_by_avatar'],
      title: json['title'],
      amount: double.parse(json['amount'].toString()),
      splitType: json['split_type'],
      expenseDate: json['expense_date'] != null ? DateTime.parse(json['expense_date']) : null,
      category: json['category'] ?? 'Other',
      receiptUrl: json['receipt_url'],
      splits: json['splits'] != null
          ? (json['splits'] as List).map((s) => ExpenseSplit.fromJson(s)).toList()
          : [],
    );
  }
}
