import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/audio_task.dart';

class LocalStorageService {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'musicpocket.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE audio_library (
            task_id TEXT PRIMARY KEY,
            original_url TEXT NOT NULL,
            platform TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'completed',
            progress INTEGER DEFAULT 100,
            title TEXT,
            author TEXT,
            cover_url TEXT,
            duration_seconds INTEGER,
            audio_format TEXT,
            download_url TEXT,
            local_path TEXT,
            file_size INTEGER,
            error_message TEXT,
            created_at TEXT NOT NULL,
            is_favorite INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE playlists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE playlist_items (
            playlist_id INTEGER,
            task_id TEXT,
            sort_order INTEGER,
            PRIMARY KEY (playlist_id, task_id),
            FOREIGN KEY (playlist_id) REFERENCES playlists(id),
            FOREIGN KEY (task_id) REFERENCES audio_library(task_id)
          )
        ''');
      },
    );
  }

  Future<void> saveAudio(AudioTask task) async {
    final db = await database;
    await db.insert(
      'audio_library',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AudioTask>> getAllAudios() async {
    final db = await database;
    final maps = await db.query('audio_library', orderBy: 'created_at DESC');
    return maps.map((m) => AudioTask.fromMap(m)).toList();
  }

  Future<List<AudioTask>> getFavorites() async {
    final db = await database;
    final maps = await db.query(
      'audio_library',
      where: 'is_favorite = 1',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => AudioTask.fromMap(m)).toList();
  }

  Future<void> toggleFavorite(String taskId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE audio_library SET is_favorite = CASE WHEN is_favorite = 1 THEN 0 ELSE 1 END WHERE task_id = ?',
      [taskId],
    );
  }

  Future<void> deleteAudio(String taskId) async {
    final db = await database;
    await db.delete('audio_library', where: 'task_id = ?', whereArgs: [taskId]);
  }

  Future<List<AudioTask>> searchAudios(String query) async {
    final db = await database;
    final maps = await db.query(
      'audio_library',
      where: 'title LIKE ? OR author LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => AudioTask.fromMap(m)).toList();
  }
}
