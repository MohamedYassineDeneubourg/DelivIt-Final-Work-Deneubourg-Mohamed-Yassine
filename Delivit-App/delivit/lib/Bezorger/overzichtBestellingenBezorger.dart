import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/Bezorger/bestellingDetailBezorger.dart';
import 'package:delivit/globals.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  Widget build(BuildContext context) {
    return new StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection('Commands')
          .where("BezorgerEmail", isEqualTo: connectedUserMail)
          .orderBy("BezorgDatumEnTijd", descending: true)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        getIcon(status) {
          switch (status) {
            case ("AANVRAAG"):
              return Icon(
                FontAwesomeIcons.question,
                size: 30,
                color: Colors.orange,
              );
              break;

            case ("AANBIEDING GEKREGEN"):
              return Icon(
                Icons.notification_important,
                size: 30,
                color: Colors.green,
              );
              break;

            case ("PRODUCTEN VERZAMELEN"):
              return Icon(
                Icons.shopping_cart,
                size: 30,
                color: Geel,
              );
              break;

            case ("ONDERWEG"):
              return Icon(
                Icons.directions_bike,
                size: 30,
                color: Geel,
              );
              break;

            case ("BEZORGD"):
              return Icon(
                Icons.check,
                size: 30,
                color: Geel,
              );
              break;

            case ("GEANNULEERD"):
              return Icon(
                Icons.delete,
                size: 30,
                color: Colors.redAccent.withOpacity(0.7),
              );
              break;

            default:
              return Icon(
                Icons.help_outline,
                size: 30,
                color: Geel,
              );
              break;
          }
        }

        if (snapshot.hasData && snapshot.data.documents.length != 0) {
          return Padding(
            padding: const EdgeInsets.only(top: 20.0, right: 15, left: 15),
            child: Scaffold(
                body: ListView.builder(
              itemCount: snapshot.data.documents.length,
              itemBuilder: (_, index) {
                var bestelling = snapshot.data.documents[index];
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
                      trailing: getIcon(bestellingStatus),
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
              },
            )),
          );
        } else {
          return Padding(
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
      },
    );
  }

  @override
  void initState() {
    print("init!");
    getCurrentUser();
    setState(() {});

    super.initState();
  }
}
