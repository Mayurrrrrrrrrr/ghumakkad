import 'dart:convert';
import 'package:shelf/shelf.dart';

class ApiResponse {
  static Response ok(dynamic data, {String message = 'Done'}) {
    return Response.ok(
      jsonEncode({'success': true, 'data': data, 'message': message}),
      headers: {'content-type': 'application/json'},
    );
  }

  static Response error(String message, {int statusCode = 400}) {
    return Response(
      statusCode,
      body: jsonEncode({'success': false, 'data': null, 'message': message}),
      headers: {'content-type': 'application/json'},
    );
  }

  static Response unauthorized([String message = 'Unauthorized']) {
    return Response(401,
      body: jsonEncode({'success': false, 'data': null, 'message': message}),
      headers: {'content-type': 'application/json'},
    );
  }

  static Response notFound([String message = 'Not found']) {
    return Response.notFound(
      jsonEncode({'success': false, 'data': null, 'message': message}),
      headers: {'content-type': 'application/json'},
    );
  }

  static Response serverError(String message) {
    return Response.internalServerError(
      body: jsonEncode({'success': false, 'data': null, 'message': message}),
      headers: {'content-type': 'application/json'},
    );
  }
}
