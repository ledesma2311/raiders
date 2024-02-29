import 'dart:ffi';
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
      
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

 
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  late Database _db;

  @override
  void initState(){
    super.initState();
    initDB();
  }
  void initDB() async{
    _db = await openDatabase(
      join(await getDatabasesPath(), "login_database.db"),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE users(id INTEGER PRIMARY KEY, username TEXT, Password TEXT)"
        );
      },
      version: 1,
    );
    CheckAndInsertData();
  }

  Future<void> CheckAndInsertData () async {//verifica si la tabla esta vacia
  final count =
   Sqflite.firstIntValue (await _db.rawQuery("SELECT COUNT(*) FROM users"));
   if (count==0) {
    await _db.transaction((txn) async {
      await txn.rawInsert(
        "INSERT INTO users(id,usarname,password) VALUES (?,?,?)",
        [1,"John","12345"]);

        await txn.rawInsert(
        "INSERT INTO users(id,usarname,password) VALUES (?,?,?)",
        [2,"Alice","12345"]);
    });
   }
  }

Widget build(BuildContext context) {
  Future<void> _login() async {
    final List<Map<String, dynamic>> users = await _db.query('users',
      where: 'username = ? AND password = ?',
      whereArgs: [_usernameController.text, _passwordController.text]);

    if (users.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Invalid username or password.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  return Scaffold(
    body: Column(
      children: [
        Text('Prueba'),

        // Botón para practicar
        ElevatedButton(
          onPressed: () {
            // Acción al presionar el botón
          },
          child: Text('Next'),
        ),
      ],
    ),
  );
}

}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: Text('Welcome!'),
      ),
    );
  }
}
