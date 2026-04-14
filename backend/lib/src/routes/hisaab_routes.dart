import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../core/auth.dart';
import '../core/db.dart';
import '../core/response.dart';
import '../services/hisaab_service.dart';

class HisaabRoutes {
  Router get router {
    final router = Router();
    router.get('/<tripId>', _summary);
    router.post('/<tripId>/settle', _settle);
    return router;
  }

  Future<Response> _summary(Request request, String tripId) async {
    try {
      final user = await Auth.requireLogin(request);
      final id = int.tryParse(tripId);
      if (id == null) return ApiResponse.error("Invalid trip ID");

      final check = await DB.queryOne('SELECT * FROM trip_members WHERE trip_id = ? AND user_id = ?', [id, user['id']]);
      if (check == null) return ApiResponse.error("Not a member", statusCode: 403);

      final result = await HisaabService.calculateSettlement(id);
      return ApiResponse.ok(result);
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  Future<Response> _settle(Request request, String tripId) async {
    try {
      final user = await Auth.requireLogin(request);
      final id = int.tryParse(tripId);
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      if (id == null) return ApiResponse.error("Invalid trip ID");

      final check = await DB.queryOne('SELECT * FROM trip_members WHERE trip_id = ? AND user_id = ?', [id, user['id']]);
      if (check == null) return ApiResponse.error("Not a member", statusCode: 403);

      if (body['expense_split_id'] != null) {
        await DB.execute(
          'UPDATE expense_splits SET is_settled = 1, settled_at = NOW() WHERE id = ?', 
          [body['expense_split_id']]
        );
      } else if (body['from_user_id'] != null && body['to_user_id'] != null) {
        // Find all splits where from_user owes to_user for this trip and mark them settled
        // In the schema provided: expense_splits ties a user (who owes) to an expense (which has a paid_by). 
        // So we update expense_splits user_id=from_user mapping into trip_expenses paid_by=to_user
        await DB.execute('''
          UPDATE expense_splits es
          JOIN trip_expenses e ON es.expense_id = e.id
          SET es.is_settled = 1, es.settled_at = NOW()
          WHERE e.trip_id = ? AND es.user_id = ? AND e.paid_by = ? AND es.is_settled = 0
        ''', [id, body['from_user_id'], body['to_user_id']]);
      } else {
        return ApiResponse.error("Require expense_split_id OR from_user_id + to_user_id");
      }

      return ApiResponse.ok(null, message: "Settled successfully");
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }
}
