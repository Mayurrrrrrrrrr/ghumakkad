import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/expense.dart';
import 'auth_provider.dart';

class ExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final ApiService _apiService;
  final int tripId;

  ExpensesNotifier(this._apiService, this.tripId) : super(const AsyncValue.loading()) {
    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    try {
      final response = await _apiService.get("${ApiConstants.expenses}?trip_id=$tripId");
      if (response.data['success'] == true) {
        final List list = response.data['data'];
        state = AsyncValue.data(list.map((e) => Expense.fromJson(e)).toList());
      } else {
        state = AsyncValue.error(response.data['message'], StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> addExpense(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(ApiConstants.expenses, data: data);
      if (response.data['success'] == true) {
        await fetchExpenses(); // Refresh list to get all splits properly formatted from server
        return true;
      }
    } catch (e) {
      print('Error adding expense: $e');
    }
    return false;
  }

  Future<bool> deleteExpense(int expenseId) async {
    try {
      final response = await _apiService.delete("${ApiConstants.expenses}/$expenseId");
      if (response.data['success'] == true) {
        state = AsyncValue.data(state.value?.where((e) => e.id != expenseId).toList() ?? []);
        return true;
      }
    } catch (e) {
      print('Error deleting expense: $e');
    }
    return false;
  }
}

final expensesProvider = StateNotifierProvider.family<ExpensesNotifier, AsyncValue<List<Expense>>, int>((ref, tripId) {
  final apiService = ref.read(apiServiceProvider);
  return ExpensesNotifier(apiService, tripId);
});
