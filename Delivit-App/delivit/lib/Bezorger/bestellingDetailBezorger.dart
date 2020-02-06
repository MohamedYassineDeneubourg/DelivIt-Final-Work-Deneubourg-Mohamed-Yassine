import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class BestellingDetailBezorger extends StatefulWidget {
  BestellingDetailBezorger({Key key, this.bestellingId, this.connectedUserMail})
      : super(key: key);
  final String bestellingId;
  final String connectedUserMail;

  @override
  _BestellingDetailBezorgerState createState() =>
      _BestellingDetailBezorgerState(
          bestellingId: this.bestellingId,
          connectedUserMail: connectedUserMail);
}

class _BestellingDetailBezorgerState extends State<BestellingDetailBezorger> {
  _BestellingDetailBezorgerState(
      {Key key, @required this.bestellingId, @required this.connectedUserMail});
  String buttonText = "";
  String bestellingId;
  List bestellingLijst = [];
  List aanbodLijst = [];
  String connectedUserMail;
  Map bestelling;
  double totalePrijs = 0.0;
  @override
  void initState() {
    super.initState();
    _getData();
  }

  _getData() async {
    var prijsLijstQuery = Firestore.instance
        .collection("Users")
        .document(connectedUserMail)
        .snapshots();
    Map prijsLijst = {};
    prijsLijstQuery.listen((userData) {
      // print('Get prijslijst...');

      prijsLijst = userData['PrijsLijstBezorger'];
      var reference = Firestore.instance
          .collection("Commands")
          .document(bestellingId)
          .snapshots();

      reference.listen((data) {
        if (this.mounted) {
          setState(() {
            // print("Refreshed");
            bestelling = data.data;
            List bestellingLijstDatabase = data.data['BestellingLijst'];
            //print(data.data);
            bestellingLijst = [];
            bestellingLijstDatabase.forEach((bestelling) {
              String productId = bestelling['ProductID'];
              var productObject = {
                "ProductID": productId,
                "Aantal": bestelling['Aantal'],
                "ProductTitel": bestelling["ProductTitel"],
                "ProductAveragePrijs": bestelling['ProductAveragePrijs'],
                "ProductImage": bestelling['ProductImage']
              };
              if (prijsLijst.containsKey(bestelling['ProductID'])) {
                productObject['ProductAveragePrijs'] = prijsLijst[productId];
                // print(prijsLijst[productId]);
                //print("Contains!");
              }

              bestellingLijst.add(productObject);
            });
            //bestellingLijst = []..addAll(data.data['BestellingLijst']);
          });

          if (bestelling['BestellingStatus'] == "AANBIEDING GEKREGEN") {
            bestelling['AanbodLijst'].forEach((aanbod) {
              double distanceInMeters;
              Geolocator()
                  .getCurrentPosition(
                      desiredAccuracy: LocationAccuracy.bestForNavigation)
                  .then((e) async {
                distanceInMeters = await Geolocator().distanceBetween(
                    bestelling['AdresPosition']['latitude'],
                    bestelling['AdresPosition']['longitude'],
                    e.latitude,
                    e.longitude);

                var reference = Firestore.instance
                    .collection("Users")
                    .document(aanbod['EmailBezorger'])
                    .get();

                reference.then((data) {
                  // print(data);
                  //  print(distanceInMeters);
                  Map bezorgerMap = {
                    "EmailBezorger": aanbod['EmailBezorger'],
                    "NaamVoornaam":
                        data.data["Naam"] + " " + data.data["Voornaam"],
                    "Ranking": 2.5,
                    "ProfileImage": data.data['ProfileImage'],
                    "Position": data.data['Position'],
                    "TotaleAanbodPrijs": aanbod['TotaleAanbodPrijs'],
                    "RatingScore": data.data['RatingScore'],
                    "Distance": distanceInMeters / 1000
                  };

                  setState(() {
                    aanbodLijst.add(bezorgerMap);
                  });
                });
              });
            });
          }
        }
      });
    });
  }

  getDatum() {
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

    return datum + " - " + tijd;
  }

