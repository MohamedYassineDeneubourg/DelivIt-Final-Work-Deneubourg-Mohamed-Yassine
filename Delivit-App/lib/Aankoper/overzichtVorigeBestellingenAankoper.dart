import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/Aankoper/bestellingDetailAankoper.dart';
import 'package:delivit/globals.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class OverzichtVorigeBestellingenAankoper extends StatefulWidget {
  @override
  _OverzichtVorigeBestellingenAankoperState createState() =>
      _OverzichtVorigeBestellingenAankoperState();
}

class _OverzichtVorigeBestellingenAankoperState
    extends State<OverzichtVorigeBestellingenAankoper> {
  List bestellingenLijst = [];
  String connectedUserMail;
  int aantalAanbiedingen;
  StreamSubscription<QuerySnapshot> _getFirebaseSubscription;
  void getCurrentUser() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    if (user != null) {
      setState(() {
        connectedUserMail = user.email;
      });
      aantalAanbiedingen = 0;
      _getFirebaseSubscription = Firestore.instance
          .collection('Commands')
          .where("AankoperEmail", isEqualTo: user.email)
          .where("BestellingStatus", whereIn: ["GEANNULEERD", "BEZORGD"])
          .snapshots()
          .listen((e) {
            List list = e.documents;
            list.sort((a, b) => a.data['BezorgDatumEnTijd']
                .compareTo(b.data['BezorgDatumEnTijd']));

            if (this.mounted) {
              setState(() {
                bestellingenLijst = list.reversed.toList();
                connectedUserMail = user.email;
              });
            }
          });
    }
  }


  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return ((bestellingenLijst.length > 0))
        ? Padding(
            padding: const EdgeInsets.only(top: 20, right: 15, left: 15),
            child: Scaffold(
                body: new Container(
              height: size.height * 0.80,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  (aantalAanbiedingen == 0)
                      ? Container()
                      : Container(
                          margin: EdgeInsets.only(bottom: 15),
                          padding: EdgeInsets.only(top: 5, bottom: 5),
                          decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(50)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.assignment_late,
                                size: 23,
                              ),
                              Text(
                                  "  " +
                                      aantalAanbiedingen.toString() +
                                      "  Aanbieding(en)",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: bestellingenLijst.length,
                      itemBuilder: (_, index) {
                        var bestelling = bestellingenLijst[index];
                        String bestellingStatus =
                            bestelling['BestellingStatus'];
                        String datum = new DateFormat.d()
                                .format(
                                    bestelling['BezorgDatumEnTijd'].toDate())
                                .toString() +
                            "/" +
                            DateFormat.M()
                                .format(
                                    bestelling['BezorgDatumEnTijd'].toDate())
                                .toString() +
                            "/" +
                            DateFormat.y()
                                .format(
                                    bestelling['BezorgDatumEnTijd'].toDate())
                                .toString();

                        String tijd = new DateFormat.Hm()
                            .format(bestelling['BezorgDatumEnTijd'].toDate())
                            .toString();

                        return Card(
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                  color: bestelling != null
                                      ? (bestellingStatus ==
                                              "AANBIEDING GEKREGEN")
                                          ? Colors.orange
                                          : GrijsLicht
                                      : GrijsLicht),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    SlideTopRoute(
                                        page: BestellingDetailAankoper(
                                            bestellingId:
                                                bestelling.documentID)));
                              },
                              trailing: getIconAankoper(bestellingStatus),
                              title: Text("Bestelling: " + datum + " - " + tijd,
                                  style: TextStyle(
                                      color: (bestellingStatus == "BEZORGD" ||
                                              bestellingStatus == "GEANNULEERD")
                                          ? GrijsMidden
                                          : Colors.black,
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                bestellingStatus,
                                style: TextStyle(
                                    color: (bestellingStatus == "BEZORGD" ||
                                            bestellingStatus == "GEANNULEERD")
                                        ? GrijsDark
                                        : Colors.black),
                              ),
                            ));
                      },
                    ),
                  )
                ],
              ),
            )),
          )
        : (bestellingenLijst == null)
            ? Container(
                child: SpinKitDoubleBounce(
                  color: Geel,
                  size: 100,
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(right: 40.0, left: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Lottie.asset('assets/Animations/empty.json'),
                    Text(
                      "Je hebt nog geen bestellingen gemaakt. \n Je kan nu een nieuwe aanmaken! ",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
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
    print("init!");
    getCurrentUser();
    setState(() {});

    super.initState();
  }
}
