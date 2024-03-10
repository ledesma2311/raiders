import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primaryColor: Color.fromARGB(255, 20, 38, 199), // Color primario 
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.white), // Color secundario 
        scaffoldBackgroundColor: Colors.white, // Color de fondo de la pantalla
      ),
      home: const MyHomePage(title: 'Practica'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late Database _db;
  List<Map<String, dynamic>> users = [];
  bool isLoggedIn = false;
  int? selectedUserId;

  @override
  void initState() {
    super.initState();
    initDB();
  }

  void initDB() async {
    _db = await openDatabase(join(await getDatabasesPath(), 'login_database.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE users(id INTEGER PRIMARY KEY, username TEXT, password TEXT)",
        );
      },
      version: 1,
    );
    checkAndInsertData();
  }

  Future<void> checkAndInsertData() async {
    final count =
        Sqflite.firstIntValue(await _db.rawQuery('SELECT COUNT(*) FROM users'));
    if (count == 0) {
      await _db.transaction((txn) async {
        await txn.rawInsert(
            'INSERT INTO users(id, username, password) VALUES(?,?,?)',
            [1, 'John', '12345']);
        await txn.rawInsert(
            'INSERT INTO users(id, username, password) VALUES(?,?,?)',
            [2, 'Alice', '12345']);
      });
    }
  }

  Future<void> getUsers() async {
    final List<Map<String, dynamic>> userList = await _db.query('users');
    setState(() {
      users = userList;
    });
  }

 Future<void> addUser(String username, String password) async {
  await _db.rawInsert(
    'INSERT INTO users(id, username, password) VALUES(NULL,?,?)',
    [username, password],
  );
  getUsers();
  _usernameController.clear();
  _passwordController.clear();
}

  Future<void> updateUser(int id, String username, String password) async {
    await _db.rawUpdate(
      'UPDATE users SET username = ?, password = ? WHERE id = ?',
      [username, password, id],
    );
    getUsers();
    _usernameController.clear();
    _passwordController.clear();
  }

  Future<void> deleteUser(int id) async {
    await _db.rawDelete('DELETE FROM users WHERE id = ?', [id]);
    getUsers();
  }

  @override
  Widget build(BuildContext context) {
    Future<void> login() async {
      final List<Map<String, dynamic>> users = await _db.query('users',
          where: 'username = ? AND password = ?',
          whereArgs: [_usernameController.text, _passwordController.text]);

      if (users.isNotEmpty) {
        setState(() {
          isLoggedIn = true;
        });
        getUsers();
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('Contraseña o nombre incorrecto.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
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
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                setState(() {
                  isLoggedIn = false;
                  _usernameController.text = '';
                  _passwordController.text = '';
                });
              },
            ),
        ],
      ),
      body: isLoggedIn
          ? ListView.builder(
              itemCount: users.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text('User'),
                  subtitle: Text(users[index]['username']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          setState(() {
                            selectedUserId = users[index]['id'];
                            _usernameController.text = users[index]['username'];
                            _passwordController.text = users[index]['password'];
                          });
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Editar Usuario'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: _usernameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Username',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    TextField(
                                      controller: _passwordController,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Password',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('Cancelar'),
                                    onPressed: () {
                                      setState(() {
                                        selectedUserId = null;
                                        _usernameController.clear();
                                        _passwordController.clear();
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('Guardar'),
                                    onPressed: () {
                                      updateUser(
                                        users[index]['id'],
                                        _usernameController.text,
                                        _passwordController.text,
                                      );
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          deleteUser(users[index]['id']);
                        },
                      ),
                    ],
                  ),
                );
              },
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      login();
                    },
                    child: const Text('Login'),
                  ),
                ],
              ),
            ),
      floatingActionButton: isLoggedIn
          ? FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Agregar Usuario'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 20),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancelar'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Agregar'),
                          onPressed: () {
                            addUser(
                              _usernameController.text,
                              _passwordController.text,
                            );
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: Icon(Icons.add),
            )
          : null,
    );
  }
}
