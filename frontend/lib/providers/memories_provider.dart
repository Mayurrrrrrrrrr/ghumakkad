import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/memory.dart';
import 'auth_provider.dart';

final memoriesProvider = FutureProvider.family<List<Memory>, int>((ref, tripId) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.get("\${ApiConstants.memories}/trip/\$tripId");
  if (response.data['success'] == true) {
    final List list = response.data['data'];
    return list.map((e) => Memory.fromJson(e)).toList();
  }
  throw Exception(response.data['message'] ?? 'Failed to load memories');
});
