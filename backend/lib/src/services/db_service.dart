import 'package:mysql_client/mysql_client.dart';

class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  MySQLConnection? _connection;

  Future<void> init() async {
    _connection = await MySQLConnection.createConnection(
      host: 'localhost',
      port: 3306,
      userName: 'mayur_user',
      password: 'Mayur@12345',
      databaseName: 'ghumakkad_db',
    );
    await _connection!.connect();
    print('MySQL Connected Successfully');
  }

  MySQLConnection get connection {
    if (_connection == null) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return _connection!;
  }
}
