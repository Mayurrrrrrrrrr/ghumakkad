import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../core/auth.dart';
import '../core/db.dart';
import '../core/response.dart';

class TicketRoutes {
  Router get router {
    final router = Router();
    router.get('/', _list);
    router.post('/', _create);
    router.put('/<ticketId>', _update);
    router.delete('/<ticketId>', _delete);
    return router;
  }

  Future<Response> _list(Request request) async {
    try {
      final user = await Auth.requireLogin(request);
      final tripId = request.url.queryParameters['trip_id'];
      if (tripId == null) return ApiResponse.error("trip_id required");

      final check = await DB.queryOne('SELECT * FROM trip_members WHERE trip_id = ? AND user_id = ?', [tripId, user['id']]);
      if (check == null) return ApiResponse.error("Not a member", statusCode: 403);

      final tickets = await DB.query('SELECT * FROM trip_tickets WHERE trip_id = ? ORDER BY travel_date ASC', [tripId]);
      return ApiResponse.ok(tickets);
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
        INSERT INTO trip_tickets (trip_id, added_by, ticket_type, from_place, to_place, travel_date, travel_time, pnr_number, amount, pin_id, ticket_image_url, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        tripId, user['id'], body['ticket_type'], body['from_place'], body['to_place'],
        body['travel_date'], body['travel_time'], body['pnr_number'], body['amount'],
        body['pin_id'], body['ticket_image_url'], body['notes']
      ]);

      final ticket = await DB.queryOne('SELECT * FROM trip_tickets WHERE id = ?', [res.insertId]);
      return ApiResponse.ok(ticket);
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _update(Request request, String ticketId) async {
    try {
      final user = await Auth.requireLogin(request);
      final id = int.tryParse(ticketId);
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final t = await DB.queryOne('''
        SELECT t.added_by, tr.creator_id FROM trip_tickets t
        JOIN trips tr ON t.trip_id = tr.id WHERE t.id = ?
      ''', [id]);
      if (t == null) return ApiResponse.notFound();
      if (t['added_by'] != user['id'] && t['creator_id'] != user['id']) {
        return ApiResponse.error("Only added_by or creator can edit", statusCode: 403);
      }

      final allowedFields = ['ticket_type', 'from_place', 'to_place', 'travel_date', 'travel_time', 'pnr_number', 'amount', 'pin_id', 'ticket_image_url', 'notes'];
      List<String> setClauses = [];
      List<dynamic> params = [];

      for (final field in allowedFields) {
        if (body.containsKey(field)) {
          setClauses.add('$field = ?');
          params.add(body[field]);
        }
      }

      if (setClauses.isNotEmpty) {
        params.add(id);
        await DB.execute('UPDATE trip_tickets SET ${setClauses.join(', ')} WHERE id = ?', params);
      }

      return ApiResponse.ok(null, message: "Updated");
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _delete(Request request, String ticketId) async {
    try {
      final user = await Auth.requireLogin(request);
      final id = int.tryParse(ticketId);

      final t = await DB.queryOne('''
        SELECT t.added_by, tr.creator_id FROM trip_tickets t
        JOIN trips tr ON t.trip_id = tr.id WHERE t.id = ?
      ''', [id]);
      if (t == null) return ApiResponse.notFound();
      if (t['added_by'] != user['id'] && t['creator_id'] != user['id']) {
        return ApiResponse.error("Only added_by or creator can delete", statusCode: 403);
      }

      await DB.execute('DELETE FROM trip_tickets WHERE id = ?', [id]);
      return ApiResponse.ok(null, message: "Deleted");
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }
}
