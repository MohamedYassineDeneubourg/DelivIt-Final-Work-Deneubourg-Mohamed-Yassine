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

class OverzichtAanbiedingenBestellingenBezorger extends StatefulWidget {
  @override
  _OverzichtAanbiedingenBestellingenBezorgerState createState() =>
      _OverzichtAanbiedingenBestellingenBezorgerState();
}

class _OverzichtAanbiedingenBestellingenBezorgerState
    extends State<OverzichtAanbiedingenBestellingenBezorger> {
  List bestellingenLijst = [];
  String connectedUserMail;
  StreamSubscription<QuerySnapshot> _getFirebaseSubscription;

  void getCurrentUser() async {
    print("bestelde");
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    if (user != null) {
      _getFirebaseSubscription = Firestore.instance
          .collection('Commands')
          .where("AanbodEmailLijst", arrayContains: user.email)
          .snapshots()
          .listen((e) async {
        List list = e.documents;
        list.sort((a, b) =>
            a.data['BezorgDatumEnTijd'].compareTo(b.data['BezorgDatumEnTijd']));

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
    return ((bestellingenLijst.length > 0))
        ? Padding(
            padding: const EdgeInsets.only(top: 20.0, right: 15, left: 15),
            child: Scaffold(
                body: ListView.builder(
              itemCount: bestellingenLijst.length,
              itemBuilder: (_, index) {
                String bestellingStatus =
                    bestellingenLijst[index]['BestellingStatus'];
                String datum = new DateFormat.d()
                        .format(bestellingenLijst[index]['BezorgDatumEnTijd']
                            .toDate())
                        .toString() +
                    "/" +
                    DateFormat.M()
                        .format(bestellingenLijst[index]['BezorgDatumEnTijd']
                            .toDate())
                        .toString() +
                    "/" +
                    DateFormat.y()
                        .format(bestellingenLijst[index]['BezorgDatumEnTijd']
                            .toDate())
                        .toString();

                String tijd = new DateFormat.Hm()
                    .format(
                        bestellingenLijst[index]['BezorgDatumEnTijd'].toDate())
                    .toString();
                if (bestellingenLijst[index]['BezorgerEmail'] !=
                    connectedUserMail) {
                  return Card(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                            color: bestellingenLijst[index] != null
                                ? (bestellingStatus == "AANBIEDING GEKREGEN")
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
                                  page: BestellingDetailBezorger(
                                bestellingId:
                                    bestellingenLijst[index].documentID,
                                connectedUserMail: connectedUserMail,
                              )));
                        },
                        trailing: (bestellingStatus == "AANBIEDING GEKREGEN")
                            ? getIconBezorger(bestellingStatus)
                            : Icon(Icons.delete_forever),
                        title: Text("Bestelling: " + datum + " - " + tijd,
                            style: TextStyle(
                                color:
                                    (bestellingStatus == "AANBIEDING GEKREGEN")
                                        ? Colors.black
                                        : GrijsDark.withOpacity(0.7),
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            (bestellingStatus == "AANBIEDING GEKREGEN")
                                ? "AANBIEDING GESTUURD"
                                : "GEANNULEERD",
                            style: TextStyle(
                              color: (bestellingStatus == "AANBIEDING GEKREGEN")
                                  ? Colors.black
                                  : GrijsMidden,
                            )),
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
                      "Je hebt nog geen bestellingen bezorgd. \n Bekijk de interactieve map! ",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
  }

  @override
  void dispose() {
    if (_getFirebaseSubscription != null) {
      print("CANCELED!");
      _getFirebaseSubscription.cancel();
    }

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }
}
