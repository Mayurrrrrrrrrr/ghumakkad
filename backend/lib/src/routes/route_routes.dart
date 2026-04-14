import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../core/auth.dart';
import '../core/db.dart';
import '../core/response.dart';

class RouteRoutes {
  Router get router {
    final router = Router();
    router.get('/', _get);
    router.post('/', _save);
    return router;
  }

  Future<Response> _get(Request request) async {
    try {
      final user = await Auth.requireLogin(request);
      final tripId = request.url.queryParameters['trip_id'];
      if (tripId == null) return ApiResponse.error("trip_id required");

      final check = await DB.queryOne('SELECT * FROM trip_members WHERE trip_id = ? AND user_id = ?', [tripId, user['id']]);
      if (check == null) return ApiResponse.error("Not a member", statusCode: 403);

      final points = await DB.query('SELECT latitude, longitude FROM trip_route WHERE trip_id = ? ORDER BY point_order ASC', [tripId]);
      return ApiResponse.ok({'route': points});
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _save(Request request) async {
    try {
      final user = await Auth.requireLogin(request);
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final tripId = body['trip_id'];
      final points = body['points'] as List?;

      if (tripId == null || points == null) return ApiResponse.error("trip_id and points required");

      final check = await DB.queryOne('SELECT * FROM trip_members WHERE trip_id = ? AND user_id = ?', [tripId, user['id']]);
      if (check == null) return ApiResponse.error("Not a member", statusCode: 403);

      await DB.transaction(() async {
        await DB.execute('DELETE FROM trip_route WHERE trip_id = ?', [tripId]);
        
        int order = 0;
        for (final p in points) {
          await DB.execute(
            'INSERT INTO trip_route (trip_id, latitude, longitude, point_order) VALUES (?, ?, ?, ?)',
            [tripId, p['latitude'], p['longitude'], order++]
          );
        }
      });

      return ApiResponse.ok(null, message: "Route saved");
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }
}
