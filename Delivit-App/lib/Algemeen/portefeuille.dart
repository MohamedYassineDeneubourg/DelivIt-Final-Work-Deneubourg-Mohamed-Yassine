import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/globals.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:toast/toast.dart';

class Portefeuille extends StatefulWidget {
  @override
  _PortefeuilleState createState() => _PortefeuilleState();
}

class _PortefeuilleState extends State<Portefeuille> {
  List portefeuilleHistoriek = [];
  String connectedUserMail;
  Map gebruikerData;
  double geldToevoegen = 5.00;
  var _scaffoldKey = new GlobalKey<ScaffoldState>();
  StreamSubscription _getFirebaseSubscription;
  ScrollController _scrollController = new ScrollController();

  String serverUrl = "https://delivitapp.herokuapp.com/payment";

  @override
  void dispose() {
    if (_getFirebaseSubscription != null) {
      _getFirebaseSubscription.cancel();
    }
    super.dispose();
  }

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  _scrollDown(BuildContext context) {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(MediaQuery.of(context).size.height);
    }
  }

  void getCurrentUser() async {
    final FirebaseUser userData = await FirebaseAuth.instance.currentUser();
    if (userData != null) {
      setState(() {
        connectedUserMail = userData.email;
      });
      _getData();
    }
  }

  void portefeuilleAanvullen() {
    bool isLoading = false;
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0))),
              title: new Text(
                "Portefeuille aanvullen",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: isLoading
                  ? Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: SpinKitDoubleBounce(
                          color: Geel,
                          size: 30,
                        ),
                      )
                    ])
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text("Kies hieronder hoeveel geld je wilt storten."),
                        Padding(
                          padding: const EdgeInsets.only(top: 25, bottom: 25.0),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                IconButton(
                                  icon: Icon(
                                    Icons.remove_circle,
                                    size: 35,
                                  ),
                                  onPressed: () {
                                    if (geldToevoegen > 5) {
                                      setState(() {
                                        geldToevoegen = geldToevoegen - 5;
                                      });
                                    }
                                  },
                                ),
                                Text(
                                  "€ " + geldToevoegen.toString(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 30),
                                ),
                                IconButton(
                                    icon: Icon(
                                      Icons.add_circle,
                                      color: Geel,
                                      size: 35,
                                    ),
                                    onPressed: () {
                                      if (geldToevoegen < 100) {
                                        setState(() {
                                          geldToevoegen = geldToevoegen + 5;
                                        });
                                      }
                                    }),
                              ]),
                        ),
                      ],
                    ),
              actions: <Widget>[
                isLoading
                    ? null
                    : ButtonTheme(
                        minWidth: 400.0,
                        child: FlatButton(
                          color: isLoading ? GrijsDark : Geel,
                          child: new Text(
                            "BEVESTIG",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            setState(() {
                              isLoading = true;
                            });
                            betalenViaBancontact();
                          },
                        )),
                isLoading
                    ? null
                    : ButtonTheme(
                        minWidth: 400.0,
                        child: FlatButton(
                          color: GrijsDark,
                          child: new Text(
                            "ANNULEREN",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ))
              ],
            );
          });
        });
  }

  _getData() {
    var reference = Firestore.instance
        .collection("Users")
        .document(connectedUserMail)
        .snapshots();

    _getFirebaseSubscription = reference.listen((data) {
      if (this.mounted) {
        setState(() {
          // //print("Refreshed");
          gebruikerData = data.data;
          ////print(data.data);
          portefeuilleHistoriek = []
            ..addAll(data.data['PortefeuilleHistoriek']);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown(context));

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
          backgroundColor: White,
          textTheme: TextTheme(
              headline6: TextStyle(
                  color: Geel,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  fontFamily: "Montserrat")),
          centerTitle: true,
          title: Text("PORTEFEUILLE")),
      body: (gebruikerData != null)
          ? Container(
              padding: new EdgeInsets.only(
                  top: 8.0, bottom: 20, right: 15, left: 15),
              child: new Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Padding(
                      padding: EdgeInsets.only(
                        bottom: 15,
                        top: 10,
                      ),
                      child: Column(
                        children: <Widget>[
                          Container(
                              width: size.width,
                              decoration: new BoxDecoration(
                                  color: Geel,
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 1.0,
                                      color: GrijsMidden,
                                      offset: Offset(0.3, 0.3),
                                    ),
                                  ],
                                  borderRadius: new BorderRadius.all(
                                      Radius.circular(10.0))),
                              child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    "€" +
                                        gebruikerData['Portefeuille']
                                            .toStringAsFixed(2),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        fontSize: 50),
                                  ))),
                          Container(
                            height: size.height * 0.40,
                            margin: EdgeInsets.only(top: 10),
                            child: new ListView.builder(
                              controller: _scrollController,
                              reverse: true,
                              itemCount: portefeuilleHistoriek.length,
                              itemBuilder: (context, index) {
                                return Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: ListTile(
                                      dense: true,
                                      onTap: null,
                                      trailing: Text(
                                          portefeuilleHistoriek[index]['Type'] +
                                              " € " +
                                              portefeuilleHistoriek[index]
                                                      ['TotalePrijs']
                                                  .toStringAsFixed(2),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      title: Text(
                                          portefeuilleHistoriek[index]
                                              ['BestellingId'],
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      subtitle: Text(
                                          portefeuilleHistoriek[index]['Datum']
                                              .toString(),
                                          style: TextStyle(
                                              fontWeight: FontWeight.w400,
                                              fontSize: 8)),
                                    ));
                              },
                            ),
                          ),
                        ],
                      )),
                  Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(right: 15.0),
                          child: ButtonTheme(
                            shape: RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(10.0)),
                            padding: const EdgeInsets.all(0.0),
                            child: RaisedButton(
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      new BorderRadius.circular(10.0)),
                              child:
                                  Stack(alignment: Alignment.center, children: <
                                      Widget>[
                                ClipRRect(
                                  child: Image.asset(
                                    'assets/images/geldToevoegen.jpg',
                                    color: Geel.withOpacity(0.75),
                                    colorBlendMode: BlendMode.srcOver,
                                    width: size.width * 0.40,
                                    height: size.width * 0.40,
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10.0)),
                                ),
                                Center(
                                    child: Column(
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.only(top: 20.0),
                                      child: Text(
                                        "Portefeuille",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            fontSize: 20,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 10.0,
                                                color: Colors.black,
                                                offset: Offset(3.0, 3.0),
                                              ),
                                            ]),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Text(
                                      "Aanvullen",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          fontSize: 22,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 10.0,
                                              color: Colors.black,
                                              offset: Offset(3.0, 3.0),
                                            ),
                                          ]),
                                      textAlign: TextAlign.center,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Icon(
                                        FontAwesomeIcons.arrowCircleUp,
                                        color: White,
                                        size: 30,
                                      ),
                                    )
                                  ],
                                ))
                              ]),
                              onPressed: portefeuilleAanvullen,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 15.0),
                          child: ButtonTheme(
                            shape: RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(12.0)),
                            padding: const EdgeInsets.all(0.0),
                            child: RaisedButton(
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      new BorderRadius.circular(20.0)),
                              child:
                                  Stack(alignment: Alignment.center, children: <
                                      Widget>[
                                ClipRRect(
                                  child: Image.asset(
                                    'assets/images/geldAanvragen.jpg',
                                    color: GrijsMidden.withOpacity(0.50),
                                    colorBlendMode: BlendMode.srcOver,
                                    width: size.width * 0.40,
                                    height: size.width * 0.40,
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10.0)),
                                ),
                                Center(
                                    child: Column(
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.only(top: 20.0),
                                      child: Text(
                                        "€" +
                                            gebruikerData['Portefeuille']
                                                .toStringAsFixed(2),
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            fontSize: 20,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 10.0,
                                                color: Colors.black,
                                                offset: Offset(3.0, 3.0),
                                              ),
                                            ]),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Text(
                                      "Afhalen",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          fontSize: 22,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 10.0,
                                              color: Colors.black,
                                              offset: Offset(3.0, 3.0),
                                            ),
                                          ]),
                                      textAlign: TextAlign.center,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Icon(
                                        FontAwesomeIcons.arrowCircleDown,
                                        color: White,
                                        size: 30,
                                      ),
                                    )
                                  ],
                                ))
                              ]),
                              onPressed: () {
                                Toast.show(
                                    "Je gaat je geld in de komende dagen ontvangen.",
                                    context,
                                    textColor: Black,
                                    duration: Toast.LENGTH_LONG,
                                    gravity: Toast.BOTTOM,
                                    backgroundColor: GrijsMidden);
                              },
                            ),
                          ),
                        )
                      ]),
                ],
              ))
          : Container(
              child: SpinKitDoubleBounce(
                color: Geel,
                size: 100,
              ),
            ),
    );
  }

  betalenViaBancontact() {
    if (serverUrlGlobals != null) {
      serverUrl = serverUrlGlobals;
    }

    FlutterWebBrowser.openWebPage(
        url: serverUrl +
            "?delivitemail=" +
            connectedUserMail +
            "&amount=" +
            (geldToevoegen * 100).toString(),
        androidToolbarColor: Geel);
    Navigator.pop(context);

    /* launch(
      serverUrl +
          "?delivitemail=" +
          connectedUserMail +
          "&amount=" +
          (geldToevoegen * 100).toString(),
    ); */
  }
}
