import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../core/auth.dart';
import '../core/db.dart';
import '../core/response.dart';

class MemoryRoutes {
  Router get router {
    final router = Router();
    router.get('/', _list);
    router.post('/', _create);
    router.delete('/<memoryId>', _delete);
    router.get('/trip/<tripId>', _tripTimeline);
    return router;
  }

  Future<Response> _list(Request request) async {
    try {
      final user = await Auth.requireLogin(request);
      final pinId = request.url.queryParameters['pin_id'];
      if (pinId == null) return ApiResponse.error("pin_id required");

      final pin = await DB.queryOne('SELECT trip_id FROM trip_pins WHERE id = ?', [pinId]);
      if (pin == null) return ApiResponse.notFound();

      final check = await DB.queryOne('SELECT * FROM trip_members WHERE trip_id = ? AND user_id = ?', [pin['trip_id'], user['id']]);
      if (check == null) return ApiResponse.error("Not a member", statusCode: 403);

      final memories = await DB.query('''
        SELECT m.*, u.name as added_by_name, u.avatar_url as added_by_avatar
        FROM pin_memories m
        JOIN users u ON m.added_by = u.id
        WHERE m.pin_id = ?
        ORDER BY m.created_at ASC
      ''', [pinId]);

      return ApiResponse.ok(memories);
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
      final pinId = body['pin_id'];
      if (pinId == null) return ApiResponse.error("pin_id required");

      final pin = await DB.queryOne('SELECT trip_id FROM trip_pins WHERE id = ?', [pinId]);
      if (pin == null) return ApiResponse.notFound();

      final check = await DB.queryOne('SELECT * FROM trip_members WHERE trip_id = ? AND user_id = ?', [pin['trip_id'], user['id']]);
      if (check == null) return ApiResponse.error("Not a member", statusCode: 403);

      final res = await DB.execute('''
        INSERT INTO pin_memories (pin_id, added_by, memory_type, content, caption)
        VALUES (?, ?, ?, ?, ?)
      ''', [
        pinId,
        user['id'],
        body['memory_type'] ?? 'note',
        body['content'],
        body['caption']
      ]);

      final memory = await DB.queryOne('SELECT * FROM pin_memories WHERE id = ?', [res.insertId]);
      return ApiResponse.ok(memory);
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _delete(Request request, String memoryId) async {
    try {
      final user = await Auth.requireLogin(request);
      final id = int.tryParse(memoryId);

      final memory = await DB.queryOne('SELECT added_by FROM pin_memories WHERE id = ?', [id]);
      if (memory == null) return ApiResponse.notFound();

      if (memory['added_by'] != user['id']) return ApiResponse.error("Can only delete own memories", statusCode: 403);

      await DB.execute('DELETE FROM pin_memories WHERE id = ?', [id]);
      return ApiResponse.ok(null, message: "Deleted");
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _tripTimeline(Request request, String tripId) async {
    try {
      final user = await Auth.requireLogin(request);
      final id = int.tryParse(tripId);

      final check = await DB.queryOne('SELECT * FROM trip_members WHERE trip_id = ? AND user_id = ?', [id, user['id']]);
      if (check == null) return ApiResponse.error("Not a member", statusCode: 403);

      final memories = await DB.query('''
        SELECT pm.*, tp.title as pin_title, tp.latitude, tp.longitude, tp.address,
               tp.pinned_at, u.name as added_by_name, u.avatar_url as added_by_avatar
        FROM pin_memories pm
        JOIN trip_pins tp ON pm.pin_id = tp.id
        JOIN users u ON pm.added_by = u.id
        WHERE tp.trip_id = ?
        ORDER BY tp.pinned_at ASC, pm.created_at ASC
      ''', [id]);

      return ApiResponse.ok(memories);
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }
}
