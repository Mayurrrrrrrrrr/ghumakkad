import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';

import '../lib/src/services/db_service.dart';
import '../lib/src/middleware/auth_middleware.dart';
import '../lib/src/routes/auth_routes.dart';
import '../lib/src/routes/trip_routes.dart';
import '../lib/src/routes/pin_routes.dart';
import '../lib/src/routes/route_routes.dart';

void main() async {
  // 1. Initialize Database
  final dbService = DbService();
  await dbService.init();

  final router = Router();

  // 2. Mount API Routes
  router.mount('/api/v1/auth', AuthRoutes().router);
  router.mount('/api/v1/trips', TripRoutes().router);
  router.mount('/api/v1/pins', PinRoutes().router);
  router.mount('/api/v1/route', RouteRoutes().router);

  // 3. Setup Middlewares
  final pipeline = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addMiddleware((Handler innerHandler) {
        return (Request request) async {
          print('--- Global Pipeline Entry ---');
          print('Path: ${request.url.path}');
          print('Content-Length: ${request.contentLength}');
          return await innerHandler(request);
        };
      })
      .addMiddleware(authMiddleware());

  final handler = pipeline.addHandler(Cascade()
          .add(router)
          .add(createStaticHandler('web', defaultDocument: 'index.html'))
          .handler);

  // 4. Start Server
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('Server running on port ${server.port}');
}

Middleware _corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
        });
      }
      final response = await innerHandler(request);
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
      });
    };
  };
}
