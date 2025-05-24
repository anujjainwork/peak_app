import 'dart:async';
import 'package:peak_app/video/domain/models/video_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class VideoDatabase {
  static final VideoDatabase instance = VideoDatabase._init();
  static Database? _database;

  VideoDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('videos.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, fileName);
    deleteDatabase(path);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE videos (
        id TEXT PRIMARY KEY,
        videoLocalPath TEXT NOT NULL,
        mainthumbnailLocalPath TEXT NOT NULL,
        videothumnailgroup TEXT,
        creationDate TEXT NOT NULL
      )
    ''');
  }

  Future<void> insertVideo(VideoModel video) async {
    final db = await instance.database;
    await db.insert(
      'videos',
      video.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<VideoModel>> getAllVideos() async {
    final db = await instance.database;
    final result = await db.query('videos', orderBy: 'creationDate DESC');
    return result.map((map) => VideoModel.fromMap(map)).toList();
  }

  Future<int> deleteVideo(String id) async {
    final db = await instance.database;
    return await db.delete('videos', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
