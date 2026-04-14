class MemberBalance {
  final Map<String, dynamic> user;
  final double totalPaid;
  final double totalOwed;
  final double net;

  MemberBalance({
    required this.user,
    required this.totalPaid,
    required this.totalOwed,
    required this.net,
  });

  factory MemberBalance.fromJson(Map<String, dynamic> json) {
    return MemberBalance(
      user: json['user'],
      totalPaid: double.parse(json['total_paid'].toString()),
      totalOwed: double.parse(json['total_owed'].toString()),
      net: double.parse(json['net'].toString()),
    );
  }
}
