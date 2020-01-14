import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TodoDetail extends StatefulWidget {
  final Map todoMap;

  TodoDetail({Key key, this.todoMap}) : super(key: key);

  @override
  _TodoDetailState createState() => _TodoDetailState(todoMap: this.todoMap);
}

class _TodoDetailState extends State<TodoDetail> {
  _TodoDetailState({Key key, @required this.todoMap});

  Map todoMap;

  @override
  Widget build(BuildContext context) {
    String datum =
        new DateFormat.yMMMd().format(todoMap['TodoDatum'].toDate()).toString();

    String tijd =
        new DateFormat.Hm().format(todoMap['TodoDatum'].toDate()).toString();

    return new Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar( centerTitle: true, 
          title: Text(todoMap["TodoTitel"]),
        ),
        body: Center(
            child: Padding(
                padding: EdgeInsets.only(top: 50),
                child: Column(children: <Widget>[
                  Text(
                    "Beschrijving",
                    style: TextStyle(fontSize: 20),
                  ),
                  Text(todoMap["TodoBeschrijving"]),
                  Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text(
                        "Datum & tijd",
                        style: TextStyle(fontSize: 20),
                      )),
                  Text("$datum - $tijd"),  Padding(
                      padding: EdgeInsets.only(top: 70),
                      child: RaisedButton.icon(onPressed: deleteTodo, color: Colors.redAccent, icon: Icon(Icons.delete_forever), label: Text("Verwijderen"),) )
                ]))));
  }

  deleteTodo() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();

    Firestore.instance.collection('Users').document(user.email).updateData({
      "Todos": FieldValue.arrayRemove([this.todoMap])
    }).then((l) {
      Navigator.of(context).pop();
      print('Verwijderd!');
    });
  }
}
