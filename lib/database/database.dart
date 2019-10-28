import 'dart:io';

import 'package:flutter/material.dart';
import 'package:objectdb/objectdb.dart';
import 'package:path_provider/path_provider.dart';

class Database {

  static Future<ObjectDB> open() async {
    final Directory appDirectory = await getApplicationDocumentsDirectory();
    ObjectDB database = await ObjectDB("${appDirectory.path}/apolloDB.db").open(false);
    return database;
  }

  static Future<void> bulkWrite(List<Map> content) async {
    ObjectDB database = await Database.open();
    await database.insertMany(content);
    database.close();
  }

  static Future<void> dump() async {
    print("Opening database...");
    ObjectDB database = await Database.open();
    print("Dumping contents...");
    debugPrint((await database.find({})).toString(), wrapWidth: 100);
  }

  static Future<void> wipe() async {
    ObjectDB database = await Database.open();
    await database.remove({});
    database.close();
  }

}