import 'package:mysql_client/mysql_client.dart';
import '../config/database.dart';

class DB {
  static MySQLConnection? _conn;

  static Future<void> init() async {
    _conn = await MySQLConnection.createConnection(
      host: DbConfig.host,
      port: DbConfig.port,
      userName: DbConfig.user,
      password: DbConfig.password,
      databaseName: DbConfig.database,
      secure: false,
    );
    await _conn!.connect();
    print('MySQL connected');
  }

  static MySQLConnection get conn {
    if (_conn == null) throw Exception('DB not initialized');
    return _conn!;
  }

  // Helper: execute a query and return all rows as List<Map>
  static Future<List<Map<String, dynamic>>> query(
    String sql, [List<Object?>? params]
  ) async {
    final result = await conn.execute(sql, params ?? []);
    return result.rows.map((row) => row.assoc()).toList();
  }

  // Helper: execute insert/update/delete, return affected rows + last insert id
  static Future<({int insertId, int affectedRows})> execute(
    String sql, [List<Object?>? params]
  ) async {
    final result = await conn.execute(sql, params ?? []);
    return (insertId: result.lastInsertID.toInt(), affectedRows: result.affectedRows.toInt());
  }

  // Helper: single row or null
  static Future<Map<String, dynamic>?> queryOne(
    String sql, [List<Object?>? params]
  ) async {
    final rows = await query(sql, params);
    return rows.isEmpty ? null : rows.first;
  }

  // Transaction wrapper
  static Future<T> transaction<T>(Future<T> Function() fn) async {
    await conn.execute('START TRANSACTION');
    try {
      final result = await fn();
      await conn.execute('COMMIT');
      return result;
    } catch (e) {
      await conn.execute('ROLLBACK');
      rethrow;
    }
  }
}
