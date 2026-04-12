import 'package:shelf/shelf.dart';
import '../services/db_service.dart';
import '../utils/response_helper.dart';

Middleware authMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      // List of public endpoints that don't need auth
      final publicPaths = [
        'api/v1/auth/send-otp',
        'api/v1/auth/verify-otp',
      ];

      // Log the path to debug 401 issues
      print('--- Request Debug ---');
      print('Path: ${request.url.path}');
      print('Method: ${request.method}');
      print('Headers: ${request.headers}');
      print('--------------------');

      // Static files and index.html are public
      if (!request.url.path.startsWith('api/v1/')) {
        return await innerHandler(request);
      }

      if (publicPaths.any((path) => request.url.path == path || request.url.path == "/$path")) {
        print('Auth Middleware: Path is public, allowing access.');
        return await innerHandler(request);
      }

      final authHeader = request.headers['Authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return ResponseHelper.error('Unauthorized', status: 401);
      }

      final token = authHeader.substring(7);
      final db = DbService().connection;

      final result = await db.execute(
        'SELECT user_id FROM auth_tokens WHERE token = :token AND expires_at > NOW()',
        {'token': token},
      );

      if (result.rows.isEmpty) {
        return ResponseHelper.error('Invalid or expired token', status: 401);
      }

      // Add user_id to request context for downstream handlers
      final userId = result.rows.first.assoc()['user_id'];
      final updatedRequest = request.change(context: {'user_id': userId});

      return await innerHandler(updatedRequest);
    };
  };
}
