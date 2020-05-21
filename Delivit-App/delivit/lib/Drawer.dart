import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/globals.dart';
import 'package:delivit/keuze.dart';
import 'package:delivit/main.dart';
import 'package:delivit/portefeuille.dart';
import 'package:delivit/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DrawerNav extends StatefulWidget {
  DrawerNav({Key key, @required this.modus}) : super(key: key);
  final String modus;

  @override
  _DrawerNavState createState() => _DrawerNavState(
        modus: modus,
      );
}

class _DrawerNavState extends State<DrawerNav> {
  _DrawerNavState({Key key, @required this.modus});
  String modus;
  StreamSubscription _getFirebaseSubscription;
  String connectedUserMail;
  String naarFunctieKeuzeTekst = "WORD BEZORGER";
  Map gebruikerData;
  void getCurrentUser() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    print(user);
    if (user != null) {
      if (this.mounted) {
        setState(() {
          connectedUserMail = user.email;
        });
      }
      _getFirebaseSubscription = Firestore.instance
          .collection('Users')
          .document(user.email)
          .snapshots()
          .listen((e) {
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
    if (_getFirebaseSubscription != null) {
      _getFirebaseSubscription.cancel();
    }
    super.dispose();
  }

  @override
  void initState() {
    getCurrentUser();
    if (modus == "AANKOPER") {
      naarFunctieKeuzeTekst = "WORD BEZORGER";
    } else if (modus == "BEZORGER") {
      naarFunctieKeuzeTekst = "WORD AANKOPER";
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        UserAccountsDrawerHeader(
          margin: EdgeInsets.zero,
          decoration: (gebruikerData != null)
              ? BoxDecoration(
                  color: Geel.withOpacity(0.7),
                  image: DecorationImage(
                      colorFilter: ColorFilter.mode(
                          GrijsDark.withOpacity(0.7), BlendMode.srcOver),
                      image: NetworkImage(gebruikerData['ProfileImage']),
                      fit: BoxFit.cover))
              : null,
          arrowColor: White,
          currentAccountPicture: CircleAvatar(
            backgroundColor: Geel,
            backgroundImage: (gebruikerData != null)
                ? NetworkImage(gebruikerData['ProfileImage'])
                : null,
          ),
          accountName: new Text(
              (gebruikerData != null)
                  ? gebruikerData['Voornaam'] + " " + gebruikerData['Naam']
                  : "",
              style: TextStyle(
                  color: White, fontWeight: FontWeight.w700, fontSize: 18)),
          accountEmail: new Text(
              (gebruikerData != null) ? gebruikerData['Email'] : "",
              style: TextStyle(color: White)),
        ),
        Container(
          margin: EdgeInsets.zero,
          color: GrijsDark,
          child: ListTile(
            leading: Icon(
              Icons.swap_horizontal_circle,
              color: White,
            ),
            dense: true,
            title: Text(
              naarFunctieKeuzeTekst,
              style: TextStyle(color: White, fontWeight: FontWeight.bold),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 11,
              color: White,
            ),
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
        ),
        Divider(
          height: 0,
          color: Geel,
          thickness: 2,
        ),
        Container(
          padding: EdgeInsets.only(top: 40),
          color: White,
          child: ListTile(
            leading: Icon(FontAwesomeIcons.userAlt, color: GrijsMidden),
            title: Text(
              'Profiel',
              style: TextStyle(fontWeight: FontWeight.w600, color: GrijsDark),
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
        ),
        Divider(
          height: 0,
          color: Geel,
          thickness: 0.2,
        ),
        Container(
          color: GrijsLicht.withOpacity(0.2),
          child: ListTile(
            leading: Icon(
              FontAwesomeIcons.wallet,
              color: GrijsMidden,
              size: 22,
            ),
            title: Text(
              (gebruikerData != null)
                  ? 'Portefeuille (€' +
                      gebruikerData['Portefeuille'].toString() +
                      ")"
                  : "Portefeuille",
              style: TextStyle(fontWeight: FontWeight.w600, color: GrijsDark),
            ),
            onTap: () {
              Navigator.push(
                  context,
                  SlideTopRoute(
                    page: Portefeuille(),
                  ));
            },
          ),
        ),
        Divider(
          height: 0,
          color: Geel,
          thickness: 0.2,
        ),
        Container(
          color: White,
          child: ListTile(
            leading: Icon(
              FontAwesomeIcons.facebookMessenger,
              color: GrijsMidden,
              size: 23,
            ),
            title: Text(
              'Berichten',
              style: TextStyle(fontWeight: FontWeight.w600, color: GrijsDark),
            ),
            onTap: () {
              /* Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  ChatPage(isTutu: true),
                                              )); */
            },
          ),
        ),
        Divider(
          height: 0,
          color: Geel,
          thickness: 0.2,
        ),
        Container(
          color: GrijsLicht.withOpacity(0.2),
          child: ListTile(
            leading:
                Icon(FontAwesomeIcons.solidQuestionCircle, color: GrijsMidden),
            title: Text(
              'Help',
              style: TextStyle(fontWeight: FontWeight.w600, color: GrijsDark),
            ),
            onTap: () {
              print('Launch mail..');
              launch(
                  "mailto:contact@delivit.be?subject=HELP:%20Application&body=Hallo%20 DelivIt,");
              Navigator.pop(context);
            },
          ),
        ),
        Expanded(
          flex: MediaQuery.of(context).size.height.toInt(),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: double.infinity,
              height: 70,
              child: FlatButton(
                shape: Border(top: BorderSide(color: Geel, width: 2)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "UITLOGGEN",
                      style: TextStyle(
                        color: White,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(
                      FontAwesomeIcons.signOutAlt,
                      size: 11,
                      color: White,
                    )
                  ],
                ),
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                      context, SlideTopRoute(page: Main()));
                },
                color: GrijsDark,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
