import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/ticket.dart';
import '../models/hotel.dart';
import 'auth_provider.dart';

class DocsState {
  final List<Ticket> tickets;
  final List<Hotel> hotels;
  
  DocsState({required this.tickets, required this.hotels});
  
  DocsState copyWith({List<Ticket>? tickets, List<Hotel>? hotels}) {
    return DocsState(
      tickets: tickets ?? this.tickets,
      hotels: hotels ?? this.hotels,
    );
  }
}

class DocsNotifier extends StateNotifier<AsyncValue<DocsState>> {
  final ApiService _apiService;
  final int tripId;

  DocsNotifier(this._apiService, this.tripId) : super(const AsyncValue.loading()) {
    fetchDocs();
  }

  Future<void> fetchDocs() async {
    try {
      final tRes = await _apiService.get("\${ApiConstants.tickets}?trip_id=\$tripId");
      final hRes = await _apiService.get("\${ApiConstants.hotels}?trip_id=\$tripId");
      
      List<Ticket> tickets = [];
      List<Hotel> hotels = [];

      if (tRes.data['success'] == true) {
        tickets = (tRes.data['data'] as List).map((e) => Ticket.fromJson(e)).toList();
      }
      if (hRes.data['success'] == true) {
        hotels = (hRes.data['data'] as List).map((e) => Hotel.fromJson(e)).toList();
      }

      state = AsyncValue.data(DocsState(tickets: tickets, hotels: hotels));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> addTicket(Map<String, dynamic> data) async {
    try {
      final res = await _apiService.post(ApiConstants.tickets, data: data);
      if (res.data['success'] == true) {
        final List<Ticket> current = state.value?.tickets ?? [];
        state = AsyncValue.data(DocsState(
          tickets: [...current, Ticket.fromJson(res.data['data'])],
          hotels: state.value?.hotels ?? []
        ));
        return true;
      }
    } catch (e) {
      print('Error adding ticket: \$e');
    }
    return false;
  }

  Future<bool> deleteTicket(int id) async {
    try {
      final res = await _apiService.delete("\${ApiConstants.tickets}/\$id");
      if (res.data['success'] == true) {
        final List<Ticket> current = state.value?.tickets ?? [];
        state = AsyncValue.data(DocsState(
          tickets: current.where((t) => t.id != id).toList(),
          hotels: state.value?.hotels ?? []
        ));
        return true;
      }
    } catch (e) {
      print('Error deleting ticket: \$e');
    }
    return false;
  }

  Future<bool> addHotel(Map<String, dynamic> data) async {
    try {
      final res = await _apiService.post(ApiConstants.hotels, data: data);
      if (res.data['success'] == true) {
        final List<Hotel> current = state.value?.hotels ?? [];
        state = AsyncValue.data(DocsState(
          tickets: state.value?.tickets ?? [],
          hotels: [...current, Hotel.fromJson(res.data['data'])]
        ));
        return true;
      }
    } catch (e) {
      print('Error adding hotel: \$e');
    }
    return false;
  }

  Future<bool> deleteHotel(int id) async {
    try {
      final res = await _apiService.delete("\${ApiConstants.hotels}/\$id");
      if (res.data['success'] == true) {
        final List<Hotel> current = state.value?.hotels ?? [];
        state = AsyncValue.data(DocsState(
          tickets: state.value?.tickets ?? [],
          hotels: current.where((h) => h.id != id).toList()
        ));
        return true;
      }
    } catch (e) {
      print('Error deleting hotel: \$e');
    }
    return false;
  }
}

final docsProvider = StateNotifierProvider.family<DocsNotifier, AsyncValue<DocsState>, int>((ref, tripId) {
  final apiService = ref.read(apiServiceProvider);
  return DocsNotifier(apiService, tripId);
});
