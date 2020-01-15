import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
//import 'package:firebase_core/firebase_core.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:todo_yassine/RegisterPagina.dart';
import 'package:todo_yassine/dialog_modal.dart';
import 'package:todo_yassine/home.dart';
import 'package:flutter_auth_buttons/flutter_auth_buttons.dart';

class LoginPagina extends StatefulWidget {
  LoginPagina({Key key, this.title}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() => new _LoginPaginaState();
}

class _LoginPaginaState extends State<LoginPagina> {
  String _email, _wachtwoord;
  bool valideerEnSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      print('Form is valid: Email: $_email & Password: $_wachtwoord');
      return true;
    }
    return false;
  }

  Future valideerEnAuth() async {
    if (valideerEnSave()) {
      try {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: _email, password: _wachtwoord);

        FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();
        Firestore.instance
            .collection('Users')
            .document(currentUser.email)
            .updateData({"isOnline": true});

/*Firestore.instance.collection('Users').snapshots().listen(
          (data) => print(' ${data.documents[0]['Naam']}')
    );*/

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => LoginPagina(title: 'TodoApp - Login')),
        );

        // print('Ingelogd met : ${gebruiker.user.uid}');
      } catch (e) {
        print('Error:$e');
      }
    }
  }

  void checkAuthGebruiker() async {
    final FirebaseUser userData = await FirebaseAuth.instance.currentUser();
//Wanneer user al ingelogd is onmiddelijk redirecten.
    if (userData != null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => Home(
                title: '',
              )));
    }

//print(userData);
  }

  void gaNaarRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => RegisterPagina(
                title: "Maak een account",
              ),
          fullscreenDialog: true),
    );
  }

  Future<void> signInWithGoogle() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final AuthResult authResult = await _auth.signInWithCredential(credential);
    final FirebaseUser user = authResult.user;

    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);
  }

  final _formKey = new GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    checkAuthGebruiker();

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
                          child: Image.asset('assets/icon.png', height: 150)),
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
                      Padding(
                          padding: EdgeInsets.only(top: 10.0),
                          child: RaisedButton(
                            child: new Text('Log in'),
                            color: Colors.amber,
                            onPressed: valideerEnAuth,
                          )),
                      FlatButton(
                        //color: Colors.amberAccent,
                        child: new Text('Maak een account'),
                        onPressed: gaNaarRegister,
                      ),
                      Divider(
                        color: Colors.amber,
                        thickness: 2,
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 60, right: 60),
                        child: GoogleSignInButton(
                          onPressed: () {
                            /* signInWithGoogle().whenComplete(() {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) {
                                    return FirstScreen();
                                  },
                                ),
                              );
                            }); */

                            showAlertDialog(
                                context: context,
                                title: "Oops..",
                                description:
                                    "Probeer na een volgende update..");
                          },
                          borderRadius: 10,
                        ),
                      )
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

class FirstScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(color: Colors.blue[100]),
    );
  }
}
