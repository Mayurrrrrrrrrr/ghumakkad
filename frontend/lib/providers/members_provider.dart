import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';
import 'auth_provider.dart';

class MemberNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final ApiService _apiService;
  final int tripId;

  MemberNotifier(this._apiService, this.tripId) : super(const AsyncValue.loading()) {
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    try {
      final response = await _apiService.get("${ApiConstants.members}?trip_id=$tripId");
      if (response.data['success'] == true) {
        state = AsyncValue.data(List<Map<String, dynamic>>.from(response.data['data']));
      } else {
        state = AsyncValue.error(response.data['message'], StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final membersProvider = StateNotifierProvider.family<MemberNotifier, AsyncValue<List<Map<String, dynamic>>>, int>((ref, tripId) {
  final apiService = ref.read(apiServiceProvider);
  return MemberNotifier(apiService, tripId);
});
