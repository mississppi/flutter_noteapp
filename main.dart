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
import './utility/utility.dart';
import './model/post.dart';
import './db/databasehelper.dart';

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
  void initState() {
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
                    status: 'publish',
                    post_order: 1,
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
                  status: 'publish',
                  post_order: 1,
                ),
              );
              setState(() {
                titleController.clear();
                contentController.clear();
                selectedId = null;
                selectedPostCreatedAt = null;
              });
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
