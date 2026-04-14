import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import '../lib/src/routes/auth_routes.dart';
import '../lib/src/routes/trip_routes.dart';
import '../lib/src/routes/pin_routes.dart';
import '../lib/src/routes/memory_routes.dart';
import '../lib/src/routes/member_routes.dart';
import '../lib/src/routes/ticket_routes.dart';
import '../lib/src/routes/hotel_routes.dart';
import '../lib/src/routes/expense_routes.dart';
import '../lib/src/routes/hisaab_routes.dart';
import '../lib/src/routes/route_routes.dart';
import '../lib/src/routes/upload_routes.dart';
import '../lib/src/core/db.dart';

void main() async {
  // Init DB pool on startup
  await DB.init();

  final router = Router();

  // Mount all route groups
  router.mount('/api/v1/auth/',     AuthRoutes().router);
  router.mount('/api/v1/trips/',    TripRoutes().router);
  router.mount('/api/v1/pins/',     PinRoutes().router);
  router.mount('/api/v1/memories/', MemoryRoutes().router);
  router.mount('/api/v1/members/',  MemberRoutes().router);
  router.mount('/api/v1/tickets/',  TicketRoutes().router);
  router.mount('/api/v1/hotels/',   HotelRoutes().router);
  router.mount('/api/v1/expenses/', ExpenseRoutes().router);
  router.mount('/api/v1/hisaab/',   HisaabRoutes().router);
  router.mount('/api/v1/route/',    RouteRoutes().router);
  router.mount('/api/v1/upload/',   UploadRoutes().router);

  final handler = Pipeline()
      .addMiddleware(_corsMiddleware())
      .addMiddleware(logRequests())
      .addHandler(router);

  final server = await io.serve(handler, '127.0.0.1', 8080);
  print('Ghumakkad API running on port ${server.port}');
}

// CORS middleware — required for all responses
Middleware _corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders());
      }
      final response = await innerHandler(request);
      return response.change(headers: _corsHeaders());
    };
  };
}

Map<String, String> _corsHeaders() => {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type',
};
