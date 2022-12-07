import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/Bezorger/bestellingDetailBezorger.dart';
import 'package:delivit/globals.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class OverzichtBestellingenBezorger extends StatefulWidget {
  @override
  _OverzichtBestellingenBezorgerState createState() =>
      _OverzichtBestellingenBezorgerState();
}

class _OverzichtBestellingenBezorgerState
    extends State<OverzichtBestellingenBezorger> {
  List bestellingenLijst = [];
  String connectedUserMail;
  StreamSubscription<QuerySnapshot> _getFirebaseSubscription;

  void getCurrentUser() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    print(user);
    if (user != null) {
      _getFirebaseSubscription = Firestore.instance
          .collection('Commands')
          .where("BezorgerEmail", isEqualTo: user.email)
          .where("BestellingStatus", whereIn: [
            "PRODUCTEN VERZAMELEN",
            "BESTELLING CONFIRMATIE",
            "ONDERWEG"
          ])
          // .orderBy("BezorgDatumEnTijd", descending: true)
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
    print(bestellingenLijst.length);
    return ((bestellingenLijst.length > 0)) 
        ? Padding(
            padding: const EdgeInsets.only(top: 20.0, right: 15, left: 15),
            child: Scaffold(
                body: ListView.builder(
              itemCount: bestellingenLijst.length,
              itemBuilder: (_, index) {
                var bestelling = bestellingenLijst[index];
                String bestellingStatus = bestelling['BestellingStatus'];
                String datum = new DateFormat.d()
                        .format(bestelling['BezorgDatumEnTijd'].toDate())
                        .toString() +
                    "/" +
                    DateFormat.M()
                        .format(bestelling['BezorgDatumEnTijd'].toDate())
                        .toString() +
                    "/" +
                    DateFormat.y()
                        .format(bestelling['BezorgDatumEnTijd'].toDate())
                        .toString();

                String tijd = new DateFormat.Hm()
                    .format(bestelling['BezorgDatumEnTijd'].toDate())
                    .toString();
                if (bestellingStatus != "BEZORGD") {
                  return Card(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                            color: bestelling != null
                                ? (bestellingStatus == "AANBIEDING GEKREGEN")
                                    ? Geel
                                    : GrijsLicht
                                : GrijsLicht),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                              context,
                              SlideTopRoute(
                                  page: BestellingDetailBezorger(
                                bestellingId: bestelling.documentID,
                                connectedUserMail: connectedUserMail,
                              )));
                        },
                        trailing: getIconBezorger(bestellingStatus),
                        title: Text("Bestelling: " + datum + " - " + tijd,
                            style: TextStyle(
                                color: (bestellingStatus == "BEZORGD" ||
                                        bestellingStatus == "GEANNULEERD")
                                    ? GrijsDark
                                    : Colors.black,
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          (bestellingStatus == "AANBIEDING GEKREGEN")
                              ? "AANBIEDING GESTUURD"
                              : bestellingStatus,
                          style: TextStyle(
                              color: (bestellingStatus == "BEZORGD" ||
                                      bestellingStatus == "GEANNULEERD")
                                  ? GrijsDark
                                  : Colors.black),
                        ),
                      ));
                } else {
                  return Container();
                }
              },
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
                      "Je hebt nog geen bestellingen genomen. \n Bekijk de interactieve map! ",
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
    getCurrentUser();
    super.initState();
  }
}