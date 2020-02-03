import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/Aankoper/bestellingDetailAankoper.dart';
import 'package:delivit/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class OverzichtBestellingenAankoper extends StatefulWidget {
  @override
  _OverzichtBestellingenAankoperState createState() =>
      _OverzichtBestellingenAankoperState();
}

class _OverzichtBestellingenAankoperState
    extends State<OverzichtBestellingenAankoper> {
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
          .where("AankoperEmail", isEqualTo: connectedUserMail)
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

            case ("ONDERWEG"):
              return Icon(
                Icons.directions_bike,
                size: 30,
                color: Geel,
              );
              break;

            case ("GELEVERD"):
              return Icon(
                Icons.assignment_turned_in,
                size: 30,
                color: Geel,
              );
              break;

            default:
              return Icon(
                Icons.queue_play_next,
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
                          color: (bestelling['BestellingStatus'] ==
                                  "AANBIEDING GEKREGEN")
                              ? Geel
                              : GrijsLicht),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => BestellingDetailAankoper(
                                      bestellingId: bestelling.documentID,
                                    )));
                      },
                      trailing: getIcon(bestelling['BestellingStatus']),
                      title: Text("Bestelling: " + datum + " - " + tijd,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(bestelling['BestellingStatus']),
                    ));
              },
            )),
          );
        } else {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 40.0, left: 40),
              child: Text(
                "Je hebt nog geen bestellingen gemaakt. Je kan nu een nieuwe aanmaken! ",
                textAlign: TextAlign.center,
              ),
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