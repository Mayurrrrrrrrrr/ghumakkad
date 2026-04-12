import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/db_service.dart';
import '../utils/response_helper.dart';

class PinRoutes {
  Router get router {
    final router = Router();

    router.get('/<trip_id>', (Request request, String trip_id) async {
      final db = DbService().connection;
      final result = await db.execute(
        'SELECT * FROM trip_pins WHERE trip_id = :tid ORDER BY pin_order ASC',
        {'tid': trip_id},
      );
      return ResponseHelper.success(result.rows.map((r) => r.assoc()).toList(), 'Pins fetched');
    });

    router.post('/', (Request request) async {
      final userId = request.context['user_id'];
      final payload = jsonDecode(await request.readAsString());
      
      final db = DbService().connection;
      await db.execute(
        'INSERT INTO trip_pins (trip_id, added_by, pin_type, title, latitude, longitude, address, pinned_at) '
        'VALUES (:tid, :aid, :pt, :t, :lat, :lng, :addr, :pat)',
        {
          'tid': payload['trip_id'],
          'aid': userId,
          'pt': payload['pin_type'] ?? 'memory',
          't': payload['title'],
          'lat': payload['latitude'],
          'lng': payload['longitude'],
          'addr': payload['address'],
          'pat': payload['pinned_at'] ?? DateTime.now().toIso8601String(),
        },
      );

      return ResponseHelper.success(null, 'Pin added');
    });

    return router;
  }
}
