import '../core/db.dart';

class HisaabService {
  static Future<Map<String, dynamic>> calculateSettlement(int tripId) async {
    // 1. Get all members
    final members = await DB.query(
      'SELECT u.id, u.name, u.avatar_url FROM trip_members tm JOIN users u ON tm.user_id=u.id WHERE tm.trip_id=?',
      [tripId]
    );

    // 2. For each member calculate net balance
    final balances = <Map<String, dynamic>>[];
    
    // Get actual trip total purely by expenses
    final tripTotalResult = await DB.queryOne('SELECT COALESCE(SUM(amount), 0) as total FROM trip_expenses WHERE trip_id=?', [tripId]);
    final tripTotal = double.parse(tripTotalResult!['total'].toString());

    for (final member in members) {
      final userId = member['id'];
      
      // Total paid by this member
      final paidResult = await DB.queryOne(
        'SELECT COALESCE(SUM(amount), 0) as total FROM trip_expenses WHERE trip_id=? AND paid_by=?',
        [tripId, userId]
      );
      final totalPaid = double.parse(paidResult!['total'].toString());

      // Total owed by this member (unsettled splits only)
      final owedResult = await DB.queryOne(
        '''SELECT COALESCE(SUM(es.share_amount), 0) as total
           FROM expense_splits es
           JOIN trip_expenses e ON es.expense_id = e.id
           WHERE e.trip_id=? AND es.user_id=? AND es.is_settled=0''',
        [tripId, userId]
      );
      final totalOwed = double.parse(owedResult!['total'].toString());
      final net = totalPaid - totalOwed;

      balances.add({
        'user': member,
        'total_paid': totalPaid,
        'total_owed': totalOwed,
        'net': net,
      });
    }

    // 3. Debt simplification — greedy algorithm
    final creditors = balances
        .where((b) => (b['net'] as double) > 0.01)
        .map((b) => Map<String, dynamic>.from(b))
        .toList()
      ..sort((a, b) => (b['net'] as double).compareTo(a['net'] as double));

    final debtors = balances
        .where((b) => (b['net'] as double) < -0.01)
        .map((b) => Map<String, dynamic>.from(b))
        .toList()
      ..sort((a, b) => (a['net'] as double).compareTo(b['net'] as double));

    final settlements = <Map<String, dynamic>>[];

    while (creditors.isNotEmpty && debtors.isNotEmpty) {
      final creditor = creditors.first;
      final debtor = debtors.first;

      final amount = [
        (creditor['net'] as double),
        ((debtor['net'] as double)).abs()
      ].reduce((a, b) => a < b ? a : b);

      if (amount < 0.01) break;

      settlements.add({
        'from_user': debtor['user'],
        'to_user': creditor['user'],
        'amount': double.parse(amount.toStringAsFixed(2)),
      });

      creditor['net'] = (creditor['net'] as double) - amount;
      debtor['net'] = (debtor['net'] as double) + amount;

      if ((creditor['net'] as double) < 0.01) creditors.removeAt(0);
      if ((debtor['net'] as double).abs() < 0.01) debtors.removeAt(0);
    }

    return {
      'settlements': settlements,
      'per_member_summary': balances,
      'trip_total': tripTotal,
    };
  }
}
