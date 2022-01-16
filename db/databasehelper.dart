import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../model/post.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();
  Future<Database> _initDatabase() async {
    Directory documentDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentDirectory.path, 'posts.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE posts(
        id INTEGER PRIMARY KEY,
        title TEXT,
        content TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
  }

  Future<List<Post>> getPosts() async {
    Database db = await instance.database;
    var posts = await db.query('posts', orderBy: 'title');
    List<Post> postList =
        posts.isNotEmpty ? posts.map((c) => Post.fromMap(c)).toList() : [];
    return postList;
  }

  Future<int> add(Post post) async {
    Database db = await instance.database;
    return await db.insert('posts', post.toMap());
  }

  Future<int> update(Post post) async {
    Database db = await instance.database;
    return await db
        .update("posts", post.toMap(), where: "id=?", whereArgs: [post.id]);
  }
}
