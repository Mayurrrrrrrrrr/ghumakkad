import 'dart:convert';
import 'package:shelf/shelf.dart';

class ResponseHelper {
  static Response json(bool success, dynamic data, String message, {int status = 200}) {
    final body = jsonEncode({
      'success': success,
      'data': data,
      'message': message,
    });

    return Response(
      status,
      body: body,
      headers: {'Content-Type': 'application/json'},
    );
  }

  static Response error(String message, {int status = 400}) {
    return json(false, null, message, status: status);
  }

  static Response success(dynamic data, String message) {
    return json(true, data, message);
  }
}
