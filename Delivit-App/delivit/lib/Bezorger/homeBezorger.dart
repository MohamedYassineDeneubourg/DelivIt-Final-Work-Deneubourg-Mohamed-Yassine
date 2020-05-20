import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:delivit/Bezorger/Drawer.dart';
import 'package:delivit/Bezorger/kaartBezorger.dart';
import 'package:delivit/Bezorger/overzichtBesteldeBestellingenBezorger.dart';
import 'package:delivit/globals.dart';
import 'package:delivit/keuze.dart';
import 'package:delivit/main.dart';
import 'package:delivit/portefeuille.dart';
import 'package:delivit/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'overzichtBestellingenBezorger.dart';

class HomeBezorger extends StatefulWidget {
  HomeBezorger({Key key, this.title}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() => new _HomeBezorgerState();
}

class _HomeBezorgerState extends State<HomeBezorger> {
  int _cIndex = 0;
  double tabHeight = 50;
  Map gebruikerData;
  final List<Widget> _children = [
    KaartBezorger(),
    TabBarView(children: [
      OverzichtBestellingenBezorger(),
      OverzichtBesteldeBestellingenBezorger()
    ]),
  ];

  String connectedUserMail;
  void _incrementTab(index) {
    if (this.mounted) {
      setState(() {
        _cIndex = index;
      });
    }
  }

  void getCurrentUser() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    print(user);
    if (user != null) {
      print("User is connected!");
      if (this.mounted) {
        setState(() {
          connectedUserMail = user.email;
        });
      }
      int testi = 0;
      Firestore.instance
          .collection('Users')
          .document(user.email)
          .snapshots()
          .listen((e) {
        testi++;
        print(testi.toString() + "BEZORGER");
        if (this.mounted) {
          setState(() {
            gebruikerData = e.data;
          });
        }
        print("HOME BEZORGER TJR ACTIF");
      });
    } else {
      FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(context, SlideTopRoute(page: Main()));
    }
  }

  @override
  void dispose() {
    print('LA ON DISPOSE LE BEZORGER HOME');
    super.dispose();
  }

  @override
  void initState() {
    if (Platform.isIOS) {
      tabHeight = 75.0;
    }
    getCurrentUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //_getData();
    //Size size = MediaQuery.of(context).size;
    return new DefaultTabController(
        length: 2,
        child: Scaffold(
          endDrawer: Drawer(child: DrawerNav()),
          appBar: new AppBar(
            bottom: this._cIndex == 1
                ? TabBar(
                    indicatorColor: Geel,
                    labelColor: Geel,
                    unselectedLabelColor: GrijsDark,
                    labelPadding: EdgeInsets.zero,
                    tabs: <Widget>[
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.sync),
                            Text(
                              "TE BEZORGEN",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.check),
                            Text(
                              "BEZORGD",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : null,
            backgroundColor: White,
            textTheme: TextTheme(
                headline6: TextStyle(
                    color: Geel,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    fontFamily: "Montserrat")),
            centerTitle: true,
            title: new Text((() {
              if (this._cIndex == 0) {
                return "OVERZICHT KAART";
              } else if (this._cIndex == 1) {
                return "BESTELLINGEN";
              }

              return "DELIVIT";
            })()),
          ),
          body: _children[_cIndex],
          bottomNavigationBar: CurvedNavigationBar(
            height: tabHeight,
            backgroundColor: Geel,
            animationDuration: Duration(seconds: 1),
            animationCurve: Curves.easeOutCirc,
            items: <Widget>[
              Icon(FontAwesomeIcons.globeEurope, size: 30),
              Icon(FontAwesomeIcons.dolly, size: 24),
            ],
            onTap: (index) {
              _incrementTab(index);
            },
          ),
        ));
  }
}
