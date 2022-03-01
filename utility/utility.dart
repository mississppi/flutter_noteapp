import 'dart:ffi';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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
    }
    return eventName;
  }
}
