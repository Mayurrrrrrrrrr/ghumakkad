import 'dart:io';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:mime/mime.dart';
import '../core/auth.dart';
import '../core/db.dart';
import '../core/response.dart';

class UploadRoutes {
  Router get router {
    final router = Router();
    router.post('/image', _uploadImage);
    return router;
  }

  Future<Response> _uploadImage(Request request) async {
    try {
      final user = await Auth.requireLogin(request);
      
      final contentType = request.headers['content-type'] ?? '';
      if (!contentType.contains('multipart/form-data')) {
        return ApiResponse.error('Multipart form-data required');
      }

      // Simplified extraction for the prompt's sake. In a real environment, 
      // mime's MimeMultipartTransformer is used. Since we must provide working code:
      final boundary = contentType.split('boundary=').last;
      final transformer = MimeMultipartTransformer(boundary);
      final parts = await transformer.bind(request.read()).toList();
      
      if (parts.isEmpty) return ApiResponse.error('No file provided');
      final part = parts.first; // take first file
      
      final fileBytes = await part.fold<List<int>>([], (p, e) => p..addAll(e));
      if (fileBytes.length > 5 * 1024 * 1024) return ApiResponse.error("Max file size is 5MB");
      
      final now = DateTime.now();
      final dir = '/home/ubuntu/ghumakkad_uploads/\${now.year}/\${now.month.toString().padLeft(2, '0')}';
      await Directory(dir).create(recursive: true);
      
      final filename = '\${_randomHex(8)}.jpg'; 
      final file = File('\$dir/\$filename');
      await file.writeAsBytes(fileBytes);
      
      final url = 'https://ghumakkad.yuktaa.com/uploads/\${now.year}/\${now.month.toString().padLeft(2, '0')}/\$filename';
      return ApiResponse.ok({'url': url});
    } on UnauthorizedException {
      return ApiResponse.unauthorized();
    } catch (e) {
      return ApiResponse.serverError(e.toString());
    }
  }

  String _randomHex(int bytes) {
    final random = Random.secure();
    final values = List<int>.generate(bytes, (_) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
