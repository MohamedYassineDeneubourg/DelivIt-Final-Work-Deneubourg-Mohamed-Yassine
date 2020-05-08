import 'package:delivit_web/globals.dart';
import 'package:delivit_web/loadingScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Login extends StatefulWidget {
  Login({Key key, this.email}) : super(key: key);

  final String email;
  @override
  _LoginState createState() => _LoginState(email: email);
}

class _LoginState extends State<Login> {
  String _wachtwoord;
  bool wachtwoordOk = false;
  FirebaseAuth _auth = FirebaseAuth.instance;

  _LoginState({Key key, @required this.email});

  String email;
  bool isLoading = false;
  final _formKey = new GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        floatingActionButton: (MediaQuery.of(context).viewInsets.bottom != 0)
            ? null
            : Padding(
                padding: const EdgeInsets.only(bottom: 60.0),
                child: FloatingActionButton.extended(
                  heroTag: "INSCRIPTION",
                  splashColor: GrijsDark,
                  elevation: 4.0,
                  backgroundColor: White,
                  icon: const Icon(
                    FontAwesomeIcons.check,
                    color: Geel,
                  ),
                  label: Text(
                    "INLOGGEN",
                    style: TextStyle(color: Geel, fontWeight: FontWeight.w800),
                  ),
                  onPressed: () {
                    isWachtwoordFout();
                  },
                ),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: isLoading
            ? loadingScreen
            : SingleChildScrollView(
                child: Stack(children: <Widget>[
                  Image.asset(
                    'assets/images/aankoperChoice.jpg',
                    width: size.width,
                    height: size.height,
                    fit: BoxFit.cover,
                  ),
                  Center(
                    child: Padding(
                        padding: EdgeInsets.only(top: size.height / 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Image(
                              image: AssetImage("assets/images/logo.png"),
                              width: size.width * 0.50,
                            ),
                            Text("Thuis, wat en wanneer je wilt",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10.0,
                                        color: Colors.black,
                                        offset: Offset(3.0, 3.0),
                                      ),
                                    ])),
                            Center(
                              child: Container(
                                  margin:
                                      EdgeInsets.only(top: size.height / 10),
                                  width: size.width * 0.40,
                                  decoration: new BoxDecoration(
                                      color: Geel.withOpacity(0.8),
                                      borderRadius: new BorderRadius.all(
                                          Radius.circular(10.0))),
                                  child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: <Widget>[
                                            Text("Log je in",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 30),
                                                textAlign: TextAlign.center),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 15.0, left: 15),
                                              child: Text(
                                                "Dit moet je maar één keer doen op dit toestel.",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            Form(
                                                key: _formKey,
                                                child: Column(
                                                  children: <Widget>[
                                                    Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                top: 30,
                                                                bottom: 20.0),
                                                        child: TextFormField(
                                                          enabled: false,
                                                          decoration:
                                                              InputDecoration(
                                                                  prefixIcon:
                                                                      Icon(
                                                                    Icons
                                                                        .alternate_email,
                                                                    color: Geel,
                                                                  ),
                                                                  fillColor:
                                                                      Colors
                                                                          .white,
                                                                  filled: true,
                                                                  border:
                                                                      UnderlineInputBorder(
                                                                    borderSide: BorderSide(
                                                                        color:
                                                                            Geel,
                                                                        width:
                                                                            6),
                                                                  ),
                                                                  labelText:
                                                                      email,
                                                                  enabled:
                                                                      false),
                                                        )),
                                                    Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                bottom: 20.0),
                                                        child: TextFormField(
                                                          decoration:
                                                              InputDecoration(
                                                                  errorStyle: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700),
                                                                  prefixIcon:
                                                                      Icon(
                                                                    Icons
                                                                        .no_encryption,
                                                                    color: Geel,
                                                                  ),
                                                                  fillColor:
                                                                      Colors
                                                                          .white,
                                                                  filled: true,
                                                                  focusedBorder:
                                                                      UnderlineInputBorder(
                                                                    borderSide: BorderSide(
                                                                        color:
                                                                            Geel,
                                                                        width:
                                                                            6),
                                                                  ),
                                                                  border:
                                                                      new UnderlineInputBorder(),
                                                                  errorBorder:
                                                                      UnderlineInputBorder(
                                                                    borderSide: BorderSide(
                                                                        color: Colors
                                                                            .red,
                                                                        width:
                                                                            6),
                                                                  ),
                                                                  labelText:
                                                                      'Uw wachtwoord',
                                                                  hintText:
                                                                      '***'),
                                                          obscureText: true,
                                                          validator: (value) {
                                                            if (value.isEmpty) {
                                                              return "Wachtwoord moet ingevuld zijn";
                                                            }
                                                            if (value.length <
                                                                6) {
                                                              return "Wachtwoord moet minstens 6 karakters hebben.";
                                                            }

                                                            if (wachtwoordOk) {
                                                              return "Wachtwoord is niet correct.";
                                                            }
                                                            return null;
                                                          },
                                                          onChanged: (value) =>
                                                              _wachtwoord =
                                                                  value,
                                                          onSaved: (value) =>
                                                              _wachtwoord =
                                                                  value,
                                                        )),
                                                    FlatButton.icon(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      label: Text(
                                                        "Verkeerde e-mailadres",
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: White,
                                                        ),
                                                      ),
                                                      icon: Icon(
                                                        Icons.arrow_back_ios,
                                                        size: 15,
                                                        color: White,
                                                      ),
                                                    )
                                                  ],
                                                ))
                                          ],
                                        ),
                                      ))),
                            ),
                          ],
                        )),
                  )
                ]),
              ));
  }

  isWachtwoordFout() async {
    var loadingContext;
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        loadingContext = context;
        return Container(
          width: 200,
          height: 200,
          alignment: Alignment.center,
          child: SpinKitDoubleBounce(
            color: Geel,
            size: 50,
          ),
        );
      },
    );

    try {
      await _auth.signInWithEmailAndPassword(
          email: email, password: _wachtwoord);
      setState(() {
        this.wachtwoordOk = false;
      });
      //print("SinIn:");
      //print(wachtwoordOk);
    } catch (signUpError) {
      FocusScope.of(context).requestFocus(new FocusNode());
      if (signUpError is PlatformException) {
        if (signUpError.code == 'ERROR_WRONG_PASSWORD') {}
      }
      setState(() {
        wachtwoordOk = true;
      });
      //print("SinIn:");
      //print(wachtwoordOk);
    }
    if (loadingContext != null) {
      Navigator.of(loadingContext).pop();
    }
    //print("pressedè");
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      //print("USER LOGGED IN !");
      Navigator.pop(context);
      //print("popHier!");
      /*  Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Keuze()),
          (Route<dynamic> route) => false); */
      //TODO: HIER NAAR ANDERE PAGINA GAAN
    }
  }
}
