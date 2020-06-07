import 'package:flutter/material.dart';
import 'package:todo_yassine/LoginPagina.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
    
      title: 'TodoApp - Yassine',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: LoginPagina(title: 'TodoApp - Login'),
    );
  }

  
}
