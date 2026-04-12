import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';
import 'auth_provider.dart';

class RouteNotifier extends StateNotifier<AsyncValue<List<LatLng>>> {
  final ApiService _apiService;
  final int tripId;

  RouteNotifier(this._apiService, this.tripId) : super(const AsyncValue.loading()) {
    fetchRoute();
  }

  Future<void> fetchRoute() async {
    try {
      final response = await _apiService.get("${ApiConstants.route}?trip_id=$tripId");
      if (response.data['success'] == true) {
        final List list = response.data['data']['route'];
        state = AsyncValue.data(list.map((e) => LatLng(double.parse(e['latitude'].toString()), double.parse(e['longitude'].toString()))).toList());
      } else {
        state = AsyncValue.data([]);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> saveRoute(List<LatLng> points) async {
    try {
      final response = await _apiService.post(ApiConstants.route, data: {
        'trip_id': tripId,
        'points': points.map((p) => {'latitude': p.latitude, 'longitude': p.longitude}).toList(),
      });
      if (response.data['success'] == true) {
        state = AsyncValue.data(points);
        return true;
      }
    } catch (e) {
      //
    }
    return false;
  }
}

final routeProvider = StateNotifierProvider.family<RouteNotifier, AsyncValue<List<LatLng>>, int>((ref, tripId) {
  final apiService = ref.read(apiServiceProvider);
  return RouteNotifier(apiService, tripId);
});
