import 'package:flutter/material.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:todo_yassine/TodoDetail.dart';
import 'addTodo.dart';
import 'LoginPagina.dart';

class TodoPagina extends StatefulWidget {
  TodoPagina({Key key, this.title}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() => new _TodoPaginaState();
}

class _TodoPaginaState extends State<TodoPagina> {
  List _todoCards = new List();
  String userEmail;

  void _getData() async {
    final FirebaseUser userData = await FirebaseAuth.instance.currentUser();
    if (userData != null) {
      userEmail = userData.email;
      var reference =
          Firestore.instance.collection("Users").document(userData.email);
      List todoLijst;

      reference.snapshots().listen((querySnapshot) {
       
        todoLijst = querySnapshot.data['Todos'];
        //print(todoLijst[0]['TodoDatum']);

        if (filterValue == 'Overzicht vandaag') {
          final now = DateTime.now();
          print(DateTime(now.year, now.month, now.day));

          List _todoLijstFiltered = [];
          for (int i = 0; i < todoLijst.length; i++) {
            if(_todoCards != null){
print(i);            
            DateTime date = _todoCards[i]['TodoDatum'].toDate();
            if (date.year == now.year &&
                date.month == now.month &&
                date.day == now.day) {
              _todoLijstFiltered.add(todoLijst[i]);
            }
          } }
          if (this.mounted) {
            setState(() {
              _todoCards = _todoLijstFiltered;
            });
          }
        } else {
           if (this.mounted) {
          setState(() {
            print("Refreshed");
            _todoCards = todoLijst;
          });
        } }
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => LoginPagina(title: 'TodoApp - Login')),
      );
    }

    //print(_todoCards);
  }

  @override
  void initState() {
    print("init!");
    _getData();
    super.initState();
  }

  String filterValue = "Totaal overzicht";
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Container(
          padding: new EdgeInsets.only(top: 8.0, bottom: 20),
          child: new Center(
            child: new Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                  child: DropdownButton<String>(
                    value: filterValue,
                    icon: Icon(Icons.arrow_downward),
                    iconSize: 16,
                    onChanged: (String newValue) {
                       if (this.mounted) {
                      setState(() {
                        filterValue = newValue;
                      });
                       }
                      _getData();
                    },
                    items: <String>['Totaal overzicht', 'Overzicht vandaag']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                new Expanded(
                    child: new ListView.builder(
                  itemCount: _todoCards.length,
                  itemBuilder: (context, index) {
                    String datum = new DateFormat.yMMMd()
                        .format(_todoCards[index]['TodoDatum'].toDate())
                        .toString();

                    String tijd = new DateFormat.Hm()
                        .format(_todoCards[index]['TodoDatum'].toDate())
                        .toString();

                    return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: ListTile(
                          onLongPress: () {
                            _showDeleteVraag(_todoCards[index]);
                          },
                          onTap: () {
                            goToDetail(_todoCards[index]);
                          },
                          trailing: Text('$datum\n$tijd '),
                          leading: CircleAvatar(
                            backgroundColor: Colors.amberAccent,
                          ),
                          title: Text('${_todoCards[index]['TodoTitel']}',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle:
                              Text('${_todoCards[index]['TodoBeschrijving']}'),
                        ));
                  },
                ))
              ],
            ),
          )),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: voegTodoToe,
        label: Text('Todo'),
        icon: Icon(Icons.plus_one),
        backgroundColor: Colors.amber,
      ),
    );
  }

  void voegTodoToe() async {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddTodo(
                title: "Nieuwe Todo",
              ),
          fullscreenDialog: true),
    );
  }

  void _showDeleteVraag(Map todoMap) {
    String todoNaam = "'" + todoMap['TodoTitel'] + "'";
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Verwijderen?"),
          content: new Text("Wil je $todoNaam Verwijderen?"),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            FlatButton(
              color: Colors.amber,
              child: new Text(
                "Ja",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                deleteTodo(todoMap);
              },
            ),
            FlatButton(
              child: new Text("Neen"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }

  deleteTodo(Map todoMap) async {
    print(userEmail);
    Firestore.instance.collection('Users').document(userEmail).updateData({
      "Todos": FieldValue.arrayRemove([todoMap])
    }).then((l) {
      Navigator.of(context).pop();
      print('Verwijderd!');
    });
  }

  goToDetail(Map todoMap) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => TodoDetail(todoMap: todoMap),
          fullscreenDialog: true),
    );
  }
}
