import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/keuze.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toast/toast.dart';

import 'colors.dart';

class Register extends StatefulWidget {
  Register({Key key, this.phoneNumber}) : super(key: key);

  final String phoneNumber;

  @override
  State<StatefulWidget> createState() =>
      _RegisterState(phoneNumber: this.phoneNumber);
}

class _RegisterState extends State<Register> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  _RegisterState({Key key, @required this.phoneNumber});

  String _voornaam,
      _naam,
      _email,
      _wachtwoord,
      _herhaalWachtwoord,
      smsOTP,
      verificationId;
  String errorMessage = '';
  bool smsValid = false;
  String phoneNumber;
  FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> verifyPhone() async {
    if (valideerEnSave()) {
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
        final errorToast = SnackBar(
            content: Text('Er is iets mis gegaan.. U kan herbeginnen.'));
        _scaffoldKey.currentState.showSnackBar(errorToast);
        handleError(e);
      }
    } else {
      Toast.show("Er is iets mis gegaan.. U kan herbeginnen.", context,
          duration: Toast.LENGTH_SHORT,
          gravity: Toast.TOP,
          backgroundColor: Colors.red);
    }
  }

  Future<bool> smsOTPDialog(BuildContext context) {
    if (valideerEnSave()) {
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
    } else {
      Toast.show("Wachtwoord is niet hetzelfde, probeer opnieuw", context,
          duration: Toast.LENGTH_SHORT,
          gravity: Toast.TOP,
          backgroundColor: Colors.red);
      return null;
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
        print('popdaar!');
        // Navigator.of(context).pop();
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

    print(_wachtwoord);
    print(_herhaalWachtwoord);
    if (form.validate()) {
      form.save();
      print('Form is valid: Email: $_email & Password: $_wachtwoord');
      if (_wachtwoord == _herhaalWachtwoord) {
        return true;
      } else {
        Toast.show("Wachtwoord is niet hetzelfde, probeer opnieuw", context,
            duration: Toast.LENGTH_SHORT,
            gravity: Toast.TOP,
            backgroundColor: Colors.red);
        return false;
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
        final FirebaseUser currentUser = await _auth.currentUser();
        try {
          await currentUser.linkWithCredential(credential);
          setState(() {
            smsValid = true;
          });
        } on PlatformException catch (e) {
          handleError(e);
          print(e);
        } catch (e) {
          handleError(e);
          print('error: $e');
        }

        print("IS SMS VALID ? $smsValid");
        if (smsValid) {
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
          } on PlatformException catch (e) {
            print(e);
            final errorToast = SnackBar(
                content: Text('Er is iets mis gegaan.. U kan herbeginnen.'));
            _scaffoldKey.currentState.showSnackBar(errorToast);
          } catch (e) {
            //handleError(e);
            setState(() {
              errorMessage = "Probeer opnieuw, foute code..";
            });
            print('Error:$e');
          }
          Navigator.pop(context);
          print("popHier!");
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => Keuze()),
              (Route<dynamic> route) => false);
        } else {
          Toast.show("Er is iets mis gegaan.. U kan herbeginnen.", context,
              duration: Toast.LENGTH_SHORT,
              gravity: Toast.TOP,
              backgroundColor: Colors.red);
          if (currentUser != null) {
            currentUser.delete();
          }
        }
        // print('Ingelogd met : ${gebruiker.user.uid}');
      } catch (e) {
        print('error: $e');
      }
    }
  }

  void gaNaarLogin() {
    Navigator.pop(context);
  }

  bool checkIfEmailExists(emailValue) {
    print("Check...");
    bool bestaat = false;
    try {
      _auth.signInWithEmailAndPassword(
          email: emailValue, password: 'password');
    } catch (signUpError) {
      print("errorSignup!");
      FocusScope.of(context).requestFocus(new FocusNode());
      if (signUpError is PlatformException) {
        if (signUpError.code == 'ERROR_WRONG_PASSWORD') {
          print('E-mail bestaat al!');
          bestaat = true;
          return true;
        }
        if(signUpError.code == 'ERROR_USER_NOT_FOUND'){
          bestaat = false;
          return false;
        }
        
        print("Een ander error  !");
        return true;
      }
      print(signUpError);
      print('returnshit');
      return bestaat;
      
    }
    print("fale");
    return true;

  }

  final _formKey = new GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomPadding: false,
        body: Stack(children: <Widget>[
          ColorFiltered(
              colorFilter: ColorFilter.mode(
                  Colors.white.withOpacity(0.5), BlendMode.srcOver),
              child: Image.asset(
                'assets/images/backgroundLogin.jpg',
                width: size.width,
                height: size.height,
                fit: BoxFit.cover,
              )),
          Column(crossAxisAlignment: CrossAxisAlignment.center, children: <
              Widget>[
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
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        )))),
            // EINDE box met titel
            //BEGIN TEXTVELDEN

            Form(
                key: _formKey,
                child: Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                          padding: EdgeInsets.only(right: 20, left: 20),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Padding(
                                    padding:
                                        EdgeInsets.only(top: 0, bottom: 20.0),
                                    child: TextFormField(
                                      //  autofocus: true,
                                      decoration: InputDecoration(
                                          errorStyle: TextStyle(
                                              fontWeight: FontWeight.w700),
                                          prefixIcon: Icon(
                                            Icons.person,
                                            color: Geel,
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Geel, width: 6),
                                          ),
                                          border: new UnderlineInputBorder(),
                                          errorBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.red, width: 6),
                                          ),
                                          labelText: 'Naam',
                                          hintText: 'E.g Deneubourg'),
                                      validator: (value) => value.isEmpty
                                          ? "Naam moet ingevuld zijn"
                                          : null,

                                      onSaved: (value) => _naam = value,
                                    )),
                                Padding(
                                    padding: EdgeInsets.only(bottom: 20.0),
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                          errorStyle: TextStyle(
                                              fontWeight: FontWeight.w700),
                                          prefixIcon: Icon(
                                            Icons.person_outline,
                                            color: Geel,
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Geel, width: 6),
                                          ),
                                          border: new UnderlineInputBorder(),
                                          errorBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.red, width: 6),
                                          ),
                                          labelText: 'Voornaam',
                                          hintText: 'E.g Yassine'),
                                      validator: (value) => value.isEmpty
                                          ? "Voornaam moet ingevuld zijn"
                                          : null,
                                      onSaved: (value) => _voornaam = value,
                                    )),
                                Padding(
                                    padding: EdgeInsets.only(bottom: 20.0),
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                          errorStyle: TextStyle(
                                              fontWeight: FontWeight.w700),
                                          prefixIcon: Icon(
                                            Icons.alternate_email,
                                            color: Geel,
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Geel, width: 6),
                                          ),
                                          border: new UnderlineInputBorder(),
                                          errorBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.red, width: 6),
                                          ),
                                          labelText: 'Uw e-mail adress',
                                          hintText: 'E.g m.yassine@hotmail.be'),
                                      validator: (value) {
                                        if (value.isEmpty) {
                                          return "E-mail adres moet ingevuld zijn.";
                                        }

                                        if (!RegExp(
                                                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                            .hasMatch(value)) {
                                          return "Geen correcte e-mail adres.";
                                        }

                                        if(checkIfEmailExists(value)){
                                          return "E-mailadres is al gebruikt.";
                                        }
                                        return null;
                                      },
                                      onSaved: (value) => _email = value,
                                    )),
                                Padding(
                                    padding: EdgeInsets.only(bottom: 20.0),
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                          errorStyle: TextStyle(
                                              fontWeight: FontWeight.w700),
                                          prefixIcon: Icon(
                                            Icons.no_encryption,
                                            color: Geel,
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Geel, width: 6),
                                          ),
                                          border: new UnderlineInputBorder(),
                                          errorBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.red, width: 6),
                                          ),
                                          labelText: 'Uw wachtwoord',
                                          hintText: '***'),
                                      obscureText: true,
                                      validator: (value) {
                                        if (value.isEmpty) {
                                          return "Wachtwoord moet ingevuld zijn";
                                        }
                                        if (value.length < 6) {
                                          return "Wachtwoord moet minstens 6 karakters hebben.";
                                        }
                                        return null;
                                      },
                                      onChanged: (value) => _wachtwoord = value,
                                      onSaved: (value) => _wachtwoord = value,
                                    )),
                                Padding(
                                    padding: EdgeInsets.only(bottom: 20.0),
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                          errorStyle: TextStyle(
                                              fontWeight: FontWeight.w700),
                                          prefixIcon: Icon(
                                            Icons.no_encryption,
                                            color: Geel,
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Geel, width: 6),
                                          ),
                                          border: new UnderlineInputBorder(),
                                          errorBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.red, width: 6),
                                          ),
                                          labelText: 'Herhaal je wachtwoord',
                                          hintText: '***'),
                                      obscureText: true,
                                      validator: (value) {
                                        if (value.isEmpty) {
                                          return "Wachtwoord moet ingevuld zijn";
                                        }
                                        if (value != _wachtwoord) {
                                          return "Wachtwoord zijn niet identiek!";
                                        }
                                        if (value.length < 6) {
                                          return "Wachtwoord moet minstens 6 karakters hebben.";
                                        }
                                        return null;
                                      },
                                      onSaved: (value) =>
                                          _herhaalWachtwoord = value,
                                    )),
                              ])),
                    ),
                    Padding(
                        padding: EdgeInsets.only(
                            top: 10.0, bottom: 60, right: 20, left: 20),
                        child: RaisedButton(
                          child: new Text('SCHRIJF JE IN',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          color: Geel,
                          onPressed: () {
                            verifyPhone();
                          },
                        ))
                  ],
                ))),

            //EINDE TEXTVELDEN
          ])
        ]));
  }
}