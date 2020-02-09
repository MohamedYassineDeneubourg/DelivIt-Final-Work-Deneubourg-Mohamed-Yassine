import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/colors.dart';
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

class BestellingDetailAankoper extends StatefulWidget {
  BestellingDetailAankoper({Key key, this.bestellingId}) : super(key: key);
  final String bestellingId;

  @override
  _BestellingDetailAankoperState createState() =>
      _BestellingDetailAankoperState(bestellingId: this.bestellingId);
}

class _BestellingDetailAankoperState extends State<BestellingDetailAankoper> {
  _BestellingDetailAankoperState({Key key, @required this.bestellingId});
  List<Marker> opMapMarkers;
  String bestellingId;
  List bestellingLijst = [];
  List aanbodLijst = [];
  String connectedUserMail;
  Map bestelling;
  Map bezorgerInfo;
  List verzameldeProducten = new List();
  MapController mapController = new MapController();

  @override
  void initState() {
    getCurrentUser();
    _getData();
    super.initState();
  }

  void getCurrentUser() async {
    final FirebaseUser userData = await FirebaseAuth.instance.currentUser();
    if (userData != null) {
      setState(() {
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
          print("Refreshed");
          bestelling = data.data;
          print(data.data);
          if (data.data['VerzameldeProducten'] != null) {
            verzameldeProducten = []..addAll(data.data['VerzameldeProducten']);
          }
          bestellingLijst = []..addAll(data.data['BestellingLijst']);
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
                print(data);
                print(distanceInMeters);
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
                      print(bezorgerMap['EmailBezorger']);
                      Firestore.instance
                          .collection('Commands')
                          .document(bestellingId)
                          .updateData({
                        "BezorgerEmail": bezorgerMap['EmailBezorger'],
                        "isBeschikbaar": false,
                        "BestellingStatus": "PRODUCTEN VERZAMELEN",
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

      case ("PRODUCTEN VERZAMELEN"):
        print("producten verzz");
        getBezorgerInfo();
        getMarkers();

        return getMapEnInfo(status);

        break;

      case ("ONDERWEG"):
        print("IS ONDERWEG!");
        setState(() {
          getBezorgerInfo();
          getMarkers();
        });
        return getMapEnInfo(status);

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

  getBezorgerInfo() {
    if (bestelling != null) {
      print(bestelling);
      var reference = Firestore.instance
          .collection("Users")
          .document(bestelling['BezorgerEmail'])
          .snapshots();

      reference.listen((onData) {
        if (mounted) {
          setState(() {
            bezorgerInfo = onData.data;
          });
        }
      });
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
              ListTile(
                  title: Text(
                    (bezorgerInfo['Naam'] + bezorgerInfo['Voornaam'])
                        .toUpperCase(),
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  subtitle: (status == "PRODUCTEN VERZAMELEN")
                      ? Text('Verzamelt je producten..')
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
                              onPressed: () {}),
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
                                borderRadius: new BorderRadius.all(
                                    Radius.circular(360.0))),
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
                  )),
              Flexible(
                child: FlutterMap(
                  mapController: mapController,
                  options: new MapOptions(
                    onTap: (LatLng eo) {
                      mapController.move(
                          new LatLng(bezorgerInfo['Position']['latitude'],
                              bezorgerInfo['Position']['longitude']),
                          15);
                    },
                    center: new LatLng(bezorgerInfo['Position']['latitude'],
                        bezorgerInfo['Position']['longitude']),
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

  getMarkers() {
    if (bezorgerInfo != null && bestelling != null) {
      print(bezorgerInfo['Position']['latitude']);
      print(bezorgerInfo['Position']['longitude']);
      num longitudeBezorger = bezorgerInfo['Position']['longitude'];
      num latitudeBezorger = bezorgerInfo['Position']['latitude'];

      num longitudeBestelling = bestelling['AdresPosition']['longitude'];
      num latitudeBestelling = bestelling['AdresPosition']['latitude'];
      setState(() {
        mapController.move(new LatLng(latitudeBezorger, longitudeBezorger), 15);

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
              child: new Column(
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
                              borderRadius:
                                  new BorderRadius.all(Radius.circular(10.0))),
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
                    height: size.height * 0.25,
                    child: new ListView.builder(
                      itemCount: bestellingLijst.length,
                      itemBuilder: (context, index) {
                        return Card(
                            color: (verzameldeProducten.contains(
                                    bestellingLijst[index]['ProductID']))
                                ? GrijsMidden.withOpacity(0.3)
                                : White,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: ListTile(
                              enabled: (verzameldeProducten.contains(
                                      bestellingLijst[index]['ProductID']))
                                  ? false
                                  : true,
                              onTap: null,
                              trailing: Text(
                                  bestellingLijst[index]['Aantal'].toString(),
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              leading: Image.network(
                                bestellingLijst[index]['ProductImage'],
                                height: 40,
                              ),
                              title: Text(
                                  bestellingLijst[index]['ProductTitel'],
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ));
                      },
                    ),
                  ),
                  (bestelling != null)
                      ? getStatusWidget(bestelling['BestellingStatus'])
                      : Padding(padding: EdgeInsets.all(1))
                ],
              ))
          : Container(
              child: SpinKitDoubleBounce(
                color: Geel,
                size: 100,
              ),
            ),
      floatingActionButton: (bestelling != null)
          ? ((bestelling['BestellingStatus'] == "AANVRAAG") ||
                  (bestelling['BestellingStatus'] == "ONDERWEG"))
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: FloatingActionButton.extended(
                    heroTag: "ButtonBestellingConfirmatie",
                    splashColor: GrijsDark,
                    elevation: 4.0,
                    backgroundColor:
                        (bestelling['BestellingStatus'] == "ONDERWEG")
                            ? GrijsDark
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
                        Firestore.instance
                            .collection('Commands')
                            .document(bestellingId)
                            .updateData({
                          "ConfirmatieKlant": true,
                          "isBeschikbaar": false,
                          "BestellingStatus": "BEZORGD",
                        });
                      } else {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
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
                                        onPressed: () {
                                          Firestore.instance
                                              .collection('Commands')
                                              .document(bestellingId)
                                              .delete();
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
}
