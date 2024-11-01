import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    // Obtenir le chemin du répertoire de la base de données
    final path = await getDatabasesPath();

    // Définir le chemin du fichier de la base de données
    final dbPath = join(path, 'chat_database.db');

    // Imprimer le chemin pour le vérifier dans la console
    print("Database path: $dbPath");

    // Ouvrir la base de données
    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Créer la table "messages"
    await db.execute('''
      CREATE TABLE messages(
        messageId TEXT PRIMARY KEY,
        senderId TEXT,
        receiverId TEXT,
        textMessage TEXT,
        type TEXT,
        timeSent INTEGER,
        status TEXT,
        repliedMessage TEXT,
        repliedTo TEXT,
        repliedMessageType TEXT
      )
    ''');

    // Appeler la fonction pour créer la table "sync_metadata"
    await _createSyncMetadataTable(db);
  }

  // Fonction pour créer la table "sync_metadata"
  Future<void> _createSyncMetadataTable(Database db) async {
    await db.execute('''
      CREATE TABLE sync_metadata (
        receiver_id TEXT PRIMARY KEY,
        last_sync_time INTEGER
      )
    ''');
  }

  // Insérer un message dans la base de données
  Future<int> insertMessage(Map<String, dynamic> message) async {
    final db = await database;
    return await db.insert(
      'messages',
      message,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Récupérer les messages pour un utilisateur spécifique
  Future<List<Map<String, dynamic>>> getMessages(String receiverId) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'receiverId = ? OR senderId = ?',
      whereArgs: [receiverId, receiverId],
    );
  }

  // Supprimer un message de la base de données
  Future<void> deleteMessage(String messageId) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'messageId  = ?',
      whereArgs: [messageId],
    );
  }

  // Récupérer l'horodatage du dernier message synchronisé pour un destinataire
 Future<DateTime?> getLastSyncTime(String receiverId) async {
  final db = await database;
  final result = await db.query(
    'sync_metadata',
    columns: ['last_sync_time'],
    where: 'receiver_id = ?',
    whereArgs: [receiverId],
  );

  if (result.isNotEmpty) {
    final lastSyncTimeMillis = result.first['last_sync_time'] as int;
    return DateTime.fromMillisecondsSinceEpoch(lastSyncTimeMillis);
  } else {
    return null;
  }
}


 Future<void> updateLastSyncTime(String receiverId, DateTime lastSyncTime) async {
  final db = await database;
  await db.insert(
    'sync_metadata',
    {
      'receiver_id': receiverId,
      'last_sync_time': lastSyncTime.millisecondsSinceEpoch,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

}
