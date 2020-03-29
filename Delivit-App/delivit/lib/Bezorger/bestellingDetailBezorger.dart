import 'dart:io';
import 'package:android_intent/android_intent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/globals.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong/latlong.dart';

import '../profile.dart';

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
  Map aankoperInfo;
  _BestellingDetailBezorgerState(
      {Key key, @required this.bestellingId, @required this.connectedUserMail});
  String buttonText = "";
  String bestellingId;
  List bestellingLijst = [];
  List aanbodLijst = [];
  String connectedUserMail;
  Map bestelling;
  double totalePrijs = 0.0;
  List verzameldeProducten = new List();

  MapController mapController = new MapController();
  List<Marker> opMapMarkers;
  @override
  void initState() {
    getGlobals();
    super.initState();
    _getData();
  }

  _getData() async {
    var prijsLijstQuery = Firestore.instance
        .collection("Users")
        .document(connectedUserMail)
        .get();
    Map prijsLijst = {};
    prijsLijstQuery.then((userData) {
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
            if (data.data['VerzameldeProducten'] != null) {
              verzameldeProducten = []
                ..addAll(data.data['VerzameldeProducten']);
            }

            print("Leveren?...");

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

  getFloatingButtonWidget(status) {
    switch (status) {
      case ("AANVRAAG"):
        if (!checkAanbod()) {
          return floatingButton(
              "AANBOD MAKEN", FontAwesomeIcons.solidArrowAltCircleUp, () {
            setState(() {
              print("NOOO HERE!");
              Firestore.instance
                  .collection('Commands')
                  .document(bestellingId)
                  .updateData({
                "BestellingStatus": "AANBIEDING GEKREGEN",
                "AanbodLijst": FieldValue.arrayUnion([
                  {
                    'EmailBezorger': connectedUserMail,
                    'TotaleAanbodPrijs': totalePrijs + leveringPrijs,
                    'PrijsVanProducten': totalePrijs,
                    'LeveringKosten': leveringPrijs,
                    'ComissieAankoper':
                        (percentageCommisie * totalePrijs).ceilToDouble()
                  }
                ])
              });
            });
          });
        } else {
          return null;
        }

        break;
      case ("AANBIEDING GEKREGEN"):
        if (!checkAanbod()) {
          return floatingButton(
              "AANBOD MAKEN", FontAwesomeIcons.solidArrowAltCircleUp, () {
            setState(() {
              Firestore.instance
                  .collection('Commands')
                  .document(bestellingId)
                  .updateData({
                "BestellingStatus": "AANBIEDING GEKREGEN",
                "AanbodLijst": FieldValue.arrayUnion([
                  {
                    'EmailBezorger': connectedUserMail,
                    'TotaleAanbodPrijs': totalePrijs + leveringPrijs,
                  }
                ])
              });
            });
          });
        } else {
          return null;
        }

        break;

      case ("PRODUCTEN VERZAMELEN"):
        return floatingButton(
            "ROUTEBESCHRIJVING NAAR KLANT", FontAwesomeIcons.map, () async {
          setState(() {
            Firestore.instance
                .collection('Commands')
                .document(bestellingId)
                .updateData({
              "BestellingStatus": "ONDERWEG",
            });
          });
          String latitude;
          String longitude;
          var me = await Geolocator()
              .getCurrentPosition(desiredAccuracy: LocationAccuracy.lowest);

          latitude = me.latitude.toString();
          longitude = me.longitude.toString();

          String origin =
              latitude + "," + longitude; // lat,long like 123.34,68.56
          print("NAVIGATE !");
          print(origin);
          String destination =
              bestelling['AdresPosition']['latitude'].toString() +
                  "," +
                  bestelling['AdresPosition']['longitude'].toString();
          if (Platform.isAndroid) {
            final AndroidIntent intent = new AndroidIntent(
                action: 'action_view',
                data: Uri.encodeFull(
                    "https://www.google.com/maps/dir/?api=1&origin=" +
                        origin +
                        "&destination=" +
                        destination +
                        "&travelmode=driving&dir_action=navigate"),
                package: 'com.google.android.apps.maps');
            intent.launch();
          } else {
            String url = "https://www.google.com/maps/dir/?api=1&origin=" +
                origin +
                "&destination=" +
                destination +
                "&travelmode=driving&dir_action=navigate";
            if (await canLaunch(url)) {
              await launch(url);
            } else {
              throw 'Could not launch $url';
            }
          }
        });
        break;

      case ("ONDERWEG"):
        return floatingButton(
            "BESTELLING BEZORGD", FontAwesomeIcons.clipboardCheck, () {
          Firestore.instance
              .collection('Commands')
              .document(bestellingId)
              .updateData({
            "BestellingStatus": "BESTELLING CONFIRMATIE",
            "ConfirmatieBezorger": true,
          });

          print("NOG CHECKEN OF KLANT CONFIRMEERD");
        });
        break;

      case ("BESTELLING CONFIRMATIE"):
        return floatingButton(
            "DE AANKOPER MOET BEVESTIGEN", FontAwesomeIcons.solidClock, () {});
        break;
    }
  }

  floatingButton(text, icon, onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: FloatingActionButton.extended(
        heroTag: "ButtonBestellingConfirmatie",
        splashColor: GrijsDark,
        elevation: 4.0,
        backgroundColor:
            (bestelling['BestellingStatus'] == "BESTELLING CONFIRMATIE")
                ? Colors.orange
                : Geel,
        icon: Icon(
          icon,
          color: White,
        ),
        label: Text(
          text,
          style: TextStyle(color: White, fontWeight: FontWeight.w800),
        ),
        onPressed: onPressed,
      ),
    );
  }

  getStatusWidget(status) {
    print(status);
    Size size = MediaQuery.of(context).size;
    switch (status) {
      case ("PRODUCTEN VERZAMELEN"):
        return Container(
          height: size.height * 0.58,
          child: Column(
            children: <Widget>[
              new ListView.builder(
                itemCount: bestellingLijst.length,
                itemBuilder: (context, index) {
                  print(verzameldeProducten.contains(bestellingLijst[index]));
                  print(verzameldeProducten);
                  print(bestellingLijst[index]);
                  return Card(
                      color: (verzameldeProducten
                              .contains(bestellingLijst[index]['ProductID']))
                          ? GrijsMidden.withOpacity(0.3)
                          : White,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: ListTile(
                        enabled: (verzameldeProducten
                                .contains(bestellingLijst[index]['ProductID']))
                            ? false
                            : true,
                        onTap: () async {
                          if (verzameldeProducten
                              .contains(bestellingLijst[index]['ProductID'])) {
                            verzameldeProducten
                                .remove(bestellingLijst[index]['ProductID']);
                            await Firestore.instance
                                .collection('Commands')
                                .document(bestellingId)
                                .updateData({
                              "VerzameldeProducten": verzameldeProducten,
                            });
                          } else {
                            verzameldeProducten
                                .add(bestellingLijst[index]['ProductID']);
                            await Firestore.instance
                                .collection('Commands')
                                .document(bestellingId)
                                .updateData({
                              "VerzameldeProducten": verzameldeProducten,
                            });
                          }
                        },
                        trailing: Text(
                            "€ " +
                                (bestellingLijst[index]['Aantal'] *
                                        bestellingLijst[index]
                                            ['ProductAveragePrijs'])
                                    .toStringAsFixed(2),
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        leading: Image.network(
                          bestellingLijst[index]['ProductImage'],
                          height: 40,
                        ),
                        title: Text(
                            bestellingLijst[index]['Aantal'].toString() +
                                "x : " +
                                bestellingLijst[index]['ProductTitel'],
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            "€ " +
                                bestellingLijst[index]['ProductAveragePrijs']
                                    .toStringAsFixed(2),
                            style: TextStyle(fontWeight: FontWeight.w400)),
                      ));
                },
              ),
              getTotalePrijsWidget()
            ],
          ),
        );
        break;

      case ("ONDERWEG"):
        getAankoperInfo();
        getMarkers();

        return getMapEnInfo(status);
        break;

      case ("BESTELLING CONFIRMATIE"):
        getAankoperInfo();
        getMarkers();
        print("no column?");
        return getMapEnInfo(status);

        break;
      case ("BEZORGD"):
        return Lottie.asset('assets/Animations/checked.json');
        break;
      default:
        return Padding(padding: EdgeInsets.all(1));
        break;
    }
  }

  getAankoperInfo() {
    if (bestelling != null) {
      //print(bestelling);
      var reference = Firestore.instance
          .collection("Users")
          .document(bestelling['AankoperEmail'])
          .snapshots();

      reference.listen((onData) {
        if (mounted) {
          setState(() {
            aankoperInfo = onData.data;
          });
        }
      });
    }
  }

  getMarkers() {
    if (aankoperInfo != null && bestelling != null) {
      //print(bezorgerInfo['Position']['latitude']);
      //print(bezorgerInfo['Position']['longitude']);
      num longitudeBezorger = aankoperInfo['Position']['longitude'];
      num latitudeBezorger = aankoperInfo['Position']['latitude'];

      num longitudeBestelling = bestelling['AdresPosition']['longitude'];
      num latitudeBestelling = bestelling['AdresPosition']['latitude'];
      //print(mapController);

      mapController.onReady.then((result) {
        setState(() {
          mapController.move(LatLng(latitudeBezorger, longitudeBezorger), 15);

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
      body: getCorrectInterface(),
      floatingActionButton: (bestelling != null)
          ? getFloatingButtonWidget(bestelling['BestellingStatus'])
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  getMapEnInfo(status) {
    Size size = MediaQuery.of(context).size;
    if (aankoperInfo != null) {
      print("mapinfo");
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
                    (aankoperInfo['Naam'] + aankoperInfo['Voornaam'])
                        .toUpperCase(),
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  subtitle: (status == "PRODUCTEN VERZAMELEN")
                      ? Text('Wacht op zijn bestelling..')
                      : (status == "BEZORGD")
                          ? Text('Heeft het goed gekregen.')
                          : (status == "BESTELLING CONFIRMATIE")
                              ? Text(
                                  'Kijkt zorgvuldig de bestelling en gaat deze binnenkort bevestigen..')
                              : Text('Wacht op zijn bestelling..'),
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
                                print(bestelling);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Profile(
                                              userEmail:
                                                  bestelling['BezorgerEmail'],
                                            ),
                                        fullscreenDialog: true));
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
              (status == "BEZORGD" && mapController != null)
                  ? Lottie.asset('assets/Animations/checked.json',
                      width: size.width * 0.25)
                  : (status == "BESTELLING CONFIRMATIE" &&
                          mapController != null)
                      ? Container(
                          margin: EdgeInsets.all(30),
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
                                  mapController.move(
                                      new LatLng(
                                          aankoperInfo['Position']['latitude'],
                                          aankoperInfo['Position']
                                              ['longitude']),
                                      15);
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

  getCorrectInterface() {
    Size size = MediaQuery.of(context).size;
    if ((bestelling != null)) {
      if ((bestelling['BestellingStatus'] != "AANVRAAG") &&
          (bestelling['BestellingStatus'] != "AANBIEDING GEKREGEN") &&
          bestelling['BezorgerEmail'] == connectedUserMail) {
        return (bestelling != null)
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
                                        fontSize: 20,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                )))),
                    getStatusWidget(bestelling['BestellingStatus'])
                  ],
                ))
            : Container(
                child: SpinKitDoubleBounce(
                color: Geel,
                size: 100,
              ));
      } else {
        return (bestelling != null)
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
                                              (bestellingLijst[index]
                                                          ['Aantal'] *
                                                      bestellingLijst[index][
                                                          'ProductAveragePrijs'])
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
                          // getTotalePrijsWidget(),
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
                          getTotalePrijsWidget(),
                        ],
                      ))
            : Container(
                child: SpinKitDoubleBounce(
                  color: Geel,
                  size: 100,
                ),
              );
      }
    }
  }

  getTotalePrijs() {
    totalePrijs = 0;
    bestellingLijst.forEach((product) {
      totalePrijs =
          totalePrijs + (product['Aantal'] * product['ProductAveragePrijs']);
    });

    return totalePrijs.toStringAsFixed(2);
  } 

  getAanbodPrijsWidget() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: ExpandablePanel(
          header: Padding(
              padding: const EdgeInsets.only(right: 10, left: 10),
              child: Column(
                children: <Widget>[
                  Divider(
                    color: GrijsDark,
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
                        "€ " + getTotalePrijs().toStringAsFixed(2),
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
                      "€ " + getTotalePrijs().toStringAsFixed(2),
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
                      "€ " + bestelling["LeveringKosten"].toStringAsFixed(2),
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

  getTotalePrijsWidget() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: ExpandablePanel(
          header: Padding(
              padding: const EdgeInsets.only(right: 10, left: 10),
              child: Column(
                children: <Widget>[
                  Divider(
                    color: GrijsDark,
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
                        "€ " + bestelling["TotalePrijs"].toStringAsFixed(2),
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
                      "€ " + bestelling["LeveringKosten"].toStringAsFixed(2),
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
