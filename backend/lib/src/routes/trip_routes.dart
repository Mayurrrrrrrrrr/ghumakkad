import 'dart:convert';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../core/auth.dart';
import '../core/db.dart';
import '../core/response.dart';

class TripRoutes {
  Router get router {
    final router = Router();
    router.get('/', _list);
    router.post('/', _create);
    router.get('/<tripId>', _detail);
    router.put('/<tripId>', _update);
    router.delete('/<tripId>', _delete);
    router.put('/<tripId>/archive', _archive);
    router.get('/join/<inviteCode>', _joinInfo);
    router.post('/join/<inviteCode>', _join);
    router.put('/<tripId>/transfer', _transfer);
    router.get('/<tripId>/invite-link', _inviteLink);
    return router;
  }

  Future<Response> _list(Request request) async {
    try {
      final user = await Auth.requireLogin(request);
      final trips = await DB.query('''
        SELECT t.*, tm.role, 
               (SELECT COUNT(*) FROM trip_members WHERE trip_id = t.id) as member_count,
               (SELECT COUNT(*) FROM trip_pins WHERE trip_id = t.id) as pin_count
        FROM trips t
        JOIN trip_members tm ON t.id = tm.trip_id
        WHERE tm.user_id = ?
        ORDER BY CASE WHEN t.status = 'active' THEN 1 ELSE 2 END, t.start_date DESC
      ''', [user['id']]);
      return ApiResponse.ok(trips);
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
      final title = body['title'];
      if (title == null) return ApiResponse.error("Title required");

      final desc = body['description'];
      final start = body['start_date'];
      final end = body['end_date'];

      // UUID
      final random = Random.secure();
      final uuidBytes = List<int>.generate(16, (_) => random.nextInt(256));
      final uuidStr = uuidBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      
      // Invite code: 12 char alphanumeric
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final inviteCode = List.generate(12, (_) => chars[random.nextInt(chars.length)]).join();

      int tripId = 0;
      await DB.transaction(() async {
        final res = await DB.execute('''
          INSERT INTO trips (uuid, title, description, start_date, end_date, creator_id, invite_code)
          VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', [uuidStr, title, desc, start, end, user['id'], inviteCode]);
        tripId = res.insertId;

        await DB.execute(
          "INSERT INTO trip_members (trip_id, user_id, role) VALUES (?, ?, 'creator')",
          [tripId, user['id']]
        );
      });

      final newTrip = await DB.queryOne('SELECT * FROM trips WHERE id = ?', [tripId]);
      return ApiResponse.ok(newTrip);
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _detail(Request request, String tripId) async {
    try {
      final user = await Auth.requireLogin(request);
      final id = int.tryParse(tripId);
      if (id == null) return ApiResponse.error("Invalid trip ID");

      final memberCheck = await DB.queryOne('SELECT * FROM trip_members WHERE trip_id = ? AND user_id = ?', [id, user['id']]);
      if (memberCheck == null) return ApiResponse.error("Not a member", statusCode: 403);

      final trip = await DB.queryOne('SELECT * FROM trips WHERE id = ?', [id]);
      if (trip == null) return ApiResponse.notFound("Trip not found");

      final members = await DB.query('''
        SELECT u.id, u.name, u.avatar_url, tm.role
        FROM trip_members tm JOIN users u ON tm.user_id = u.id WHERE tm.trip_id = ?
      ''', [id]);
      
      final pinCount = await DB.queryOne('SELECT COUNT(*) as c FROM trip_pins WHERE trip_id = ?', [id]);
      trip['members'] = members;
      trip['pin_count'] = pinCount?['c'] ?? 0;

      return ApiResponse.ok(trip);
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _update(Request request, String tripId) async {
    try {
      final user = await Auth.requireLogin(request);
      final id = int.tryParse(tripId);
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final tripCheck = await DB.queryOne('SELECT creator_id FROM trips WHERE id = ?', [id]);
      if (tripCheck == null) return ApiResponse.notFound();
      if (tripCheck['creator_id'] != user['id']) return ApiResponse.error("Creator only", statusCode: 403);

      final allowedFields = ['title', 'description', 'start_date', 'end_date', 'cover_image_url'];
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
        await DB.execute('UPDATE trips SET \${setClauses.join(', ')} WHERE id = ?', params);
      }

      return ApiResponse.ok(null, message: "Updated");
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _delete(Request request, String tripId) async {
    try {
      final user = await Auth.requireLogin(request);
      final id = int.tryParse(tripId);

      final tripCheck = await DB.queryOne('SELECT creator_id FROM trips WHERE id = ?', [id]);
      if (tripCheck == null) return ApiResponse.notFound();
      if (tripCheck['creator_id'] != user['id']) return ApiResponse.error("Creator only", statusCode: 403);

      await DB.execute('DELETE FROM trips WHERE id = ?', [id]);
      return ApiResponse.ok(null, message: "Deleted");
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _archive(Request request, String tripId) async {
    try {
      final user = await Auth.requireLogin(request);
      final id = int.tryParse(tripId);

      final tripCheck = await DB.queryOne('SELECT creator_id FROM trips WHERE id = ?', [id]);
      if (tripCheck == null) return ApiResponse.notFound();
      if (tripCheck['creator_id'] != user['id']) return ApiResponse.error("Creator only", statusCode: 403);

      await DB.execute("UPDATE trips SET status = 'archived' WHERE id = ?", [id]);
      return ApiResponse.ok(null, message: "Archived");
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _joinInfo(Request request, String inviteCode) async {
    try {
      final tripInfo = await DB.queryOne('''
        SELECT t.title, t.start_date, t.end_date, u.name as creator_name, 
               (SELECT COUNT(*) FROM trip_members WHERE trip_id = t.id) as member_count
        FROM trips t JOIN users u ON t.creator_id = u.id 
        WHERE t.invite_code = ?
      ''', [inviteCode]);

      if (tripInfo == null) return ApiResponse.notFound("Invalid invite code");
      return ApiResponse.ok(tripInfo);
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _join(Request request, String inviteCode) async {
    try {
      final user = await Auth.requireLogin(request);
      final trip = await DB.queryOne('SELECT * FROM trips WHERE invite_code = ?', [inviteCode]);
      if (trip == null) return ApiResponse.notFound("Invalid invite code");

      final check = await DB.queryOne('SELECT * FROM trip_members WHERE trip_id = ? AND user_id = ?', [trip['id'], user['id']]);
      if (check == null) {
        await DB.execute(
          "INSERT INTO trip_members (trip_id, user_id, role) VALUES (?, ?, 'member')",
          [trip['id'], user['id']]
        );
      }
      return ApiResponse.ok(trip);
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _transfer(Request request, String tripId) async {
    try {
      final user = await Auth.requireLogin(request);
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final newCreatorId = body['new_creator_user_id'];
      final id = int.tryParse(tripId);

      if (newCreatorId == null) return ApiResponse.error("new_creator_user_id required");

      final tripCheck = await DB.queryOne('SELECT creator_id FROM trips WHERE id = ?', [id]);
      if (tripCheck == null) return ApiResponse.notFound();
      if (tripCheck['creator_id'] != user['id']) return ApiResponse.error("Creator only", statusCode: 403);

      final memberCheck = await DB.queryOne('SELECT * FROM trip_members WHERE trip_id = ? AND user_id = ?', [id, newCreatorId]);
      if (memberCheck == null) return ApiResponse.error("User is not a member", statusCode: 403);

      await DB.transaction(() async {
        await DB.execute("UPDATE trip_members SET role = 'member' WHERE trip_id = ? AND user_id = ?", [id, user['id']]);
        await DB.execute("UPDATE trip_members SET role = 'creator' WHERE trip_id = ? AND user_id = ?", [id, newCreatorId]);
        await DB.execute("UPDATE trips SET creator_id = ? WHERE id = ?", [newCreatorId, id]);
      });

      return ApiResponse.ok(null, message: "Transferred");
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _inviteLink(Request request, String tripId) async {
    try {
      final user = await Auth.requireLogin(request);
      final id = int.tryParse(tripId);

      final tripCheck = await DB.queryOne('SELECT invite_code FROM trips WHERE id = ?', [id]);
      if (tripCheck == null) return ApiResponse.notFound();
      
      final memberCheck = await DB.queryOne('SELECT * FROM trip_members WHERE trip_id = ? AND user_id = ?', [id, user['id']]);
      if (memberCheck == null) return ApiResponse.error("Not a member", statusCode: 403);

      final code = tripCheck['invite_code'];
      return ApiResponse.ok({
        'invite_code': code,
        'url': 'https://ghumakkad.yuktaa.com/join/$code'
      });
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }
}
