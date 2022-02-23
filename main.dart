import 'dart:collection';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:undo/undo.dart';
import './utility/utility.dart';
import './model/post.dart';
import './db/databasehelper.dart';
// import 'package:flutter_quill/flutter_quill.dart';
// import 'package:simple_rich_text/simple_rich_text.dart';

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
  late SimpleStack _controller;

  @override
  void initState() {
    _controller = SimpleStack(
      {'id': 0, 'value': ''},
      limit: 10,
      onUpdate: (val) {
        if (mounted) setState(() {});
      },
    );
    super.initState();
  }

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
            if (eventName == "undo") {
              print("undo");
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
                            onSubmitted: (text) {
                              print(text);
                              var undo_list = {selectedId: text};
                              var _undo_state = {
                                'id': selectedId,
                                'value': text,
                              };
                              _controller.modify(_undo_state);
                            },
                          ),
                        ),
                        Positioned(
                          left: 10.0,
                          top: 100,
                          width: 150.0,
                          child: ElevatedButton(
                              child: const Text('undo'),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.orange,
                                onPrimary: Colors.white,
                              ),
                              onPressed: () {}),
                        ),
                        Positioned(
                          left: 10.0,
                          top: 150,
                          width: 150.0,
                          child: ElevatedButton(
                            child: const Text('redo'),
                            style: ElevatedButton.styleFrom(
                              primary: Colors.orange,
                              onPrimary: Colors.white,
                            ),
                            onPressed: !_controller.canUndo
                                ? null
                                : () {
                                    if (mounted)
                                      setState(
                                        () {
                                          _controller.undo();
                                        },
                                      );
                                    var data = _controller.state;
                                    print(_controller);
                                  },
                          ),
                        ),
                        Positioned(
                          left: 10.0,
                          top: 200,
                          width: 150.0,
                          child: ElevatedButton(
                            child: const Text('add_button'),
                            style: ElevatedButton.styleFrom(
                              primary: Colors.orange,
                              onPrimary: Colors.white,
                            ),
                            onPressed: () {},
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
