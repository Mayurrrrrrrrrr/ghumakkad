import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';
import 'auth_provider.dart';

final hisaabProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, tripId) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.get("\${ApiConstants.hisaab}/\$tripId");
  if (response.data['success'] == true) {
    return response.data['data'] as Map<String, dynamic>;
  }
  throw Exception(response.data['message'] ?? 'Failed to load hisaab');
});
