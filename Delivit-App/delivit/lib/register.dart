import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';

class Register extends StatefulWidget {
  Register({Key key, this.phoneNumber}) : super(key: key);

  final String phoneNumber;

  @override
  State<StatefulWidget> createState() =>
      _RegisterState(phoneNumber: this.phoneNumber);
}

class _RegisterState extends State<Register> {
  _RegisterState({Key key, @required this.phoneNumber});

  String _voornaam,
      _naam,
      _email,
      _wachtwoord,
      _herhaalWachtwoord,
      smsOTP,
      verificationId;
  String errorMessage = '';
  String phoneNumber;
  FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> verifyPhone() async {
    final PhoneCodeSent smsOTPSent = (String verId, [int forceCodeResend]) {
      print(verId);
      this.verificationId = verId;
      smsOTPDialog(context).then((value) {
        print(value);
        print('Verify phone');
      });
    };
    try {
      print(this.phoneNumber);
      await _auth.verifyPhoneNumber(
          phoneNumber: this.phoneNumber,
          codeAutoRetrievalTimeout: (String verId) {
            this.verificationId = verId;
          },
          codeSent: smsOTPSent,
          timeout: const Duration(seconds: 20),
          verificationCompleted: (AuthCredential phoneAuthCredential) {
            print("OK!");
            print(phoneAuthCredential);
          },
          verificationFailed: (AuthException exceptio) {
            print("FAILLLL!");
            print('${exceptio.message}');
          });
    } catch (e) {
      handleError(e);
    }
  }

