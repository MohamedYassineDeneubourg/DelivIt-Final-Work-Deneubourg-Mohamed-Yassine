import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/globals.dart';
import 'package:expandable/expandable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong/latlong.dart';
import 'package:intl/intl.dart';
import 'package:toast/toast.dart';

import '../profile.dart';

class BestellingDetailAankoper extends StatefulWidget {
  BestellingDetailAankoper({Key key, this.bestellingId}) : super(key: key);
  final String bestellingId;

  @override
  _BestellingDetailAankoperState createState() =>
      _BestellingDetailAankoperState(bestellingId: this.bestellingId);
}

class _BestellingDetailAankoperState extends State<BestellingDetailAankoper>
    with TickerProviderStateMixin {
  ScrollController scrollController = ScrollController();

  _BestellingDetailAankoperState({Key key, @required this.bestellingId});
  List<Marker> opMapMarkers = [];
  String bestellingId;
  List bestellingLijst = [];
  List aanbodLijst = [];
  String connectedUserMail;
  Map bestelling;
  double totalePrijs = 0.0;
  Map bezorgerInfo;
  var tijdVoorBezorging;
  Timer _timerBezorging;
  List verzameldeProducten = new List();
  MapController mapController = new MapController();

  @override
  void initState() {
    getGlobals();
    getCurrentUser();
    _getData();

    super.initState();
  }

  @override
  void dispose() {
    _timerBezorging.cancel();
    scrollController.dispose();
    super.dispose();
  }

  void getCurrentUser() async {
    final FirebaseUser userData = await FirebaseAuth.instance.currentUser();
    if (userData != null) {
      setState(() {
        print("6");
        connectedUserMail = userData.email;
      });
    }
  }

  _getData() {
    var reference = Firestore.instance
        .collection("Commands")
        .document(bestellingId)
        .snapshots();

    reference.listen((data) {
      aanbodLijst = [];
      if (this.mounted) {
        setState(() {
          print("1");
          bestelling = data.data;
          //print(data.data);
          if (data != null) {
            if (data.data['VerzameldeProducten'] != null) {
              verzameldeProducten = []
                ..addAll(data.data['VerzameldeProducten']);
            }
            bestellingLijst = []..addAll(data.data['BestellingLijst']);
          }
        });
        if ((bestelling['BestellingStatus'] != "AANBIEDING GEKREGEN" ||
                bestelling['BestellingStatus'] != "AANVRAAG") &&
            (bestelling['BezorgerEmail'] != "")) {
          berekenEnToonBezorgingTijd();
          getBezorgerInfo();
        }
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
                //print(data);
                //print(distanceInMeters);
                Map bezorgerMap = {
                  "EmailBezorger": aanbod['EmailBezorger'],
                  "NaamVoornaam":
                      data.data["Naam"] + " " + data.data["Voornaam"],
                  "Ranking": 2.5,
                  "ProfileImage": data.data['ProfileImage'],
                  "Position": data.data['Position'],
                  "TotaleAanbodPrijs": aanbod['TotaleAanbodPrijs'],
                  "ComissieAankoper": aanbod['ComissieAankoper'],
                  "LeveringKosten": aanbod['LeveringKosten'],
                  "PrijsVanProducten": aanbod['PrijsVanProducten'],
                  "RatingScore": data.data['RatingScore'],
                  "Distance": distanceInMeters / 1000
                };

                setState(() {
                  print("2");
                  aanbodLijst.add(bezorgerMap);
                });
              });
            });
          });
        }
      }
    });
  }

  getTotalePrijsWidget() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: ExpandablePanel(
          header: Padding(
              padding: const EdgeInsets.only(right: 10, left: 10),
              child: Column(
                children: <Widget>[
                  Divider(
                    color: GrijsMidden,
                    height: 10,
                    thickness: 2,
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                          child: Text(
                        "Totale prijs",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900),
                      )),
                      Text(
                        "€ " +
                            bestelling["TotalePrijsAankoper"]
                                .toStringAsFixed(2),
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900),
                      )
                    ],
                  ),
                ],
              )),
          expanded: Column(
            children: <Widget>[
              Divider(),
              Padding(
                padding: const EdgeInsets.only(right: 20, left: 20),
                child: Row(
                  children: <Widget>[
                    Expanded(
                        child: Text(
                      "Artikelen",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    )),
                    Text(
                      "€ " + bestelling["PrijsVanProducten"].toStringAsFixed(2),
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    )),
                    Text(
                      "€ " +
                          (bestelling["LeveringKosten"] +
                                  bestelling["ComissieAankoper"])
                              .toStringAsFixed(2),
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    )
                  ],
                ),
              ),
            ],
          )),
    );
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12.0))),
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
              FlatButton.icon(
                onPressed: () {
                  Navigator.push(
                      context,
                      SlideTopRoute(
                          page: Profile(
                        userEmail: bezorgerMap['EmailBezorger'],
                      )));
                },
                label: Text(
                  "Profiel bekijken",
                  style: TextStyle(
                    color: GrijsDark,
                  ),
                ),
                icon: Icon(
                  Icons.person,
                  size: 15,
                  color: GrijsDark,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text(
                    "Wil je " +
                        bezorgerMap['NaamVoornaam'] +
                        " kiezen om je bestelling te bezorgen tegen \n\n€ " +
                        (bezorgerMap['TotaleAanbodPrijs'] +
                                bezorgerMap['ComissieAankoper'])
                            .toStringAsFixed(2) +
                        "?",
                    textAlign: TextAlign.center),
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
                      Firestore.instance
                          .collection('Commands')
                          .document(bestellingId)
                          .updateData({
                        "BezorgerEmail": bezorgerMap['EmailBezorger'],
                        "TotalePrijs": bezorgerMap['TotaleAanbodPrijs'],
                        "TotalePrijsAankoper":
                            (bezorgerMap['TotaleAanbodPrijs'] +
                                bezorgerMap['ComissieAankoper']),
                        'PrijsVanProducten': bezorgerMap['PrijsVanProducten'],
                        'LeveringKosten': bezorgerMap['LeveringKosten'],
                        "ComissieAankoper": bezorgerMap['ComissieAankoper'],
                        "isBeschikbaar": false,
                        "BestellingStatus": "PRODUCTEN VERZAMELEN",
                        'gaatBezorgdZijnTijd': bestelling['BezorgDatumEnTijd']
                            .toDate()
                            .add(Duration(
                                minutes: bezorgerMap['AanbodBezorgingTijd']))
                      });
                      Navigator.pop(context);
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
        return Container(
            margin: EdgeInsets.only(top: 20),
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
            margin: EdgeInsets.only(top: 20),
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
                    aanbodLijst.length == 0
                        ? Container(
                            padding: EdgeInsets.all(15),
                            child: SpinKitDoubleBounce(
                              color: Geel,
                              size: 60,
                            ),
                          )
                        : Container(
                            height: size.height * 0.20,
                            child: new ListView.builder(
                              itemCount: aanbodLijst.length,
                              itemBuilder: (context, index) {
                                double volledigePrijs = aanbodLijst[index]
                                        ['TotaleAanbodPrijs'] +
                                    aanbodLijst[index]['ComissieAankoper'];
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: <Widget>[
                                          Text(
                                              "€" +
                                                  volledigePrijs
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
                                      title: Text(
                                          aanbodLijst[index]['NaamVoornaam'],
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      subtitle: RatingBarIndicator(
                                        rating: aanbodLijst[index]
                                            ['RatingScore'],
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
                          ),
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 10.0, right: 40, left: 40, bottom: 20),
                      child: Text(
                        "Je kan je bestelling niet meer annuleren. \n Indien het echt noodzakelijk is, gelieve contact te nemen met de bezorger.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10),
                      ),
                    )
                  ],
                )));
        break;

      case ("PRODUCTEN VERZAMELEN"):
        return getMapEnInfo(status);

        break;

      case ("ONDERWEG"):
        //print("IS ONDERWEG!");

        return getMapEnInfo(status);

        break;

      case ("BEZORGD"):
        //  getBezorgerInfo();
        return Column(
          children: <Widget>[
            Divider(),
            getInfoWidget(bestelling['BestellingStatus']),
            /* Lottie.asset('assets/Animations/checked.json',
                width: size.width * 0.25) */
          ],
        );
        break;

      case ("BESTELLING CONFIRMATIE"):
        return getInfoWidget(status);
        break;

      case ("GEANNULEERD"):
        return Text("Deze bestelling werd geannuleerd");
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

  getBezorgerInfo() {
    print("GET BEZORGER INFO NOW !!!");
    if (bestelling != null) {
      var reference = Firestore.instance
          .collection("Users")
          .document(bestelling['BezorgerEmail'])
          .snapshots();

      reference.listen((onData) {
        if (mounted) {
          setState(() {
            print("3");
            bezorgerInfo = onData.data;
          });
          if (bestelling['BestellingStatus'] == "PRODUCTEN VERZAMELEN" ||
              bestelling['BestellingStatus'] == "ONDERWEG") {
            getMarkers();
          }
        }
      });
    }
  }

  getInfoWidget(status) {
    //getBezorgerInfo();
    Size size = MediaQuery.of(context).size;
    if (bezorgerInfo != null) {
      return ListTile(
          title: Text(
            (bezorgerInfo['Naam'] + " " + bezorgerInfo['Voornaam'])
                .toUpperCase(),
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          subtitle: (status == "PRODUCTEN VERZAMELEN")
              ? Text('Verzamelt je producten..')
              : (status == "BEZORGD")
                  ? Text('Heeft het geleverd.')
                  : (status == "BESTELLING CONFIRMATIE")
                      ? Text('Wacht op je bevestiging..')
                      : Text('Is nu aan het aankomen!'),
          trailing: Container(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Container(
                  height: size.width * 0.10,
                  width: size.width * 0.10,
                  decoration: new BoxDecoration(
                      color: Geel,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 1.0,
                          color: GrijsMidden,
                          offset: Offset(0.3, 0.3),
                        ),
                      ],
                      borderRadius:
                          new BorderRadius.all(Radius.circular(360.0))),
                  child: new IconButton(
                      icon: new Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                            context,
                            SlideTopRoute(
                                page: Profile(
                              userEmail: bestelling['BezorgerEmail'],
                            )));
                      }),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Container(
                    height: size.width * 0.10,
                    width: size.width * 0.10,
                    decoration: new BoxDecoration(
                        color: GrijsDark,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 1.0,
                            color: GrijsMidden,
                            offset: Offset(0.3, 0.3),
                          ),
                        ],
                        borderRadius:
                            new BorderRadius.all(Radius.circular(360.0))),
                    child: new IconButton(
                        icon: new Icon(
                          Icons.message,
                          color: Colors.white,
                        ),
                        onPressed: null),
                  ),
                ),
              ],
            ),
          ));
    } else {
      return SizedBox(height: 0);
    }
  }

  getMapEnInfo(status) {
    Size size = MediaQuery.of(context).size;
    if (bezorgerInfo != null) {
      return Expanded(
        child: Container(
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
            child: Column(children: <Widget>[
              getInfoWidget(status),
              (status == "BESTELLING CONFIRMATIE" && mapController != null)
                  ? Container(
                      child: SpinKitDoubleBounce(
                        color: Geel,
                        size: 100,
                      ),
                    )
                  : Flexible(
                      child: FlutterMap(
                        mapController: mapController,
                        options: new MapOptions(
                          onTap: (LatLng eo) {
                            mapController.onReady.then((result) {
                              print("verplaats it!");
                              verplaatsKaart(
                                  mapController,
                                  LatLng(bezorgerInfo['Position']['latitude'],
                                      bezorgerInfo['Position']['longitude']),
                                  15,
                                  this);
                            });
                          },
                          center: new LatLng(53, 22),
                          zoom: 15.0,
                        ),
                        layers: [
                          new TileLayerOptions(
                            urlTemplate: "https://api.tiles.mapbox.com/v4/"
                                "{id}/{z}/{x}/{y}@2x.png?access_token=sk.eyJ1IjoieWFzc2luZTEzMTMiLCJhIjoiY2szaGR4bTBtMGFwYTNjbXV6bTNhZ3hzMyJ9.1e9x7ostbK09U-kbvaxXxg",
                            additionalOptions: {
                              'accessToken':
                                  '<sk.eyJ1IjoieWFzc2luZTEzMTMiLCJhIjoiY2szaGR4bTBtMGFwYTNjbXV6bTNhZ3hzMyJ9.1e9x7ostbK09U-kbvaxXxg>',
                              'id': 'mapbox.streets',
                            },
                          ),
                          new MarkerLayerOptions(
                            markers: opMapMarkers,
                          ),
                        ],
                      ),
                    )
            ])),
      );
    } else {
      return Padding(padding: EdgeInsets.all(1));
    }
  }

  berekenEnToonBezorgingTijd() {
    if ((bestelling['gaatBezorgdZijnTijd'].toDate().difference(DateTime.now()))
            .inMinutes <=
        0) {
      setState(() {
        tijdVoorBezorging = Duration(minutes: 0).inMinutes;
      });
    } else {
      setState(
        () {
          tijdVoorBezorging = (bestelling['gaatBezorgdZijnTijd']
                  .toDate()
                  .difference(DateTime.now()))
              .inMinutes;
        },
      );
    }

    _timerBezorging = new Timer.periodic(
      Duration(seconds: 5),
      (Timer timer) {
        if (this.mounted) {
          if ((bestelling['gaatBezorgdZijnTijd']
                      .toDate()
                      .difference(DateTime.now()))
                  .inMinutes <=
              0) {
            setState(() {
              tijdVoorBezorging = Duration(minutes: 0).inMinutes;
            });
            timer.cancel();
          } else {
            setState(
              () {
                tijdVoorBezorging = (bestelling['gaatBezorgdZijnTijd']
                        .toDate()
                        .difference(DateTime.now()))
                    .inMinutes;
              },
            );
          }
        } else {
          timer.cancel();
        }
      },
    );
  }

  getMarkers() {
    if (bezorgerInfo != null && bestelling != null) {
      //print(bezorgerInfo['Position']['latitude']);
      //print(bezorgerInfo['Position']['longitude']);
      num longitudeBezorger = bezorgerInfo['Position']['longitude'];
      num latitudeBezorger = bezorgerInfo['Position']['latitude'];

      num longitudeBestelling = bestelling['AdresPosition']['longitude'];
      num latitudeBestelling = bestelling['AdresPosition']['latitude'];
      //print(mapController);

      mapController.onReady.then((result) {
        print("verplaats it!");
        verplaatsKaart(mapController,
            LatLng(latitudeBezorger, longitudeBezorger), 15, this);
        setState(() {
          print("4");
          opMapMarkers = [
            Marker(
              width: 35.0,
              height: 35.0,
              point: new LatLng(latitudeBestelling, longitudeBestelling),
              builder: (ctx) => new Container(
                child: new RawMaterialButton(
                  onPressed: null,
                  child: Icon(
                    Icons.home,
                    color: Colors.white,
                    size: 20.0,
                  ),
                  shape: new CircleBorder(),
                  elevation: 1.0,
                  fillColor: Colors.blue,
                ),
              ),
            ),
            Marker(
              width: 35.0,
              height: 35.0,
              point: new LatLng(latitudeBezorger, longitudeBezorger),
              builder: (ctx) => new Container(
                child: new RawMaterialButton(
                  onPressed: null,
                  child: Icon(
                    Icons.directions_bike,
                    color: Colors.white,
                    size: 20.0,
                  ),
                  shape: new CircleBorder(),
                  elevation: 3.0,
                  fillColor: Geel,
                ),
              ),
            )
          ];
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("BUILD IT");
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
          backgroundColor: White,
          textTheme: TextTheme(
              headline6: TextStyle(
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
          ? SingleChildScrollView(
              child: Container(
                height: size.height * 0.9,
                padding: new EdgeInsets.only(
                    top: 8.0, bottom: 20, right: 15, left: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
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
                                    Text(
                                        getDatumToString(
                                            bestelling['BezorgDatumEnTijd']),
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
                                        fontSize: 20,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      "Nog ±" +
                                          tijdVoorBezorging.toString() +
                                          " min...",
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                )))),
                    (bestelling['BestellingStatus'] == "BEZORGD")
                        ? getBestellingOverzicht()
                        : Container(
                            constraints: BoxConstraints(
                              maxHeight: size.height * 0.22,
                            ),
                            child: new ListView.builder(
                              shrinkWrap: true,
                              itemCount: bestellingLijst.length,
                              itemBuilder: (context, index) {
                                return Card(
                                    color: (verzameldeProducten.contains(
                                            bestellingLijst[index]
                                                ['ProductID']))
                                        ? GrijsMidden.withOpacity(0.3)
                                        : White,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: ListTile(
                                      enabled: (verzameldeProducten.contains(
                                              bestellingLijst[index]
                                                  ['ProductID']))
                                          ? false
                                          : true,
                                      onTap: null,
                                      trailing: Text(
                                          "€ " +
                                              (bestellingLijst[index][
                                                          'ProductAveragePrijs'] *
                                                      bestellingLijst[index]
                                                          ['Aantal'])
                                                  .toStringAsFixed(2),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      leading: AspectRatio(
                                          aspectRatio: 1 / 1,
                                          child: Image.network(
                                            bestellingLijst[index]
                                                ['ProductImage'],
                                            height: 40,
                                          )),
                                      title: Text(
                                          bestellingLijst[index]['Aantal']
                                                  .toString() +
                                              "x " +
                                              bestellingLijst[index]
                                                  ['ProductTitel'],
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ));
                              },
                            ),
                          ),
                    (bestelling['BestellingStatus'] == "GEANNULEERD") ||
                            (bestelling['BestellingStatus'] == "AANVRAAG") ||
                            (bestelling['BestellingStatus'] ==
                                "AANBIEDING GEKREGEN")
                        ? Container()
                        : getTotalePrijsWidget(),
                    (bestelling != null)
                        ? getStatusWidget(bestelling['BestellingStatus'])
                        : Container()
                  ],
                ),
              ),
            )
          : Container(
              child: SpinKitDoubleBounce(
                color: Geel,
                size: 100,
              ),
            ),
      floatingActionButton: (bestelling != null)
          ? ((bestelling['BestellingStatus'] == "AANVRAAG") ||
                  (bestelling['BestellingStatus'] == "ONDERWEG") ||
                  (bestelling['BestellingStatus'] == "BESTELLING CONFIRMATIE"))
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: FloatingActionButton.extended(
                    heroTag: "ButtonBestellingConfirmatie",
                    splashColor: GrijsDark,
                    elevation: 4.0,
                    backgroundColor:
                        (bestelling['BestellingStatus'] == "ONDERWEG")
                            ? GrijsDark
                            : (bestelling['BestellingStatus'] ==
                                    "BESTELLING CONFIRMATIE")
                                ? Colors.green
                                : Geel,
                    icon: Icon(
                      (bestelling['BestellingStatus'] == "ONDERWEG")
                          ? Icons.timer
                          : FontAwesomeIcons.check,
                      color: White,
                    ),
                    label: Text(
                      (bestelling['BestellingStatus'] ==
                              "BESTELLING CONFIRMATIE")
                          ? "BESTELLING IS BEZORGD"
                          : (bestelling['BestellingStatus'] == "ONDERWEG")
                              ? "WACHTEN OP BEZORGER.."
                              : "BESTELLING ANNULEREN",
                      style:
                          TextStyle(color: White, fontWeight: FontWeight.w800),
                    ),
                    onPressed: () {
                      if (bestelling['BestellingStatus'] == "ONDERWEG") {
                        Toast.show(
                            "De bezorger moet eerst de bestelling bevestigen.",
                            context,
                            duration: Toast.LENGTH_LONG,
                            gravity: Toast.BOTTOM,
                            backgroundColor: GrijsDark);
                      } else if (bestelling['BestellingStatus'] ==
                          "BESTELLING CONFIRMATIE") {
                        ratingSystem(setState);
                      } else {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(12.0))),
                                title: new Text(
                                  "Bestelling annuleren",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                content: Padding(
                                  padding: const EdgeInsets.only(top: 20.0),
                                  child:
                                      Text("Wil je deze bestelling annuleren?"),
                                ),
                                actions: <Widget>[
                                  ButtonTheme(
                                      minWidth: 400.0,
                                      child: FlatButton(
                                        color: Geel,
                                        child: new Text(
                                          "JA",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: () async {
                                          await Firestore.instance
                                              .collection('Commands')
                                              .document(bestellingId)
                                              .updateData({
                                            "isBeschikbaar": false,
                                            "BestellingStatus": "GEANNULEERD",
                                          });

                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                          // GEKOZEN!!
                                        },
                                      )),
                                  ButtonTheme(
                                      minWidth: 400.0,
                                      child: FlatButton(
                                        color: GrijsDark,
                                        child: new Text(
                                          "NEEN",
                                          style: TextStyle(
                                              color: White,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ))
                                ],
                              );
                            });
                      }
                    },
                  ),
                )
              : Padding(padding: EdgeInsets.all(1))
          : Padding(padding: EdgeInsets.all(1)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  getBestellingOverzicht() {
    Size size = MediaQuery.of(context).size;

    return Container(
      margin: EdgeInsets.only(top: 20, bottom: 20),
      constraints: BoxConstraints(maxHeight: size.height * 0.55),
      child: new ListView.builder(
        shrinkWrap: true,
        itemCount: bestellingLijst.length,
        itemBuilder: (context, index) {
          return ListTile(
            onTap: null,
            trailing: Text(
                "€ " +
                    (bestellingLijst[index]['Aantal'] *
                            bestellingLijst[index]['ProductAveragePrijs'])
                        .toString(),
                style: TextStyle(fontWeight: FontWeight.bold)),
            leading: Image.network(
              bestellingLijst[index]['ProductImage'],
              height: 20,
            ),
            title: Text(
                bestellingLijst[index]['Aantal'].toString() +
                    "x " +
                    bestellingLijst[index]['ProductTitel'],
                style: TextStyle(fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }

  ratingSystem(setState) {
    List ratingScoreList = bezorgerInfo['RatingScoresList'];

    if (ratingScoreList == null) {
      ratingScoreList = [];
    }

    num ratingNumber;
    String ratingMessage;
    bool anonyme = false;

    bool isOk = false;
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return WillPopScope(
                onWillPop: () async {
                  if (isOk) {
                    return true;
                  } else {
                    return false;
                  }
                },
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12.0))),
                  title: new Text(
                    "GEEF UW ADVIES",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: SingleChildScrollView(
                    reverse: true,
                    controller: scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          "Wij hopen dat de bezorging vlot en goed werd gedaan, geef uw advies op de bezorger 😀",
                          textAlign: TextAlign.justify,
                        ),
                        Divider(
                          color: Geel,
                          thickness: 2,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: CircleAvatar(
                            backgroundColor: Geel,
                            radius: 60,
                            child: ClipOval(
                              child: Image.network(bezorgerInfo['ProfileImage'],
                                  fit: BoxFit.cover),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0, bottom: 12),
                          child: Text(
                              bezorgerInfo['Naam'].toUpperCase() +
                                  " " +
                                  bezorgerInfo['Voornaam'].toUpperCase(),
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22),
                              textAlign: TextAlign.center),
                        ),
                        Center(
                          child: RatingBar(
                            initialRating: 0,
                            maxRating: 5,
                            minRating: 0,
                            allowHalfRating: true,
                            unratedColor: GrijsMidden,
                            itemBuilder: (context, index) => Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            itemCount: 5,
                            itemSize: 45.0,
                            direction: Axis.horizontal,
                            onRatingUpdate: (double value) {
                              setState(() {
                                ratingNumber = value;
                              });
                            },
                          ),
                        ),
                        Padding(
                            padding: EdgeInsets.only(top: 15.0),
                            child: TextFormField(
                              onTap: () {
                                scrollController.animateTo(
                                  0.0,
                                  curve: Curves.easeOut,
                                  duration: const Duration(milliseconds: 300),
                                );
                              },
                              maxLines: 3,
                              decoration: InputDecoration(
                                  errorStyle:
                                      TextStyle(fontWeight: FontWeight.w700),
                                  prefixIcon: Icon(
                                    Icons.textsms,
                                    color: Geel,
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                  focusedBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Geel, width: 2),
                                  ),
                                  border: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Geel, width: 2),
                                  ),
                                  errorBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.red, width: 2),
                                  ),
                                  labelText: 'Commentaar over ' +
                                      bezorgerInfo['Naam'].toUpperCase() +
                                      " " +
                                      bezorgerInfo['Voornaam'].toUpperCase(),
                                  hintText: '...'),
                              onChanged: (value) => ratingMessage = value,
                            )),
                        Center(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Checkbox(
                                activeColor: Geel,
                                value: anonyme,
                                onChanged: (bool value) {
                                  setState(() {
                                    anonyme = value;
                                  });
                                },
                              ),
                              Text(
                                "Anoniem blijven",
                                textAlign: TextAlign.center,
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    ButtonTheme(
                        minWidth: 400.0,
                        child: RaisedButton(
                          color: Geel,
                          child: Text(
                            "BEVESTIGEN",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          onPressed: () async {
                            if (ratingNumber == null ||
                                ratingMessage == null ||
                                ratingMessage.length < 5) {
                              Toast.show(
                                  "Een score moet ingevoegd worden..", context,
                                  duration: Toast.LENGTH_LONG,
                                  gravity: Toast.BOTTOM,
                                  backgroundColor: GrijsDark);
                            } else {
                              num total = 0.0;
                              var firebaseEntry;
                              if (ratingScoreList.isEmpty) {
                                firebaseEntry = [ratingNumber];
                                total = ratingNumber;
                              } else {
                                ratingScoreList.forEach((e) {
                                  total = total + e;
                                });

                                total = (total + ratingNumber) /
                                    (ratingScoreList.length + 1);

                                firebaseEntry =
                                    FieldValue.arrayUnion([ratingNumber]);
                              }

                              try {
                                await Firestore.instance
                                    .collection("Users")
                                    .document(bestelling['BezorgerEmail'])
                                    .updateData({
                                  'RatingScore': total,
                                  'RatingScoresList': firebaseEntry,
                                  'RatingMessages': FieldValue.arrayUnion([
                                    {
                                      "Person": anonyme
                                          ? "Anoniem"
                                          : connectedUserMail,
                                      "Message": ratingMessage,
                                      "Score": ratingNumber
                                    }
                                  ])
                                });
                                await Firestore.instance
                                    .collection('Commands')
                                    .document(bestellingId)
                                    .updateData({
                                  "isBeschikbaar": false,
                                  "ConfirmatieKlant": true,
                                  "BestellingStatus": "BEZORGD",
                                });
/*
                                await Firestore.instance
                                    .collection('Users')
                                    .document(bestelling['AankoperEmail'])
                                    .updateData({
                                  "Portefeuille": FieldValue.increment(
                                      bestelling['geldBezorger'])
                                });
                                */

                                setState(() {
                                  print("5");
                                  isOk = true;
                                });
                                Navigator.pop(context);
                              } catch (e) {
                                Toast.show(
                                    "Une erreur s'est produite..", context,
                                    duration: Toast.LENGTH_LONG,
                                    gravity: Toast.BOTTOM,
                                    backgroundColor: GrijsDark);
                                print('Error:$e');
                              }
                            }
                            //  signIn();
                          },
                        )),
                  ],
                ),
              );
            },
          );
        });
  }
}
