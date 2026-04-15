import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';
import 'auth_provider.dart';

final tripsProvider = FutureProvider<List<Trip>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.get(ApiConstants.trips);
  
  if (response.data['success'] == true) {
    final rawData = response.data['data'];
    final List list = rawData is List ? rawData : (rawData['trips'] ?? []);
    return list.map((e) => Trip.fromJson(e)).toList();
  }
  return [];
});

final activeTripProvider = StateProvider<Trip?>((ref) => null);
