import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip_pin.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';
import 'auth_provider.dart';

class PinsNotifier extends StateNotifier<AsyncValue<List<TripPin>>> {
  final ApiService _apiService;
  final int tripId;

  PinsNotifier(this._apiService, this.tripId) : super(const AsyncValue.loading()) {
    fetchPins();
  }

  Future<void> fetchPins() async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiService.get("${ApiConstants.pins}?trip_id=$tripId");
      if (response.data['success'] == true) {
        final List list = response.data['data']['pins'];
        state = AsyncValue.data(list.map((e) => TripPin.fromJson(e)).toList());
      } else {
        state = AsyncValue.error(response.data['message'], StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> addPin(Map<String, dynamic> pinData) async {
    try {
      final response = await _apiService.post(ApiConstants.pins, data: {
        ...pinData,
        'trip_id': tripId,
      });
      if (response.data['success'] == true) {
        fetchPins(); // Refresh list
        return true;
      }
    } catch (e) {
      // Handle error
    }
    return false;
  }
}

final pinsProvider = StateNotifierProvider.family<PinsNotifier, AsyncValue<List<TripPin>>, int>((ref, tripId) {
  final apiService = ref.read(apiServiceProvider);
  return PinsNotifier(apiService, tripId);
});