  accepteerAanbod(bezorgerMap) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text(
              "Aanbieding accepteren",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
              CircleAvatar(
                  backgroundColor: White,
                  child: ClipOval(
                      child: Image.network(
                    bezorgerMap['ProfileImage'],
                  ))),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text("Wil je " +
                    bezorgerMap['NaamVoornaam'] +
                    " kiezen om je bestelling te bezorgen tegen € " +
                    bezorgerMap['TotaleAanbodPrijs'].toString() +
                    "?"),
              )
            ]),
            actions: <Widget>[
              ButtonTheme(
                  minWidth: 400.0,
                  child: FlatButton(
                    color: Geel,
                    child: new Text(
                      "JA",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      // GEKOZEN!!
                    },
                  )),
              ButtonTheme(
                  minWidth: 400.0,
                  child: FlatButton(
                    color: GrijsDark,
                    child: new Text(
                      "NEEN",
                      style:
                          TextStyle(color: White, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ))
            ],
          );
        });
  }

  getStatusWidget(status) {
    Size size = MediaQuery.of(context).size;
    switch (status) {
      case ("AANVRAAG"):
        return Padding(padding: EdgeInsets.all(1));
        return Container(
            width: size.width,
            decoration: new BoxDecoration(
                color: GrijsLicht,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 1.0,
                    color: GrijsMidden,
                    offset: Offset(0.3, 0.3),
                  ),
                ],
                borderRadius: new BorderRadius.all(Radius.circular(10.0))),
            child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 0, bottom: 20),
                      child: SpinKitDoubleBounce(
                        color: Geel,
                        size: 30,
                      ),
                    ),
                    Text(
                      "Je bestelling is gemaakt en werd aan de nabije bezorgers gestuurd. Je zal binnenkort aanbiediengen krijgen en zo snel mogelijk bezorgd worden..",
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )));

        break;

      case ("AANBIEDING GEKREGEN"):
        return Container(
            width: size.width,
            decoration: new BoxDecoration(
                color: GrijsLicht,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 1.0,
                    color: GrijsMidden,
                    offset: Offset(0.3, 0.3),
                  ),
                ],
                borderRadius: new BorderRadius.all(Radius.circular(10.0))),
            child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: <Widget>[
                    Text(
                      "AANBIEDINGEN",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "Accepteer één aanbod",
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    Container(
                      height: size.height * 0.25,
                      child: new ListView.builder(
                        itemCount: aanbodLijst.length,
                        itemBuilder: (context, index) {
                          return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: ListTile(
                                onTap: () {
                                  accepteerAanbod(aanbodLijst[index]);
                                },
                                trailing: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Text(
                                        "€" +
                                            aanbodLijst[index]
                                                    ['TotaleAanbodPrijs']
                                                .toStringAsFixed(2),
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                        aanbodLijst[index]['Distance']
                                                .toStringAsFixed(1) +
                                            "Km",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))
                                  ],
                                ),
                                leading: Image.network(
                                  aanbodLijst[index]['ProfileImage'],
                                  height: 40,
                                ),
                                title: Text(aanbodLijst[index]['NaamVoornaam'],
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: RatingBarIndicator(
                                  rating: aanbodLijst[index]['RatingScore'],
                                  itemBuilder: (context, index) => Icon(
                                    Icons.star,
                                    color: GrijsDark,
                                  ),
                                  itemCount: 5,
                                  itemSize: 20.0,
                                  direction: Axis.horizontal,
                                ),
                              ));
                        },
                      ),
                    )
                  ],
                )));
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

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
          backgroundColor: White,
          textTheme: TextTheme(
              title: TextStyle(
                  color: Geel,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  fontFamily: "Montserrat")),
          centerTitle: true,
          title: Column(
            children: <Widget>[
              Text("BESTELLING"),
              Text(
                bestellingId,
                style: TextStyle(fontSize: 12, color: GrijsDark),
              ),
            ],
          )),
      body: (bestelling != null)
          ? Container(
              padding: new EdgeInsets.only(
                  top: 8.0, bottom: 20, right: 15, left: 15),
              child: !checkAanbod()
                  ? new Column(
                      children: <Widget>[
                        Padding(
                            padding: EdgeInsets.only(
                              bottom: 15,
                              top: 10,
                            ),
                            child: Container(
                                decoration: new BoxDecoration(
                                    color: Geel,
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 1.0,
                                        color: GrijsMidden,
                                        offset: Offset(0.3, 0.3),
                                      ),
                                    ],
                                    borderRadius: new BorderRadius.all(
                                        Radius.circular(10.0))),
                                child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Column(
                                      children: <Widget>[
                                        Text(getDatum(),
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 30)),
                                        Text(
                                          bestelling['Adres'],
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              fontSize: 16),
                                        ),
                                        Divider(
                                          color: White,
                                          thickness: 2,
                                        ),
                                        Text(
                                          "Status:",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              fontSize: 16),
                                        ),
                                        Text(
                                          bestelling['BestellingStatus'],
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 26,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    )))),
                        Container(
                          height: size.height * 0.43,
                          child: new ListView.builder(
                            itemCount: bestellingLijst.length,
                            itemBuilder: (context, index) {
                              return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: ListTile(
                                    onTap: null,
                                    trailing: Text(
                                        "€ " +
                                            (bestellingLijst[index]['Aantal'] *
                                                    bestellingLijst[index]
                                                        ['ProductAveragePrijs'])
                                                .toStringAsFixed(2),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    leading: Image.network(
                                      bestellingLijst[index]['ProductImage'],
                                      height: 40,
                                    ),
                                    title: Text(
                                        bestellingLijst[index]['Aantal']
                                                .toString() +
                                            "x : " +
                                            bestellingLijst[index]
                                                ['ProductTitel'],
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                        "€ " +
                                            bestellingLijst[index]
                                                    ['ProductAveragePrijs']
                                                .toStringAsFixed(2),
                                        style: TextStyle(
                                            fontWeight: FontWeight.w400)),
                                  ));
                            },
                          ),
                        ),
                        Column(children: getTotalePrijsWidget()),
                        getStatusWidget(bestelling['BestellingStatus'])
                      ],
                    )
                  : Column(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height * 0.30,
                              bottom: 20),
                          child: SpinKitDoubleBounce(
                            color: Geel,
                            size: 30,
                          ),
                        ),
                        Text(
                          "Je aanbod werd gestuurd, eventjes wachten op de bevestiging..",
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                              fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        Column(children: getTotalePrijsWidget()),
                      ],
                    ))
          : Container(
              child: SpinKitDoubleBounce(
                color: Geel,
                size: 100,
              ),
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: FloatingActionButton.extended(
          heroTag: "ButtonBestellingConfirmatie",
          splashColor: GrijsDark,
          elevation: 4.0,
          backgroundColor: Geel,
          icon: const Icon(
            FontAwesomeIcons.check,
            color: White,
          ),
          label: Text(
            buttonText,
            style: TextStyle(color: White, fontWeight: FontWeight.w800),
          ),
          onPressed: (bestelling != null)
              ? buttonFunction(bestelling['BestellingStatus'])
              : null,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  getTotalePrijs() {
    totalePrijs = 0;
    bestellingLijst.forEach((product) {
      totalePrijs =
          totalePrijs + (product['Aantal'] * product['ProductAveragePrijs']);
    });

    return totalePrijs.toStringAsFixed(2);
  }

  getTotalePrijsWidget() {
    return [
      Divider(
        color: GrijsDark,
        height: 30,
        thickness: 2,
      ),
      Padding(
        padding: const EdgeInsets.only(right: 20, left: 20),
        child: Row(
          children: <Widget>[
            Expanded(
                child: Text(
              "Artikelen",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            )),
            Text(
              "€ " + getTotalePrijs(),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            )
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 20, left: 20),
        child: Row(
          children: <Widget>[
            Expanded(
                child: Text(
              "Leveringskosten",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            )),
            Text(
              "€ " + leveringPrijs.toString(),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            )
          ],
        ),
      ),
      Divider(),
      Padding(
        padding: const EdgeInsets.only(right: 20, left: 20),
        child: Row(
          children: <Widget>[
            Expanded(
                child: Text(
              "Totale prijs",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            )),
            Text(
              "€ " +
                  (double.parse(getTotalePrijs()) + leveringPrijs).toString(),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            )
          ],
        ),
      )
    ];
  }

  buttonFunction(bestelling) {
    if ((bestelling == "AANVRAAG" || bestelling == "AANBIEDING GEKREGEN") &&
        !checkAanbod()) {
      print(checkAanbod());
      print("yi");
      setState(() {
        buttonText = "AANBOD MAKEN";
      });
      return () {
        Firestore.instance
            .collection('Commands')
            .document(bestellingId)
            .updateData({
          "AanbodLijst": FieldValue.arrayUnion([
            {
              'EmailBezorger': connectedUserMail,
              'TotaleAanbodPrijs': totalePrijs + leveringPrijs,
            }
          ])
        });
      };
    }
    if (bestelling == "AANVRAAG" ||
        bestelling == "AANBIEDING GEKREGEN" && checkAanbod()) {
      print("yo");
      setState(() {
        buttonText = "AANBOD VERWIJDEREN";
      });
      return () {
        Firestore.instance
            .collection('Commands')
            .document(bestellingId)
            .updateData({
          "AanbodLijst": FieldValue.arrayRemove([
            {
              'EmailBezorger': connectedUserMail,
              'TotaleAanbodPrijs': totalePrijs + leveringPrijs,
            }
          ])
        });
      };
    }
  }

  checkAanbod() {
    List aanbodLijst = bestelling['AanbodLijst'];
    print(aanbodLijst);
    bool isInLijst = false;
    aanbodLijst.forEach((aanbodMap) {
      print(aanbodMap['EmailBezorger']);
      if (aanbodMap['EmailBezorger'] == connectedUserMail) {
        print("exist in aanbod");
        isInLijst = true;
      }
    });

    return isInLijst;
  }
}
