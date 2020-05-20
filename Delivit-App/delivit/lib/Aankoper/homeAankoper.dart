import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:delivit/Aankoper/kaartAankoper.dart';
import 'package:delivit/Aankoper/overzichtBestellingenAankoper.dart';
import 'package:delivit/Aankoper/productenLijstAankoper.dart';
import 'package:delivit/Bezorger/Drawer.dart';
import 'package:delivit/globals.dart';
import 'package:delivit/main.dart';
import 'package:delivit/portefeuille.dart';
import 'package:delivit/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../keuze.dart';

class HomeAankoper extends StatefulWidget {
  HomeAankoper({Key key, this.title}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() => new _HomeAankoperState();
}

class _HomeAankoperState extends State<HomeAankoper> {
  int _cIndex = 0;
  var gebruikerListener;

  double tabHeight = 50;
  final List<Widget> _children = [
    KaartAankoper(),
    OverzichtBestellingenAankoper()
  ];

  String connectedUserMail;

  Map gebruikerData;

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
      if (this.mounted) {
        setState(() {
          connectedUserMail = user.email;
        });
      }
      int testi = 0;

      gebruikerListener = Firestore.instance
          .collection('Users')
          .document(user.email)
          .snapshots();
      gebruikerListener.listen((e) {
        testi++;
        print(testi.toString() + "AAANKOPER");
        print(" TJR DISO aankoper");
        if (this.mounted) {
          setState(() {
            gebruikerData = e.data;
          });
        }
      });
    } else {
      FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(context, SlideTopRoute(page: Main()));
    }
  }

  @override
  void dispose() {
    print('LA ON DISPOSE LE aankoper HOME');
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

//TODO: CHANGER DRAWER PAS DE STRAMBUILDER
  @override
  Widget build(BuildContext context) {
    //_getData();
    //Size size = MediaQuery.of(context).size;
    return new Scaffold(
      endDrawer: Drawer(child: DrawerNav()),
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
      ),
      body: _children[_cIndex],
      floatingActionButton: Container(
          width: 85.0,
          child: FittedBox(
              child: FloatingActionButton(
            heroTag: "buttonGaNaarProductenLijst",
            shape: CircleBorder(side: BorderSide(color: Geel)),
            backgroundColor: Colors.white,
            elevation: 1,
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
              Icons.add,
              color: Geel,
            ),
          ))),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
    );
  }
}
