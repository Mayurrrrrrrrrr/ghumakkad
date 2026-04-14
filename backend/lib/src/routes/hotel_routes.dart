import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../core/auth.dart';
import '../core/db.dart';
import '../core/response.dart';

class HotelRoutes {
  Router get router {
    final router = Router();
    router.get('/', _list);
    router.post('/', _create);
    router.put('/<hotelId>', _update);
    router.delete('/<hotelId>', _delete);
    return router;
  }

  Future<Response> _list(Request request) async {
    try {
      final user = await Auth.requireLogin(request);
      final tripId = request.url.queryParameters['trip_id'];
      if (tripId == null) return ApiResponse.error("trip_id required");

      final check = await DB.queryOne('SELECT * FROM trip_members WHERE trip_id = ? AND user_id = ?', [tripId, user['id']]);
      if (check == null) return ApiResponse.error("Not a member", statusCode: 403);

      final hotels = await DB.query('SELECT * FROM trip_hotels WHERE trip_id = ? ORDER BY check_in ASC', [tripId]);
      return ApiResponse.ok(hotels);
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _create(Request request) async {
    try {
      final user = await Auth.requireLogin(request);
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final tripId = body['trip_id'];
      if (tripId == null) return ApiResponse.error("trip_id required");

      final check = await DB.queryOne('SELECT * FROM trip_members WHERE trip_id = ? AND user_id = ?', [tripId, user['id']]);
      if (check == null) return ApiResponse.error("Not a member", statusCode: 403);

      final res = await DB.execute('''
        INSERT INTO trip_hotels (trip_id, added_by, hotel_name, city, check_in, check_out, confirmation_no, amount, pin_id, booking_image_url, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        tripId, user['id'], body['hotel_name'], body['city'], body['check_in'],
        body['check_out'], body['confirmation_no'], body['amount'], body['pin_id'],
        body['booking_image_url'], body['notes']
      ]);

      final hotel = await DB.queryOne('SELECT * FROM trip_hotels WHERE id = ?', [res.insertId]);
      return ApiResponse.ok(hotel);
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _update(Request request, String hotelId) async {
    try {
      final user = await Auth.requireLogin(request);
      final id = int.tryParse(hotelId);
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final h = await DB.queryOne('''
        SELECT h.added_by, tr.creator_id FROM trip_hotels h
        JOIN trips tr ON h.trip_id = tr.id WHERE h.id = ?
      ''', [id]);
      if (h == null) return ApiResponse.notFound();
      if (h['added_by'] != user['id'] && h['creator_id'] != user['id']) {
        return ApiResponse.error("Only added_by or creator can edit", statusCode: 403);
      }

      final allowedFields = ['hotel_name', 'city', 'check_in', 'check_out', 'confirmation_no', 'amount', 'pin_id', 'booking_image_url', 'notes'];
      List<String> setClauses = [];
      List<dynamic> params = [];

      for (final field in allowedFields) {
        if (body.containsKey(field)) {
          setClauses.add('\$field = ?');
          params.add(body[field]);
        }
      }

      if (setClauses.isNotEmpty) {
        params.add(id);
        await DB.execute('UPDATE trip_hotels SET \${setClauses.join(', ')} WHERE id = ?', params);
      }

      return ApiResponse.ok(null, message: "Updated");
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _delete(Request request, String hotelId) async {
    try {
      final user = await Auth.requireLogin(request);
      final id = int.tryParse(hotelId);

      final h = await DB.queryOne('''
        SELECT h.added_by, tr.creator_id FROM trip_hotels h
        JOIN trips tr ON h.trip_id = tr.id WHERE h.id = ?
      ''', [id]);
      if (h == null) return ApiResponse.notFound();
      if (h['added_by'] != user['id'] && h['creator_id'] != user['id']) {
        return ApiResponse.error("Only added_by or creator can delete", statusCode: 403);
      }

      await DB.execute('DELETE FROM trip_hotels WHERE id = ?', [id]);
      return ApiResponse.ok(null, message: "Deleted");
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }
}