  Future<bool> smsOTPDialog(BuildContext context) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text('VOEG JE SMS-CODE',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: Container(
              height: 85,
              child: Column(children: [
                TextField(
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25),
                  onChanged: (value) {
                    this.smsOTP = value;
                  },
                ),
                (errorMessage != ''
                    ? Flexible(
                        child: Text(
                        errorMessage,
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 8,
                            fontWeight: FontWeight.bold),
                      ))
                    : Container())
              ]),
            ),
            contentPadding: EdgeInsets.all(20),
            actions: <Widget>[
              ButtonTheme(
                  minWidth: 400.0,
                  child: RaisedButton(
                    color: Geel,
                    child: Text(
                      "BEVESTIG CODE",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      print("bevestiged code!");
                      valideerEnAuth();
                      //  signIn();
                    },
                  ))
            ],
          );
        });
  }

  signIn() async {
    try {
      print("yeah!");
      PhoneAuthProvider.getCredential(
        verificationId: verificationId,
        smsCode: smsOTP,
      );
    } catch (e) {
      print("nonono!");
      handleError(e);
    }
  }

  handleError(PlatformException error) {
    print(error);
    switch (error.code) {
      case 'ERROR_INVALID_VERIFICATION_CODE':
        FocusScope.of(context).requestFocus(new FocusNode());
        setState(() {
          errorMessage = 'De code is niet correct..';
        });
        Navigator.of(context).pop();
        smsOTPDialog(context).then((value) {
          print('sign in');
        });
        break;
      default:
        setState(() {
          errorMessage = error.message;
        });

        break;
    }
  }

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
    print("valideerEnAuth!");
    if (valideerEnSave()) {
      try {
        print("Creating User...");

        await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _email, password: _wachtwoord);

        final AuthCredential credential = PhoneAuthProvider.getCredential(
          verificationId: verificationId,
          smsCode: smsOTP,
        );
        print("Link phone number..");
        final FirebaseUser currentUser = await _auth.currentUser();
        currentUser.linkWithCredential(credential);
        // currentUser.updateEmail(_email);
        print("Creating user in DATABASE...");
        try {
          await Firestore.instance
              .collection("Users")
              .document(phoneNumber)
              .setData({
            'Naam': _naam,
            "Voornaam": _voornaam,
            "Email": _email,
            "PhoneNumber": phoneNumber,
            "Position": {
              'latitude': 50.8465573,
              'longitude': 4.351697,
            },
            "GeldEuro": 0.0,
            'isOnline': true,
          });

          print("User fully created!");
        } catch (e) {
          //handleError(e);
          setState(() {
            errorMessage = "Probeer opnieuw, foute code..";
          });
          print('Error:$e');
        }
        /*    Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => Home(
                      title: "TodoApp - $_naam",
                    )),
            (Route<dynamic> route) => false);*/
        // print('Ingelogd met : ${gebruiker.user.uid}');
      } catch (e) {
        print('error: $e');
      }
    }
  }

  void gaNaarLogin() {
    Navigator.pop(context);
  }

  final _formKey = new GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        resizeToAvoidBottomPadding: false,
        body: Stack(children: <Widget>[
          ColorFiltered(
              colorFilter: ColorFilter.mode(
                  Colors.white.withOpacity(0.9), BlendMode.srcOver),
              child: Image.asset(
                'assets/images/backgroundLogin.jpg',
                width: size.width,
                height: size.height,
                fit: BoxFit.cover,
              )),
          Center(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                //Box met titel BEGIN
                Padding(
                    padding: EdgeInsets.only(top: 75),
                    child: Container(
                        width: size.width * 0.90,
                        decoration: new BoxDecoration(
                            color: Geel,
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 1.0,
                                color: GrijsMidden,
                                offset: Offset(0.3, 0.3),
                              ),
                            ],
                            borderRadius:
                                new BorderRadius.all(Radius.circular(10.0))),
                        child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              children: <Widget>[
                                Text("Vul uw gegevens in",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 30),
                                    textAlign: TextAlign.center),
                                Text(
                                  "Deze zullen beschermd worden",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              ],
                            )))),
                // EINDE box met titel
                //BEGIN TEXTVELDEN
                Center(
                  child: Padding(
                      padding:
                          EdgeInsets.only(top: 50, right: 10.0, left: 10.0),
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
                                        fillColor: Colors.white,
                                        filled: true,
                                        border: new OutlineInputBorder(
                                            borderSide:
                                                new BorderSide(color: Geel)),
                                        labelText: 'Naam',
                                        hintText: 'E.g Deneubourg'),
                                    validator: (value) => value.isEmpty
                                        ? "Naam moet ingevuld zijn"
                                        : null,
                                    onSaved: (value) => _naam = value,
                                  )),
                              Padding(
                                  padding: EdgeInsets.only(bottom: 10.0),
                                  child: TextFormField(
                                    decoration: InputDecoration(
                                        fillColor: Colors.white,
                                        filled: true,
                                        border: new OutlineInputBorder(
                                            borderSide:
                                                new BorderSide(color: Geel)),
                                        labelText: 'Voornaam',
                                        hintText: 'E.g Yassine'),
                                    validator: (value) => value.isEmpty
                                        ? "Voornaam moet ingevuld zijn"
                                        : null,
                                    onSaved: (value) => _voornaam = value,
                                  )),
                              Padding(
                                  padding: EdgeInsets.only(bottom: 10.0),
                                  child: TextFormField(
                                    decoration: InputDecoration(
                                        fillColor: Colors.white,
                                        filled: true,
                                        border: new OutlineInputBorder(
                                            borderSide:
                                                new BorderSide(color: Geel)),
                                        labelText: 'Uw e-mail adress',
                                        hintText: 'E.g m.yassine@hotmail.be'),
                                    validator: (value) => value.isEmpty
                                        ? "E-mail moet ingevuld zijn"
                                        : null,
                                    onSaved: (value) => _email = value,
                                  )),
                              Padding(
                                  padding: EdgeInsets.only(bottom: 10.0),
                                  child: TextFormField(
                                    decoration: InputDecoration(
                                        fillColor: Colors.white,
                                        filled: true,
                                        border: new OutlineInputBorder(
                                            borderSide:
                                                new BorderSide(color: Geel)),
                                        labelText: 'Uw wachtwoord',
                                        hintText: '***'),
                                    obscureText: true,
                                    validator: (value) => value.isEmpty
                                        ? "Wachtwoord moet ingevuld zijn"
                                        : null,
                                    onSaved: (value) => _wachtwoord = value,
                                  )),
                              Padding(
                                  padding: EdgeInsets.only(bottom: 10.0),
                                  child: TextFormField(
                                    decoration: InputDecoration(
                                        fillColor: Colors.white,
                                        filled: true,
                                        border: new OutlineInputBorder(
                                            borderSide:
                                                new BorderSide(color: Geel)),
                                        labelText: 'Herhaal je wachtwoord',
                                        hintText: '***'),
                                    obscureText: true,
                                    validator: (value) => value.isEmpty
                                        ? "Wachtwoord moet ingevuld zijn"
                                        : null,
                                    onSaved: (value) =>
                                        _herhaalWachtwoord = value,
                                  )),
                              Padding(
                                  padding: EdgeInsets.only(top: 10.0),
                                  child: RaisedButton(
                                    child: new Text('SCHRIJF JE IN',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    color: Geel,
                                    onPressed: () {
                                      verifyPhone();
                                    },
                                  )),
                            ],
                          ))),
                )
                //EINDE TEXTVELDEN
              ]))
        ]));
  }
}
