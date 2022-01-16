import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Ropes());
}

class Ropes extends StatelessWidget {
  const Ropes({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.yellow,
        fontFamily: "Noto Sans JP",
      ),
      home: RopesComponent(),
    );
  }
}

class RopesComponent extends StatefulWidget {
  @override
  State<RopesComponent> createState() => _RopesComponent();
}

class _RopesComponent extends State<RopesComponent> {
  int? selectedId;
  String? selectedPostCreatedAt;
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  Utility utility = new Utility();

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RawKeyboardListener(
        autofocus: true,
        focusNode: FocusNode(),
        onKey: (event) {
          final key = event.logicalKey;
          if (event is RawKeyDownEvent) {
            String eventName = utility.isEventKeyPressd(event);
            if (eventName == "save") {
              if (selectedId != null) {
                DatabaseHelper.instance.update(
                  Post(
                    id: selectedId,
                    title: titleController.text,
                    content: contentController.text,
                    created_at: selectedPostCreatedAt.toString(),
                    updated_at: utility.getDateTime(),
                  ),
                );
                setState(() {
                  titleController.text = titleController.text;
                  contentController.text = contentController.text;
                  selectedId = selectedId;
                  selectedPostCreatedAt = null;
                });
              }
            }
            if (eventName == "add") {
              DatabaseHelper.instance.add(
                Post(
                  title: "no title",
                  content: "",
                  created_at: utility.getDateTime(),
                  updated_at: utility.getDateTime(),
                ),
              );
              setState(() {
                titleController.clear();
                contentController.clear();
                selectedId = null;
                selectedPostCreatedAt = null;
              });
            }
            if (eventName == "copy") {
              //   if (selectedId != null) {
              //まずテキスト選択状態かどうかの判定
              //     //カーソルが存在したら的なバリでいるかもな
              //     //.selection = 場所
              //     //
              //     //contentController.text.length 文字数

              //     //まずカーソルのクラスあるのか
              //     //まずflutter自体でショートカット用意してないのか調査

              //     contentController.selection = TextSelection.fromPosition(
              //         TextPosition(offset: contentController.text.length));
              //     print("selected");
              //     print(contentController.text.length);
              //   }
            }
          }
        },
        child: Scaffold(
          body: Container(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  //こっちレフトナビ
                  Container(
                    width: 235,
                    child: FutureBuilder<List<Post>>(
                        future: DatabaseHelper.instance.getPosts(),
                        builder: (BuildContext context,
                            AsyncSnapshot<List<Post>> snapshot) {
                          if (!snapshot.hasData) {
                            return Container(child: Text('Loading...'));
                          }
                          return snapshot.data!.isEmpty
                              ? Center(child: Text('No Posts in List'))
                              : ListView(
                                  children: snapshot.data!.map((post) {
                                    return Container(
                                      child: ListTile(
                                        title: Text(post.title),
                                        onTap: () {
                                          setState(() {
                                            titleController.text = post.title;
                                            contentController.text =
                                                post.content;
                                            selectedId = post.id;
                                            selectedPostCreatedAt =
                                                post.created_at;
                                          });
                                        },
                                      ),
                                    );
                                  }).toList(),
                                );
                        }),
                  ),
                  //title
                  Container(
                    width: 450,
                    // child: SingleChildScrollView(
                    child: Stack(
                      children: <Widget>[
                        Positioned(
                          left: 5.0,
                          top: 5.0,
                          width: 1000.0,
                          child: TextField(
                            controller: titleController,
                          ),
                        ),
                        Positioned(
                          left: 5.0,
                          top: 55.0,
                          width: 1000.0,
                          child: TextField(
                            controller: contentController,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      );
}

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

class Post {
  final int? id;
  final String title;
  final String content;
  final String created_at;
  final String updated_at;

  Post(
      {this.id,
      required this.title,
      required this.content,
      required this.created_at,
      required this.updated_at});

  factory Post.fromMap(Map<String, dynamic> json) => new Post(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        created_at: json['created_at'],
        updated_at: json['updated_at'],
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': created_at,
      'updated_at': updated_at
    };
  }
}

class Utility {
  String getDateTime() {
    DateTime now = DateTime.now();
    DateFormat outputFormat = DateFormat('yyyy-MM-dd H:m:s');
    String date = outputFormat.format(now);
    return date;
  }

  String isEventKeyPressd(event) {
    String eventName = "";
    if (event.isKeyPressed(LogicalKeyboardKey.metaLeft) &&
            event.isKeyPressed(LogicalKeyboardKey.keyS) ||
        event.isKeyPressed(LogicalKeyboardKey.metaRight) &&
            event.isKeyPressed(LogicalKeyboardKey.keyS)) {
      eventName = "save";
    } else if (event.isKeyPressed(LogicalKeyboardKey.metaLeft) &&
            event.isKeyPressed(LogicalKeyboardKey.keyN) ||
        event.isKeyPressed(LogicalKeyboardKey.metaRight) &&
            event.isKeyPressed(LogicalKeyboardKey.keyN)) {
      eventName = "add";
    } else if (event.isKeyPressed(LogicalKeyboardKey.metaLeft) &&
            event.isKeyPressed(LogicalKeyboardKey.keyT) ||
        event.isKeyPressed(LogicalKeyboardKey.metaRight) &&
            event.isKeyPressed(LogicalKeyboardKey.keyT)) {
      eventName = "date";
    } else if (event.isKeyPressed(LogicalKeyboardKey.metaLeft) &&
            event.isKeyPressed(LogicalKeyboardKey.keyC) ||
        event.isKeyPressed(LogicalKeyboardKey.metaRight) &&
            event.isKeyPressed(LogicalKeyboardKey.keyC)) {
      eventName = "copy";
    } else if (event.isKeyPressed(LogicalKeyboardKey.metaLeft) &&
            event.isKeyPressed(LogicalKeyboardKey.keyF) ||
        event.isKeyPressed(LogicalKeyboardKey.metaRight) &&
            event.isKeyPressed(LogicalKeyboardKey.keyF)) {
      eventName = "search";
    }
    return eventName;
  }
}
