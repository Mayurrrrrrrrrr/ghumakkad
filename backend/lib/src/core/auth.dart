import 'package:shelf/shelf.dart';
import 'db.dart';

class Auth {
  // Extract user from Bearer token. Returns user map or null.
  static Future<Map<String, dynamic>?> getUser(Request request) async {
    final authHeader = request.headers['authorization'] ?? '';
    if (!authHeader.startsWith('Bearer ')) return null;

    final token = authHeader.substring(7).trim();
    if (token.isEmpty) return null;

    final user = await DB.queryOne('''
      SELECT u.* FROM users u
      JOIN auth_tokens t ON u.id = t.user_id
      WHERE t.token = ? AND t.expires_at > NOW() AND u.is_active = 1
    ''', [token]);

    return user;
  }

  // Use in routes: throws 401 if not logged in
  static Future<Map<String, dynamic>> requireLogin(Request request) async {
    final user = await getUser(request);
    if (user == null) throw UnauthorizedException();
    return user;
  }
}

class UnauthorizedException implements Exception {
  final String message = 'Unauthorized: Invalid or expired token';
}
