import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';

class AddTodo extends StatefulWidget {
  AddTodo({Key key, this.title}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() => new _AddTodoState();
}

class _AddTodoState extends State<AddTodo> {
  String _titel, _beschrijving;
  DateTime _datumEnTijd = DateTime.now();

  String _currentUserEmail;

  DateTime selectedDate = DateTime.now();

  void _getData() async {
    final FirebaseUser userData = await FirebaseAuth.instance.currentUser();
    String currentUser = userData.email;
    _currentUserEmail = currentUser;
    print("Geconnecteerde user: $currentUser");
  }

  final _formKey = new GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    _getData();

    return new Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
          centerTitle: true, 
        title: Text(widget.title),
      ),
      body: Column(children: <Widget>[
        Center(
          child: Padding(
              padding: EdgeInsets.only(top: 50, right: 10.0, left: 10.0),
              child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.only(bottom: 10.0),
                          child: TextFormField(
                            decoration: InputDecoration(
                                border: new OutlineInputBorder(
                                    borderSide:
                                        new BorderSide(color: Colors.teal)),
                                labelText: 'Titel',
                                hintText: 'E.g Frietjes maken'),
                            validator: (value) => value.isEmpty
                                ? "Naam moet ingevuld zijn"
                                : null,
                            onSaved: (value) => _titel = value,
                          )),
                      Padding(
                          padding: EdgeInsets.only(bottom: 25.0),
                          child: TextFormField(
                            decoration: InputDecoration(
                                border: new OutlineInputBorder(
                                    borderSide:
                                        new BorderSide(color: Colors.teal)),
                                labelText: 'Beschrijving',
                                hintText: 'E.g Twee pakjes friet maken...'),
                            validator: (value) => value.isEmpty
                                ? "E-mail moet ingevuld zijn"
                                : null,
                            onSaved: (value) => _beschrijving = value,
                          )),
                      Center(
                        child: Text(
                            DateFormat("dd-MM-yyyy hh:mm").format(_datumEnTijd),
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      FlatButton(
                          onPressed: () {
                            DatePicker.showDateTimePicker(context,
                                showTitleActions: true,
                                minTime: DateTime(2018, 3, 5),
                                maxTime: DateTime(2019, 6, 7),
                                onChanged: (date) {
                              print('change $date');
                            }, onConfirm: (date) {
                              setState(() => _datumEnTijd = date);
                              print('confirm $date');
                            },
                                currentTime: DateTime.now(),
                                locale: LocaleType.nl);
                          },
                          child: Text(
                            'Kies datum en tijd',
                            style: TextStyle(color: Colors.amber),
                          )),
                      Padding(
                          padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                          child: RaisedButton(
                            child: new Text('Voeg toe'),
                            color: Colors.amber,
                            onPressed: voegToe,
                          )),
                    ],
                  ))),
        )
      ]),
    );
  }

  void voegToe() async {
    final form = _formKey.currentState;

    form.save();
    print('voegtoe');
    Firestore.instance
        .collection('Users')
        .document(_currentUserEmail)
        .updateData({
      "Todos": FieldValue.arrayUnion([
        {
          'TodoBeschrijving': _beschrijving,
          'TodoTitel': _titel,
          'TodoDatum': _datumEnTijd
        }
      ])
    }).then((l) {
      print('return!');
      Navigator.pop(context);
    });
  }
}
