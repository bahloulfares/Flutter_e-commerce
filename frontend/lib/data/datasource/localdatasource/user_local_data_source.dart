import 'package:atelier7/data/datasource/models/users.model.dart';
import 'package:atelier7/utils/password_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class UserLocalDataSource {
  static final UserLocalDataSource _instance = UserLocalDataSource._internal();
  static Database? _database;

  factory UserLocalDataSource() {
    return _instance;
  }

  UserLocalDataSource._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute(
      '''CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT, password TEXT)''',
    );
  }

  Future<Map<String, dynamic>> insertUser(User user) async {
    final db = await database;

    // Hasher le mot de passe avant de le stocker (SÉCURITÉ)
    final hashedPassword = PasswordHelper.hashPassword(user.password);

    // Insérer l'utilisateur et récupérer l'ID inséré
    final int userId = await db.insert('users', {
      'username': user.username,
      'password': hashedPassword,
    });

    // Retourner une Map avec les informations de l'utilisateur, y compris l'ID
    return {
      'id': userId,
      'username': user.username,
      'password': hashedPassword,
    };
  }

  Future<User?> getUser(String username, String password) async {
    final db = await database;

    // Récupérer l'utilisateur par nom d'utilisateur
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (result.isNotEmpty) {
      final storedPassword = result.first['password'] as String;

      // Vérifier le mot de passe avec le hash (SÉCURITÉ)
      if (PasswordHelper.verifyPassword(password, storedPassword)) {
        return User(
          id: result.first['id'] as int,
          username: result.first['username'] as String,
          password: storedPassword,
        );
      }
    }
    return null;
  }
}
