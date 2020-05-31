import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:delivit/Bezorger/kaartBezorger.dart';
import 'package:delivit/Bezorger/overzichtAanbiedingenBestellingenBezorger.dart';
import 'package:delivit/Bezorger/overzichtBesteldeBestellingenBezorger.dart';
import 'package:delivit/Functies/chatFunctions.dart';
import 'package:delivit/UI-elementen/Drawer.dart';
import 'package:delivit/globals.dart';
import 'package:delivit/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'overzichtBestellingenBezorger.dart';

class HomeBezorger extends StatefulWidget {
  HomeBezorger({Key key, this.title}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() => new _HomeBezorgerState();
}

class _HomeBezorgerState extends State<HomeBezorger>
    with WidgetsBindingObserver {
  int _cIndex = 0;
  double tabHeight = 50;
  Map gebruikerData;
  final List<Widget> _children = [
    KaartBezorger(),
    TabBarView(children: [
      OverzichtBestellingenBezorger(),
      OverzichtAanbiedingenBestellingenBezorger(),
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
    Size size = MediaQuery.of(context).size;
    return new DefaultTabController(
        length: 3,
        child: Scaffold(
          endDrawer: Drawer(
              child: DrawerNav(
            modus: "BEZORGER",
          )),
          appBar: new AppBar(
            bottom: this._cIndex == 1
                ? TabBar(
                    indicatorColor: Geel,
                    labelColor: Geel,
                    unselectedLabelColor: GrijsDark,
                    labelPadding: EdgeInsets.zero,
                    tabs: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.sync,
                                size: 14,
                              ),
                              AutoSizeText(
                                "TE BEZORGEN",overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.bold,fontSize: (size.aspectRatio > 0.57) ? 10 : 14),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.assignment,
                              size: 14,
                            ),
                            AutoSizeText(
                              "AANBOD",
                              style: TextStyle(fontWeight: FontWeight.bold,fontSize: (size.aspectRatio > 0.57) ? 10 : 14),
                            ),
                          ],
                        ),
                      ), //WESH? LE ADMIN PRIJSLIJST
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.check, size: 14),
                              AutoSizeText(
                                "BEZORGD",
                                style: TextStyle(fontWeight: FontWeight.bold,fontSize: (size.aspectRatio > 0.57) ? 10 : 14),
                              ),
                            ],
                          ),
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
