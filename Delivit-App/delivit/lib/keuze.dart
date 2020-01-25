import 'package:delivit/Aankoper/homeAankoper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:icon_shadow/icon_shadow.dart';

import 'colors.dart';

class Keuze extends StatefulWidget {
  @override
  _KeuzeState createState() => _KeuzeState();
}

class _KeuzeState extends State<Keuze> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        key: _scaffoldKey,
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
              child: ListView(children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                //Box met titel BEGIN
                Padding(
                    padding: EdgeInsets.only(top: 50),
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
                            padding: EdgeInsets.only(
                                bottom: 20, top: 20, right: 15, left: 15),
                            child: Column(
                              children: <Widget>[
                                Text("Kies een functie",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 30),
                                    textAlign: TextAlign.center),
                                Text(
                                    "Dit kan je later in je instellingen wijzigen",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16),
                                    textAlign: TextAlign.center),
                              ],
                            )))),

                // EINDE box met titel
                Padding(
                  padding: EdgeInsets.only(top: 50, right: 20.0, left: 20.0),
                  child: ButtonTheme(
                    minWidth: size.width * 0.90,
                    height: 100.0,
                    padding: EdgeInsets.all(0),
                    child: RaisedButton(
                      shape: RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(10.0)),
                      child:
                          Stack(alignment: Alignment.center, children: <Widget>[
                        ColorFiltered(
                            colorFilter: ColorFilter.mode(
                                Geel.withOpacity(0.5), BlendMode.srcOver),
                            child: ClipRRect(
                              child: Image.asset(
                                'assets/images/aankoperChoice.png',
                                width: size.width,
                                height: size.height / 3.5,
                                fit: BoxFit.cover,
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.0)),
                            )),
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
                          child: Stack(alignment: Alignment.center, children: <
                              Widget>[
                            ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                    Geel.withOpacity(0.5), BlendMode.srcOver),
                                child: ClipRRect(
                                  child: Image.asset(
                                    'assets/images/bezorgerChoice.png',
                                    width: size.width,
                                    height: size.height / 3.5,
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10.0)),
                                )),
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
                                  padding: EdgeInsets.only(right: 20, left: 20),
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
          ]))
        ]));
  }

  Future<void> aankoperGekozen() async {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeAankoper()),
        (Route<dynamic> route) => false);
  }

  void bezorgerGekozen() {
    FirebaseAuth.instance.signOut();
  }
}
