import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SQLHelper {
  static String notes = 'notes';

  static final _databaseName = "notes.db3";
  static final _databaseVersion = 1;

  // make this a singleton class
  SQLHelper._privateConstructor();
  static final SQLHelper instance = SQLHelper._privateConstructor();

  // only have a single app-wide reference to the database
  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  // this opens the database (and creates it if it doesn't exist)
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute(
      "CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, title INTEGER, content INTEGER, date DATETIME);",
    );
  }

  Future<int> insertNotes(Notes bibleNotes) async {
    Database db = await instance.database;
    if (bibleNotes.id == null) {
      /*final List<Map<String, dynamic>> maps = await db.query(
        bible_notes,
        //where: 'id = ?',
        //whereArgs: [bibleNotes.id],
        orderBy:'title,content,id',
        );*/
      return await db.insert(
        notes,
        bibleNotes.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      /*final List<Map<String, dynamic>> maps = await db.query(
        bible_notes,
        where: 'id = ?',
        whereArgs: [bibleNotes.id],
        orderBy:'title,content,id',
        );*/
      return await db.update(
        notes,
        bibleNotes.toMap(),
        where: 'id = ?',
        whereArgs: [bibleNotes.id],
        //conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<Notes>> getNotesList() async {
    // Get a reference to the database.
    final Database db = await database;

    // Query the table.
    final List<Map<String, dynamic>> maps = await db.query(notes);

    // Convert the List<Map<String, dynamic> into a List<>.
    return List.generate(maps.length, (i) {
      return Notes(
        id: maps[i]['id'],
        title: maps[i]['title'].toString(),
        content: maps[i]['content'],
      );
    });
  }

  Future<List<Notes>> getBibleNotesById(int id) async {
    // Get a reference to the database.
    final Database db = await database;

    // Query the table.
    final List<Map<String, dynamic>> maps = await db.query(
      notes,
      where: 'id = ?',
      whereArgs: [id],
      orderBy: 'title,content,id',
    );

    // Convert the List<Map<String, dynamic> into a List<>.
    return List.generate(maps.length, (i) {
      return Notes(
        id: maps[i]['id'],
        title: maps[i]['title'],
        content: maps[i]['content'],
      );
    });
  }

  Future<void> deleteNote(int id) async {
    final Database db = await database;
    await db.delete(
      notes,
      where: "id = ?",
      whereArgs: [id],
    );
  }
}

class Notes {
  int id;
  String title;
  String content;

  Notes({required this.id, required this.title, required this.content});

  // Convert a Dog into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
    };
  }
}
