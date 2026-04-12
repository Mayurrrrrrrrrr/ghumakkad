import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/db_service.dart';
import '../utils/response_helper.dart';

class RouteRoutes {
  Router get router {
    final router = Router();

    router.get('/<trip_id>', (Request request, String trip_id) async {
      final db = DbService().connection;
      final result = await db.execute(
        'SELECT * FROM trip_route WHERE trip_id = :tid ORDER BY point_order ASC',
        {'tid': trip_id},
      );
      return ResponseHelper.success(result.rows.map((r) => r.assoc()).toList(), 'Route fetched');
    });

    router.post('/save', (Request request) async {
      final payload = jsonDecode(await request.readAsString());
      final trip_id = payload['trip_id'];
      final List points = payload['points'];

      final db = DbService().connection;
      
      // Atomic update
      await db.execute('DELETE FROM trip_route WHERE trip_id = :tid', {'tid': trip_id});
      
      for (var i = 0; i < points.length; i++) {
        await db.execute(
          'INSERT INTO trip_route (trip_id, latitude, longitude, point_order) VALUES (:tid, :lat, :lng, :idx)',
          {
            'tid': trip_id,
            'lat': points[i]['latitude'],
            'lng': points[i]['longitude'],
            'idx': i,
          },
        );
      }

      return ResponseHelper.success(null, 'Route saved');
    });

    return router;
  }
}
