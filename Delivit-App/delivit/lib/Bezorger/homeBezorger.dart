import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:delivit/Bezorger/kaartBezorger.dart';
//import 'package:delivit/Bezorger/overzichtBestellingenBezorger.dart';
//import 'package:delivit/Bezorger/productenLijstBezorger.dart';
import 'package:delivit/colors.dart';
import 'package:delivit/main.dart';
import 'package:delivit/portefeuille.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeBezorger extends StatefulWidget {
  HomeBezorger({Key key, this.title}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() => new _HomeBezorgerState();
}

class _HomeBezorgerState extends State<HomeBezorger> {
  int _cIndex = 0;
  String email;
  double tabHeight = 50;
  final List<Widget> _children = [
    KaartBezorger(),
    //OverzichtBestellingenBezorger()
    KaartBezorger()
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
      setState(() {
        connectedUserMail = user.email;
      });
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
            if (snapshot.hasData) {
              return Column(
                children: <Widget>[
                  UserAccountsDrawerHeader(
                    decoration: BoxDecoration(
                        color: Geel.withOpacity(0.7),
                        image: DecorationImage(
                            colorFilter: ColorFilter.mode(
                                GrijsDark.withOpacity(0.7), BlendMode.srcOver),
                            image: NetworkImage(
                              snapshot.data['ProfileImage'],
                            ),
                            fit: BoxFit.cover)),
                    arrowColor: GrijsDark,
                    otherAccountsPictures: <Widget>[
                      IconButton(
                        icon: Icon(Icons.close, color: GrijsDark),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      )
                    ],
                    currentAccountPicture: CircleAvatar(
                        backgroundColor: White,
                        child: ClipOval(
                            child: Image.network(
                          snapshot.data['ProfileImage'],
                          fit: BoxFit.cover,
                        ))),
                    accountName: new Text(
                        snapshot.data['Voornaam'] + " " + snapshot.data['Naam'],
                        style: TextStyle(
                            color: White,
                            fontWeight: FontWeight.w700,
                            fontSize: 18)),
                    accountEmail: new Text(snapshot.data['Email'],
                        style: TextStyle(color: White)),
                  ),
                  ListTile(
                    leading: Icon(FontAwesomeIcons.userAlt, color: GrijsDark),
                    title: Text(
                      'Profiel',
                      style: TextStyle(color: GrijsDark),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(FontAwesomeIcons.wallet, color: GrijsDark),
                    title: Text('Portefeuille (€' +
                        snapshot.data['Portefeuille'].toString() +
                        ")"),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Portefeuille(),
                              fullscreenDialog: true));
                    },
                  ),
                  ListTile(
                    leading: Icon(FontAwesomeIcons.wrench, color: GrijsDark),
                    title: Text('Instellingen'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(FontAwesomeIcons.solidQuestionCircle,
                        color: GrijsDark),
                    title: Text('Help'),
                    onTap: () {
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
                            "Uitloggen",
                            style: TextStyle(
                              color: White,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () {
                            FirebaseAuth.instance.signOut();
                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Main()));
                            print("uitlogg");
                          },
                          color: GrijsDark.withOpacity(0.7),
                        ),
                      ),
                    ),
                  )
                ],
              );
            } else {
              return Text('Loading');
            }
          },
        ),
      ),
      appBar: new AppBar(
        backgroundColor: White,
        textTheme: TextTheme(
            title: TextStyle(
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
