import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../core/auth.dart';
import '../core/db.dart';
import '../core/response.dart';

class PinRoutes {
  Router get router {
    final router = Router();
    router.get('/', _list);
    router.post('/', _create);
    router.put('/<pinId>', _update);
    router.delete('/<pinId>', _delete);
    router.put('/reorder', _reorder);
    return router;
  }

  Future<Response> _list(Request request) async {
    try {
      final user = await Auth.requireLogin(request);
      final tripId = request.url.queryParameters['trip_id'];
      if (tripId == null) return ApiResponse.error("trip_id required");

      final check = await DB.queryOne('SELECT * FROM trip_members WHERE trip_id = ? AND user_id = ?', [tripId, user['id']]);
      if (check == null) return ApiResponse.error("Not a member", statusCode: 403);

      final pins = await DB.query('SELECT * FROM trip_pins WHERE trip_id = ? ORDER BY pinned_at ASC, pin_order ASC', [tripId]);
      return ApiResponse.ok(pins);
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
        INSERT INTO trip_pins (trip_id, added_by, pin_type, title, latitude, longitude, address, pinned_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        tripId,
        user['id'],
        body['pin_type'] ?? 'waypoint',
        body['title'],
        body['latitude'],
        body['longitude'],
        body['address'],
        body['pinned_at']
      ]);

      final pin = await DB.queryOne('SELECT * FROM trip_pins WHERE id = ?', [res.insertId]);
      return ApiResponse.ok(pin);
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _update(Request request, String pinId) async {
    try {
      final user = await Auth.requireLogin(request);
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final id = int.tryParse(pinId);

      final pin = await DB.queryOne('SELECT trip_id FROM trip_pins WHERE id = ?', [id]);
      if (pin == null) return ApiResponse.notFound();

      final check = await DB.queryOne('SELECT * FROM trip_members WHERE trip_id = ? AND user_id = ?', [pin['trip_id'], user['id']]);
      if (check == null) return ApiResponse.error("Not a member", statusCode: 403);

      final allowedFields = ['pin_type', 'title', 'latitude', 'longitude', 'address', 'pinned_at'];
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
        await DB.execute('UPDATE trip_pins SET ${setClauses.join(', ')} WHERE id = ?', params);
      }

      return ApiResponse.ok(null, message: "Updated");
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _delete(Request request, String pinId) async {
    try {
      final user = await Auth.requireLogin(request);
      final id = int.tryParse(pinId);

      final pin = await DB.queryOne('SELECT trip_id FROM trip_pins WHERE id = ?', [id]);
      if (pin == null) return ApiResponse.notFound();

      final check = await DB.queryOne('SELECT * FROM trip_members WHERE trip_id = ? AND user_id = ?', [pin['trip_id'], user['id']]);
      if (check == null) return ApiResponse.error("Not a member", statusCode: 403);

      await DB.execute('DELETE FROM trip_pins WHERE id = ?', [id]);
      return ApiResponse.ok(null, message: "Deleted");
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _reorder(Request request) async {
    try {
      final user = await Auth.requireLogin(request);
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final tripId = body['trip_id'];
      final pinOrders = body['pin_orders'] as List?;

      if (tripId == null || pinOrders == null) return ApiResponse.error("trip_id and pin_orders required");

      final check = await DB.queryOne('SELECT * FROM trip_members WHERE trip_id = ? AND user_id = ?', [tripId, user['id']]);
      if (check == null) return ApiResponse.error("Not a member", statusCode: 403);

      await DB.transaction(() async {
        for (final po in pinOrders) {
          await DB.execute('UPDATE trip_pins SET pin_order = ? WHERE id = ? AND trip_id = ?', [po['order'], po['pin_id'], tripId]);
        }
      });

      return ApiResponse.ok(null, message: "Reordered");
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }
}
