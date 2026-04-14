class Settlement {
  final Map<String, dynamic> fromUser;
  final Map<String, dynamic> toUser;
  final double amount;

  Settlement({
    required this.fromUser,
    required this.toUser,
    required this.amount,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      fromUser: json['from_user'],
      toUser: json['to_user'],
      amount: double.parse(json['amount'].toString()),
    );
  }
}
