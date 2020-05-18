import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:delivit/Aankoper/kaartAankoper.dart';
import 'package:delivit/Aankoper/overzichtBestellingenAankoper.dart';
import 'package:delivit/Aankoper/productenLijstAankoper.dart';
import 'package:delivit/globals.dart';
import 'package:delivit/main.dart';
import 'package:delivit/portefeuille.dart';
import 'package:delivit/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  String email;
  double tabHeight = 50;
  final List<Widget> _children = [
    KaartAankoper(),
    OverzichtBestellingenAankoper()
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
      setState(() {
        connectedUserMail = user.email;
      });
    } else {
      FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(context, SlideTopRoute(page: Main()));
    }
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
      drawerScrimColor: Geel.withOpacity(0.3),
      endDrawer: Drawer(
        semanticLabel: "Menu",
        child: StreamBuilder<DocumentSnapshot>(
          stream: Firestore.instance
              .collection('Users')
              .document(connectedUserMail)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            return Column(
              children: <Widget>[
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                      color: Geel.withOpacity(0.7),
                      image: DecorationImage(
                          colorFilter: ColorFilter.mode(
                              GrijsDark.withOpacity(0.7), BlendMode.srcOver),
                          image: (snapshot.hasData)
                              ? NetworkImage(snapshot.data['ProfileImage'])
                              : "",
                          fit: BoxFit.cover)),
                  arrowColor: GrijsDark,
                  otherAccountsPictures: <Widget>[
                    IconButton(
                      icon: Icon(Icons.close, color: White),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    )
                  ],
                  currentAccountPicture: CircleAvatar(
                      backgroundColor: White,
                      child: ClipOval(
                          child: Image.network(
                        (snapshot.hasData) ? snapshot.data['ProfileImage'] : "",
                        fit: BoxFit.cover,
                      ))),
                  accountName: new Text(
                      (snapshot.hasData)
                          ? snapshot.data['Voornaam'] +
                              " " +
                              snapshot.data['Naam']
                          : "",
                      style: TextStyle(
                          color: White,
                          fontWeight: FontWeight.w700,
                          fontSize: 18)),
                  accountEmail: new Text(
                      (snapshot.hasData) ? snapshot.data['Email'] : "",
                      style: TextStyle(color: White)),
                ),
                ListTile(
                  leading: Icon(FontAwesomeIcons.userAlt, color: Geel),
                  title: Text(
                    'Profiel',
                    style: TextStyle(color: GrijsDark),
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        SlideTopRoute(
                          page: Profile(
                            userEmail: connectedUserMail,
                          ),
                        ));
                  },
                ),
                ListTile(
                  leading: Icon(
                    FontAwesomeIcons.wallet,
                    color: Geel,
                    size: 22,
                  ),
                  title: Text((snapshot.hasData)
                      ? 'Portefeuille (€' +
                          snapshot.data['Portefeuille'].toString() +
                          ")"
                      : "Portefeuille"),
                  onTap: () {
                    Navigator.push(
                        context,
                        SlideTopRoute(
                          page: Portefeuille(),
                        ));
                  },
                ),
                ListTile(
                  leading: Icon(
                    FontAwesomeIcons.facebookMessenger,
                    color: Geel,
                    size: 23,
                  ),
                  title: Text('Berichten'),
                  onTap: () {
                    /* Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            ChatPage(isTutu: true),
                                        )); */
                  },
                ),
                ListTile(
                  leading: Icon(Icons.school, color: Geel),
                  title: Text('Bezorger-modus'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                        context,
                        SlideTopRoute(
                            page: Keuze(
                          connectedUserMail: connectedUserMail,
                          redirect: false,
                        )));
                  },
                ),
                ListTile(
                  leading: Icon(FontAwesomeIcons.solidQuestionCircle,
                      color: GrijsDark),
                  title: Text('Help'),
                  onTap: () {
                    print('Launch mail..');
                    launch(
                        "mailto:contact@delivit.be?subject=HELP:%20Application&body=Hallo%20L'équipe%20Hitutu,");
                    Navigator.pop(context);
                  },
                ),
                Expanded(
                  flex: MediaQuery.of(context).size.height.toInt(),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: double.infinity,
                      height: 70,
                      child: FlatButton(
                        child: Text(
                          "Zich Uitloggen",
                          style: TextStyle(
                            color: White,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () {
                          FirebaseAuth.instance.signOut();
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                              context, SlideTopRoute(page: Main()));
                          print("uitlogg");
                        },
                        color: GrijsDark.withOpacity(0.7),
                      ),
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ),
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
            return "OVERZICHT KAART ";
          } else if (this._cIndex == 1) {
            return "Bestellingen";
          }

          return "Chat";
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
          Icon(Icons.list, size: 30),
        ],
        onTap: (index) {
          _incrementTab(index);
        },
      ),
    );
  }
}
