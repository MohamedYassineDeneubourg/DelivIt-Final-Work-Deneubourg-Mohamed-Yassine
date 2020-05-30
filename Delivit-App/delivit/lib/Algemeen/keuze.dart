import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/Aankoper/homeAankoper.dart';
import 'package:delivit/Bezorger/homeBezorger.dart';
import 'package:flutter/material.dart';
import 'package:icon_shadow/icon_shadow.dart';

import 'package:delivit/globals.dart';

class Keuze extends StatefulWidget {
  Keuze({Key key, this.connectedUserMail, this.redirect}) : super(key: key);
  final String connectedUserMail;
  final bool redirect;

  @override
  _KeuzeState createState() => _KeuzeState(
      connectedUserMail: this.connectedUserMail, redirect: this.redirect);
}

class _KeuzeState extends State<Keuze> {
  _KeuzeState(
      {Key key, @required this.connectedUserMail, @required this.redirect});

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String connectedUserMail;
  bool redirect;
  getCurrentUser() {
    if (redirect == null) {
      redirect = false;
    }
    Firestore.instance
        .collection("Users")
        .document(connectedUserMail)
        .get()
        .then((e) {
      if (e != null && redirect) {
        //print(e.data['Functie']);
        if (e.data['Functie'] != null) {
          if (e.data['Functie'] == "Aankoper") {
            aankoperGekozen();
          } else if (e.data['Functie'] == "Bezorger") {
            bezorgerGekozen();
          } else {
            //print("Gebruiker moet zijn functie kiezen.");
          }
        }
      }
      if (this.mounted) {
        setState(() {
          //print("Waiting..");
        });
      }
    });
  }

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomPadding: false,
        body: Center(
            child: ListView(children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              //titel BEGIN
              Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: Container(
                      width: size.width * 0.90,
                      child: Padding(
                          padding: EdgeInsets.only(
                              bottom: 20, top: 10, right: 15, left: 15),
                          child: Column(
                            children: <Widget>[
                              Text("Kies een functie",
                                  style: TextStyle(
                                      color: Geel,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 30),
                                  textAlign: TextAlign.center),
                              Text(
                                  "Dit kan je later in je instellingen wijzigen",
                                  style:
                                      TextStyle(color: GrijsDark, fontSize: 16),
                                  textAlign: TextAlign.center),
                              Container(
                                margin: EdgeInsets.only(top: 10),
                                height: 2,
                                width: 50,
                                color: Geel,
                              )
                            ],
                          )))),
              // EINDE titel
              Padding(
                padding: EdgeInsets.only(top: 20, right: 20.0, left: 20.0),
                child: ButtonTheme(
                  minWidth: size.width * 0.90,
                  height: 100.0,
                  padding: EdgeInsets.all(0),
                  child: RaisedButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(10.0)),
                    child:
                        Stack(alignment: Alignment.center, children: <Widget>[
                      ClipRRect(
                        child: Image.asset(
                          'assets/images/aankoperChoice.png',
                          color: Geel.withOpacity(0.25),
                          colorBlendMode: BlendMode.srcOver,
                          width: size.width,
                          height: size.height / 3.5,
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      ),
                      Center(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Container(
                              child: Center(
                                  child: Text("Aankoper",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 30,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 20.0,
                                              color: Colors.black,
                                              offset: Offset(3.0, 3.0),
                                            ),
                                          ]),
                                      textAlign: TextAlign.center))),
                          Center(
                              child: Padding(
                            padding: EdgeInsets.only(right: 20, left: 20),
                            child: Text(
                              "Je wilt je allerlei boodschappen laten leveren.",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontSize: 16,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10.0,
                                      color: Colors.black,
                                      offset: Offset(3.0, 3.0),
                                    ),
                                  ]),
                              textAlign: TextAlign.center,
                            ),
                          )),
                        ],
                      )),
                    ]),
                    onPressed: aankoperGekozen,
                  ),
                ),
              ),
              Container(
                transform: Matrix4.translationValues(-30.0, -65.0, 0.0),
                child: Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 15.0,
                            color: Colors.black.withOpacity(0.1),
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                      child: IconShadowWidget(
                        Icon(Icons.shopping_cart,
                            color: Colors.white, size: 100),
                        shadowColor: Geel,
                      ),
                    )),
              ),
              Container(
                  transform: Matrix4.translationValues(0.0, -50.0, 0.0),
                  child: Padding(
                    padding: EdgeInsets.only(top: 0, right: 20.0, left: 20.0),
                    child: ButtonTheme(
                      minWidth: size.width * 0.90,
                      height: 100.0,
                      padding: EdgeInsets.all(0),
                      child: RaisedButton(
                        shape: RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(10.0)),
                        child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              ClipRRect(
                                child: Image.asset(
                                  'assets/images/bezorgerChoice.png',
                                  color: Geel.withOpacity(0.25),
                                  colorBlendMode: BlendMode.srcOver,
                                  width: size.width,
                                  height: size.height / 3.5,
                                  fit: BoxFit.cover,
                                ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10.0)),
                              ),
                              Center(
                                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Container(
                                      child: Center(
                                          child: Text("Bezorger",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 30,
                                                  shadows: [
                                                    Shadow(
                                                      blurRadius: 20.0,
                                                      color: Colors.black,
                                                      offset: Offset(3.0, 3.0),
                                                    ),
                                                  ]),
                                              textAlign: TextAlign.center))),
                                  Center(
                                      child: Padding(
                                    padding:
                                        EdgeInsets.only(right: 20, left: 20),
                                    child: Text(
                                      "Je wilt geld maken door boodschappen op tijd te leveren.",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          fontSize: 16,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 10.0,
                                              color: Colors.black,
                                              offset: Offset(3.0, 3.0),
                                            ),
                                          ]),
                                      textAlign: TextAlign.center,
                                    ),
                                  )),
                                ],
                              )),
                            ]),
                        onPressed: bezorgerGekozen,
                      ),
                    ),
                  )),
              Container(
                transform: Matrix4.translationValues(30.0, -115.0, 0.0),
                child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 15.0,
                            color: Colors.black.withOpacity(0.1),
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                      child: IconShadowWidget(
                        Icon(Icons.directions_run,
                            color: Colors.white, size: 100),
                        shadowColor: Geel,
                      ),
                    )),
              ),
            ],
          )
        ])));
  }

  Future<void> aankoperGekozen() async {
    print(connectedUserMail);
    var reference =
        Firestore.instance.collection("Users").document(connectedUserMail);

    reference.updateData({"Functie": "Aankoper"});

    Navigator.pushAndRemoveUntil(context, SlideTopRoute(page: HomeAankoper()),
        (Route<dynamic> route) => false);
  }

  void bezorgerGekozen() {
    var reference =
        Firestore.instance.collection("Users").document(connectedUserMail);

    reference.updateData({"Functie": "Bezorger"});

    Navigator.pushAndRemoveUntil(context, SlideTopRoute(page: HomeBezorger()),
        (Route<dynamic> route) => false);
  }
}
