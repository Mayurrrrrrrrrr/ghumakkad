import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';
import '../services/db_service.dart';
import '../utils/response_helper.dart';

class TripRoutes {
  Router get router {
    final router = Router();

    // GET /api/v1/trips
    router.get('/', (Request request) async {
      final userId = request.context['user_id'];
      final db = DbService().connection;

      final result = await db.execute(
        'SELECT t.* FROM trips t JOIN trip_members tm ON t.id = tm.trip_id WHERE tm.user_id = :userId ORDER BY t.created_at DESC',
        {'userId': userId},
      );

      final trips = result.rows.map((row) => row.assoc()).toList();
      return ResponseHelper.success(trips, 'Trips fetched');
    });

    // POST /api/v1/trips
    router.post('/', (Request request) async {
      final userId = request.context['user_id'];
      final payload = jsonDecode(await request.readAsString());
      final title = payload['title'];

      if (title == null) return ResponseHelper.error('Title is required');

      final db = DbService().connection;
      final uuid = const Uuid().v4();
      final inviteCode = const Uuid().v4().substring(0, 8).toUpperCase();

      await db.execute(
        'INSERT INTO trips (uuid, title, description, start_date, end_date, creator_id, invite_code) '
        'VALUES (:u, :t, :d, :s, :e, :c, :i)',
        {
          'u': uuid,
          't': title,
          'd': payload['description'],
          's': payload['start_date'],
          'e': payload['end_date'],
          'c': userId,
          'i': inviteCode,
        },
      );

      final tripsResult = await db.execute('SELECT LAST_INSERT_ID() as id');
      final tripId = tripsResult.rows.first.assoc()['id'];

      await db.execute(
        'INSERT INTO trip_members (trip_id, user_id, role) VALUES (:tid, :uid, "creator")',
        {'tid': tripId, 'uid': userId},
      );

      return ResponseHelper.success({'id': tripId, 'uuid': uuid}, 'Trip created');
    });

    return router;
  }
}
