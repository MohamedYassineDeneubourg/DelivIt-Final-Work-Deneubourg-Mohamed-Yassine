import 'package:flutter/material.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo_yassine/home.dart';

class RegisterPagina extends StatefulWidget {
  RegisterPagina({Key key, this.title}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() => new _RegisterPaginaState();
}

enum FormType { login, register }

class _RegisterPaginaState extends State<RegisterPagina> {
  String _naam, _email, _wachtwoord, _herhaalWachtwoord;
  bool valideerEnSave() {
    final form = _formKey.currentState;
    if (_wachtwoord == _herhaalWachtwoord) {
      if (form.validate()) {
        form.save();
        print('Form is valid: Email: $_email & Password: $_wachtwoord');
        return true;
      }
    }
    return false;
  }

  Future valideerEnAuth() async {
    if (valideerEnSave()) {
      try {
        AuthResult gebruiker = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: _email, password: _wachtwoord);
        try {
          await Firestore.instance
              .collection("Users")
              .document(_email)
              .setData({
            'Naam': _naam,
            "Position": {
              'latitude': 50.8465573,
              'longitude': 4.351697,
            },
            "GeldEuro" : 0.0,
            'isOnline': true,
            'Todos': [
              {
                'TodoBeschrijving': "Default todo!",
                'TodoTitel': "Default",
                'TodoDatum': DateTime.now()
              }
            ]
          });
        } catch (e) {
          print('Error:$e');
        }
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => Home(
                      title: "TodoApp - $_naam",
                    )),
            (Route<dynamic> route) => false);
        print('Ingelogd met : ${gebruiker.user.uid}');
      } catch (e) {
        print('Error:$e');
      }
    }
  }

  void gaNaarLogin() {
    Navigator.pop(context);
  }

  final _formKey = new GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          padding: EdgeInsets.only(bottom: 50.0),
                          child: Image.asset('assets/icon.png', height: 40)),
                      Padding(
                          padding: EdgeInsets.only(bottom: 10.0),
                          child: TextFormField(
                            decoration: InputDecoration(
                                border: new OutlineInputBorder(
                                    borderSide:
                                        new BorderSide(color: Colors.teal)),
                                labelText: 'Uw volledige naam',
                                hintText: 'E.g Deneubourg Yassine'),
                            validator: (value) => value.isEmpty
                                ? "Naam moet ingevuld zijn"
                                : null,
                            onSaved: (value) => _naam = value,
                          )),
                      Padding(
                          padding: EdgeInsets.only(bottom: 10.0),
                          child: TextFormField(
                            decoration: InputDecoration(
                                border: new OutlineInputBorder(
                                    borderSide:
                                        new BorderSide(color: Colors.teal)),
                                labelText: 'Uw e-mail adress',
                                hintText: 'E.g m.yassine@hotmail.be'),
                            validator: (value) => value.isEmpty
                                ? "E-mail moet ingevuld zijn"
                                : null,
                            onSaved: (value) => _email = value,
                          )),
                      TextFormField(
                        decoration: InputDecoration(
                            border: new OutlineInputBorder(
                                borderSide: new BorderSide(color: Colors.teal)),
                            labelText: 'Uw wachtwoord',
                            hintText: '***'),
                        obscureText: true,
                        validator: (value) => value.isEmpty
                            ? "Wachtwoord moet ingevuld zijn"
                            : null,
                        onSaved: (value) => _wachtwoord = value,
                      ),
                      TextFormField(
                        decoration: InputDecoration(
                            border: new OutlineInputBorder(
                                borderSide: new BorderSide(color: Colors.teal)),
                            labelText: 'Herhaal je wachtwoord',
                            hintText: '***'),
                        obscureText: true,
                        validator: (value) => value.isEmpty
                            ? "Wachtwoord moet ingevuld zijn"
                            : null,
                        onSaved: (value) => _herhaalWachtwoord = value,
                      ),
                      Padding(
                          padding: EdgeInsets.only(top: 10.0),
                          child: RaisedButton(
                            child: new Text('Maak account'),
                            color: Colors.amber,
                            onPressed: valideerEnAuth,
                          )),
                      FlatButton(
                        //color: Colors.amberAccent,
                        child: new Text('Al een account? Log in!'),
                        onPressed: gaNaarLogin,
                      ),
                    ],
                  ))),
        )
      ]),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: null,
      //   tooltip: 'Add Todo',
      //   child: Icon(Icons.add),
      // ),
    );
  }
}
