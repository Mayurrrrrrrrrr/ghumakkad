import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../core/auth.dart';
import '../core/db.dart';
import '../core/response.dart';

class MemberRoutes {
  Router get router {
    final router = Router();
    router.get('/', _list);
    router.delete('/', _remove);
    return router;
  }

  Future<Response> _list(Request request) async {
    try {
      final user = await Auth.requireLogin(request);
      final tripId = request.url.queryParameters['trip_id'];
      if (tripId == null) return ApiResponse.error("trip_id required");

      final check = await DB.queryOne('SELECT * FROM trip_members WHERE trip_id = ? AND user_id = ?', [tripId, user['id']]);
      if (check == null) return ApiResponse.error("Not a member", statusCode: 403);

      final members = await DB.query('''
        SELECT u.id, u.name, u.avatar_url, u.phone, tm.role 
        FROM trip_members tm JOIN users u ON tm.user_id = u.id 
        WHERE tm.trip_id = ?
      ''', [tripId]);

      return ApiResponse.ok(members);
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _remove(Request request) async {
    try {
      final user = await Auth.requireLogin(request);
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final tripId = body['trip_id'];
      final userId = body['user_id'];

      if (tripId == null || userId == null) return ApiResponse.error("trip_id and user_id required");
      if (userId == user['id']) return ApiResponse.error("Cannot remove yourself", statusCode: 400);

      final check = await DB.queryOne('SELECT * FROM trips WHERE id = ?', [tripId]);
      if (check == null) return ApiResponse.notFound();
      if (check['creator_id'] != user['id']) return ApiResponse.error("Creator only", statusCode: 403);

      await DB.execute('DELETE FROM trip_members WHERE trip_id = ? AND user_id = ?', [tripId, userId]);
      return ApiResponse.ok(null, message: "Removed");
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }
}
