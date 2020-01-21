import 'package:flutter/material.dart';

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
                                Text("Kies een functie",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 30),
                                    textAlign: TextAlign.center),
                                Text(
                                  "Deze kan je later in je instellingen wijzigen",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              ],
                            )))),
                // EINDE box met titel
                RaisedButton(
                  onPressed: () {
                    final errorToast =
                        SnackBar(content: Text('Er is iets mis gegaan.. U kan herbeginnen.'));
                    _scaffoldKey.currentState.showSnackBar(errorToast);
                  },
                )
              ]))
        ]));
  }
}
