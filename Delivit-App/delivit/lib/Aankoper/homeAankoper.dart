import 'dart:io';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:delivit/Aankoper/kaartAankoper.dart';
import 'package:delivit/Aankoper/overzichtBestellingenAankoper.dart';
import 'package:delivit/Aankoper/overzichtVorigeBestellingenAankoper.dart';
import 'package:delivit/Aankoper/productenLijstAankoper.dart';
import 'package:delivit/Functies/chatFunctions.dart';
import 'package:delivit/UI-elementen/Drawer.dart';
import 'package:delivit/globals.dart';
import 'package:delivit/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeAankoper extends StatefulWidget {
  HomeAankoper({Key key, this.title}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() => new _HomeAankoperState();
}

class _HomeAankoperState extends State<HomeAankoper>
    with WidgetsBindingObserver {
  int _cIndex = 0;

  double tabHeight = 50;
  final List<Widget> _children = [
    KaartAankoper(),
    TabBarView(children: [
      OverzichtBestellingenAankoper(),
      OverzichtVorigeBestellingenAankoper()
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
    if (user != null) {
      if (this.mounted) {
        setState(() {
          connectedUserMail = user.email;
        });
      }
    } else {
      FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(context, SlideTopRoute(page: Main()));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    checkIfOnline(state, connectedUserMail);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    if (Platform.isIOS) {
      tabHeight = 75.0;
    }
    getCurrentUser();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return new DefaultTabController(
        length: 2,
        child: Scaffold(
          endDrawer: Drawer(
              child: DrawerNav(
            modus: "AANKOPER",
          )),
          appBar: new AppBar(
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
                            Icon(Icons.sync, size: 14),
                            Text(
                              "IN AFWACHTING",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.check,
                              size: 14,
                            ),
                            Text(
                              "VORIGE",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : null,
          ),
          body: _children[_cIndex],
          floatingActionButton: Container(
              width: 85.0,
              child: FittedBox(
                  child: FloatingActionButton(
                heroTag: "buttonGaNaarProductenLijst",
                shape: CircleBorder(side: BorderSide(color: Geel, width: 0.5)),
                backgroundColor: Colors.white,
                elevation: 2,
                onPressed: () {
                  print("PRODUCTENLIJST");
                  Navigator.push(
                    context,
                    SlideTopRoute(
                      page: ProductenLijstAankoper(),
                    ),
                  );
                },
                child: Icon(
                  FontAwesomeIcons.plus,
                  size: 22,
                  color: Geel,
                ),
              ))),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
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
