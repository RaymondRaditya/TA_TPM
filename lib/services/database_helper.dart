import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = "tshirt_app.db";
  static const _databaseVersion = 1;

  // =======================================================
  //                    TABLE SCHEMAS
  // =======================================================

  // --- Users Table ---
  static const tableUsers = 'users';
  static const columnUserId = 'id';
  static const columnUsername = 'username';
  static const columnEmail = 'email';
  static const columnPasswordHash = 'password_hash';
  static const columnIsBiometricEnabled = 'is_biometric_enabled';

  // --- Saved Designs Table ---
  static const tableSavedDesigns = 'saved_designs';
  static const columnDesignId = 'id';
  static const columnDesignUserId = 'user_id';
  static const columnDesignName = 'design_name';
  static const columnLayoutJsonData = 'layout_json_data';
  static const columnCreatedAt = 'created_at';

  // =======================================================
  //              SINGLETON INITIALIZATION
  // =======================================================

  // Private constructor to enforce singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  // Returns the single active database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  Future _onConfigure(Database db) async {
    // Enable foreign keys for dependent tables
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableUsers (
        $columnUserId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnUsername TEXT NOT NULL UNIQUE,
        $columnEmail TEXT UNIQUE,
        $columnPasswordHash TEXT,
        $columnIsBiometricEnabled INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableSavedDesigns (
        $columnDesignId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnDesignUserId INTEGER NOT NULL,
        $columnDesignName TEXT NOT NULL,
        $columnLayoutJsonData TEXT NOT NULL,
        $columnCreatedAt TEXT NOT NULL,
        FOREIGN KEY ($columnDesignUserId) REFERENCES $tableUsers ($columnUserId) ON DELETE CASCADE
      )
    ''');
  }

  // =======================================================
  //                 CRUD OPERATIONS: USERS
  // =======================================================

  Future<int> insertUser(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableUsers, row);
  }

  Future<Map<String, dynamic>?> getUser(int id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> results = await db.query(
      tableUsers,
      where: '$columnUserId = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> results = await db.query(
      tableUsers,
      where: '$columnUsername = ?',
      whereArgs: [username],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> results = await db.query(
      tableUsers,
      where: '$columnEmail = ?',
      whereArgs: [email],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateUser(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnUserId];
    return await db.update(
      tableUsers,
      row,
      where: '$columnUserId = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteUser(int id) async {
    Database db = await instance.database;
    return await db.delete(
      tableUsers,
      where: '$columnUserId = ?',
      whereArgs: [id],
    );
  }

  // =======================================================
  //            CRUD OPERATIONS: SAVED DESIGNS
  // =======================================================

  Future<int> insertDesign(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableSavedDesigns, row);
  }

  Future<Map<String, dynamic>?> getDesign(int id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> results = await db.query(
      tableSavedDesigns,
      where: '$columnDesignId = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getDesignsByUserId(int userId) async {
    Database db = await instance.database;
    return await db.query(
      tableSavedDesigns,
      where: '$columnDesignUserId = ?',
      whereArgs: [userId],
    );
  }

  Future<int> updateDesign(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnDesignId];
    return await db.update(
      tableSavedDesigns,
      row,
      where: '$columnDesignId = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteDesign(int id) async {
    Database db = await instance.database;
    return await db.delete(
      tableSavedDesigns,
      where: '$columnDesignId = ?',
      whereArgs: [id],
    );
  }
}
