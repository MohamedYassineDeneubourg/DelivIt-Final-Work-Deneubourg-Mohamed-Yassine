import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/colors.dart';
import 'package:delivit/keuze.dart';
import 'package:delivit/loadingScreen.dart';
import 'package:delivit/login.dart';
import 'package:delivit/register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';

import 'package:international_phone_input/international_phone_input.dart';

void main() => runApp(Main());

class Main extends StatefulWidget {
  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> {
  String connectedUserMail;

  void getCurrentUser() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    if (user != null) {
      setState(() {
        connectedUserMail = user.email;
      });
    }
  }

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  redirectGebruiker() {
    if (connectedUserMail != null) {
      return Keuze();
    } else {
      return DelivitHomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Delivit',
        theme: ThemeData(
          fontFamily: "Montserrat",
          primarySwatch: MaterialColor(Geel.value, {
            50: Colors.grey.shade50,
            100: Colors.grey.shade100,
            200: Colors.grey.shade200,
            300: Colors.grey.shade300,
            400: Colors.grey.shade400,
            500: Colors.grey.shade500,
            600: Colors.grey.shade600,
            700: Colors.grey.shade700,
            800: Colors.grey.shade800,
            900: Colors.grey.shade900
          }),
        ),
        debugShowCheckedModeBanner: false,
        home: redirectGebruiker());
    //home: Login());
  }
}

class DelivitHomePage extends StatefulWidget {
  DelivitHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _DelivitHomePageState createState() => _DelivitHomePageState();
}

class _DelivitHomePageState extends State<DelivitHomePage> {
  String phoneNumber;
  String phoneIsoCode;
  String confirmedNumber;
  Color buttonColor = GrijsDark;
  String phoneNo;
  bool isLoading = false;
  String connectedUserMail;
  Animation<double> animation;
  AnimationController animationController;
  void getCurrentUser() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    print(user);
    if (user != null) {
      setState(() {
        connectedUserMail = user.email;
      });
    } else {
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          isLoading = false;
        });
      });
    }
  }

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  void onValidPhoneNumber(
      String number, String internationalizedPhoneNumber, String isoCode) {
    setState(() {
      confirmedNumber = internationalizedPhoneNumber;
    });
  }

  void onPhoneNumberChange(
      String number, String internationalizedPhoneNumber, String isoCode) {
    setState(() {
      phoneNumber = number;
      phoneIsoCode = isoCode;
      if (phoneIsoCode == "BE") {
        phoneNo = "+32" + phoneNumber;
      }
      if (phoneNumber.length >= 9) {
        buttonColor = Geel;
      }else {
        buttonColor = GrijsDark;
      }
    });
  }

  numerExists(phoneNumber) async {
    print(phoneNumber);
    final query = await Firestore.instance
        .collection("Users")
        .where('PhoneNumber', isEqualTo: phoneNumber)
        .getDocuments();
    print(query.documents.length);

    if (query.documents.length == 0) {
      print('Nummer Bestaat niet!');
      setState(() {
        isLoading = false;
      });
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Register(
              phoneNumber: phoneNo,
            ),
          ));

      return null;
    }
    //print('Nummer Bestaat !');
    List<DocumentSnapshot> documents = query.documents;
    documents.forEach((object) {
      print("Nummer bestaat wel");
      print(object.data['Email']);
      String emailVoorLogin = object.data['Email'];
      setState(() {
        isLoading = false;
      });

      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Login(
              email: emailVoorLogin,
            ),
          ));

      return object.data['Email'];
    });
    //return null;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: isLoading
          ? loadingScreen
          : Stack(
              children: <Widget>[
                Image.asset(
                  'assets/images/backgroundLogin.jpg',
                  width: size.width,
                  height: size.height * 0.85,
                  fit: BoxFit.cover,
                ),
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image(
                        image: AssetImage("assets/images/logo.png"),
                        width: size.width * 0.80,
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
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(
                        bottom: size.height * 0.06, right: 20, left: 30),
                    child: Container(
                        decoration: new BoxDecoration(
                            border: Border.all(color: GrijsLicht),
                            color: Colors.white,
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
                            padding: EdgeInsets.only(right: 10, left: 10),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: InternationalPhoneInput(
                                      hintText: "Bv. 486 65 53 74",
                                      errorText: "Foute gsm-nummer..",
                                      onPhoneNumberChange: onPhoneNumberChange,
                                      initialPhoneNumber: phoneNumber,
                                      initialSelection: "BE"),
                                ),
                                IconButton(
                                  enableFeedback: true,
                                  icon: Icon(
                                    FontAwesomeIcons.arrowAltCircleRight,
                                    color: buttonColor,
                                  ),
                                  onPressed: () {
                                    if (phoneIsoCode == "BE") {
                                      if (phoneNo.length > 8) {
                                        Future.delayed(
                                            const Duration(milliseconds: 500),
                                            () {
                                          numerExists(phoneNo);
                                        });
                                      }

                                      print("------");
                                    }
                                  },
                                )
                              ],
                            ))),
                  ),
                )
              ],
            ),
    );
  }
}
