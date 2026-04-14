class ExpenseSplit {
  final int id;
  final int expenseId;
  final int userId;
  final String userName;
  final String? userAvatar;
  final double shareAmount;
  final bool isSettled;

  ExpenseSplit({
    required this.id,
    required this.expenseId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.shareAmount,
    required this.isSettled,
  });

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseSplit(
      id: json['id'],
      expenseId: json['expense_id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? 'Unknown',
      userAvatar: json['user_avatar'],
      shareAmount: double.parse(json['share_amount'].toString()),
      isSettled: json['is_settled'] == 1 || json['is_settled'] == true,
    );
  }
}
