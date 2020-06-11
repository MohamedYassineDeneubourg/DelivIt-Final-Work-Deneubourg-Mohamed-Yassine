import 'dart:async';
import 'dart:io';
import 'package:android_intent/android_intent.dart';
import 'package:app_settings/app_settings.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/Functies/chatFunctions.dart';
import 'package:delivit/Functies/mapFunctions.dart';
import 'package:delivit/globals.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_permissions/location_permissions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong/latlong.dart';

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

class _BestellingDetailBezorgerState extends State<BestellingDetailBezorger>
    with TickerProviderStateMixin {
  Map aankoperInfo;

  int aanbodBezorgingTijd = 0;

  StreamSubscription<DocumentSnapshot> _getFirebaseSubscription;

  StreamSubscription<DocumentSnapshot> _getFirebaseAankoperSubscription;
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
  Size size;
  String vorigBestellingStatus = "";
  MapController mapController = new MapController();
  List<Marker> opMapMarkers;
  MapboxNavigation _directions;

  @override
  void dispose() {
    if (getFirebaseGlobalSubscription != null) {
      getFirebaseGlobalSubscription.cancel();
      getFirebaseGlobalSubscription = null;
    }

    if (_getFirebaseSubscription != null) {
      _getFirebaseSubscription.cancel();
    }
    if (_getFirebaseAankoperSubscription != null) {
      _getFirebaseAankoperSubscription.cancel();
    }

    super.dispose();
  }

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
      prijsLijst = userData['PrijsLijstBezorger'];
      var reference = Firestore.instance
          .collection("Commands")
          .document(bestellingId)
          .snapshots();

      _getFirebaseSubscription = reference.listen((data) {
        if (this.mounted) {
          setState(() {
            bestelling = data.data;
            if (data.data['VerzameldeProducten'] != null) {
              verzameldeProducten = []
                ..addAll(data.data['VerzameldeProducten']);
            }

            List bestellingLijstDatabase = data.data['BestellingLijst'];
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
              }

              bestellingLijst.add(productObject);
            });
            //bestellingLijst = []..addAll(data.data['BestellingLijst']);
          });
        }
      });
    });
  }

  maakAanbod() {
    bool isLoading = false;
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0))),
              title: new Text(
                "AANBOD MAKEN",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: isLoading
                  ? Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: SpinKitDoubleBounce(
                          color: Geel,
                          size: 30,
                        ),
                      )
                    ])
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                            "Hoeveel tijd zal dit je kosten om deze bestelling te bezorgen?"),
                        Padding(
                          padding: const EdgeInsets.only(top: 25, bottom: 25.0),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                IconButton(
                                  icon: Icon(
                                    Icons.remove_circle,
                                    size: 35,
                                  ),
                                  onPressed: () {
                                    if (aanbodBezorgingTijd > 10) {
                                      setState(() {
                                        aanbodBezorgingTijd =
                                            aanbodBezorgingTijd - 10;
                                      });
                                    }
                                  },
                                ),
                                Text(
                                  aanbodBezorgingTijd.toString() + " min",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 30),
                                ),
                                IconButton(
                                    icon: Icon(
                                      Icons.add_circle,
                                      color: Geel,
                                      size: 35,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        aanbodBezorgingTijd =
                                            aanbodBezorgingTijd + 10;
                                      });
                                    }),
                              ]),
                        ),
                        Text("€ " +
                            (getTotalePrijs() + bestelling['LeveringKosten'])
                                .toStringAsFixed(2)),
                      ],
                    ),
              actions: <Widget>[
                isLoading
                    ? null
                    : ButtonTheme(
                        minWidth: 400.0,
                        child: FlatButton(
                          color: isLoading ? GrijsDark : Geel,
                          child: new Text(
                            "AANBOD STUREN",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            if (this.mounted) {
                              setState(() {
                                isLoading = true;
                              });
                            }

                            Firestore.instance
                                .collection('Commands')
                                .document(bestellingId)
                                .updateData({
                              "BestellingStatus": "AANBIEDING GEKREGEN",
                              "AanbodEmailLijst":
                                  FieldValue.arrayUnion([connectedUserMail]),
                              "AanbodLijst": FieldValue.arrayUnion([
                                {
                                  'EmailBezorger': connectedUserMail,
                                  "AanbodBezorgingTijd": aanbodBezorgingTijd,
                                  'TotaleAanbodPrijs': getTotalePrijs() +
                                      bestelling["LeveringKosten"],
                                  'PrijsVanProducten': getTotalePrijs(),
                                  'LeveringKosten':
                                      bestelling["LeveringKosten"],
                                  'ComissieAankoper':
                                      (percentageCommisie * getTotalePrijs())
                                          .ceilToDouble()
                                }
                              ])
                            });
                            if (this.mounted) {
                              setState(() {
                                isLoading = false;
                              });
                            }
                            Navigator.of(context).pop();
                          },
                        )),
                isLoading
                    ? null
                    : ButtonTheme(
                        minWidth: 400.0,
                        child: FlatButton(
                          color: GrijsDark,
                          child: new Text(
                            "TERUG",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ))
              ],
            );
          });
        });
  }

  getFloatingButtonWidget(status) {
    switch (status) {
      case ("AANVRAAG"):
        if (!checkAanbod()) {
          return floatingButton(
              "AANBOD MAKEN", FontAwesomeIcons.solidArrowAltCircleUp, () {
            maakAanbod();
          });
        } else {
          return null;
        }

        break;
      case ("AANBIEDING GEKREGEN"):
        if (!checkAanbod()) {
          return floatingButton(
              "AANBOD MAKEN", FontAwesomeIcons.solidArrowAltCircleUp, () {
            maakAanbod();
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
    switch (status) {
      case ("PRODUCTEN VERZAMELEN"):
        return Container(
          height: size.height * 0.59,
          child: Column(
            children: <Widget>[
              Container(
                height: size.height * 0.45,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: bestellingLijst.length,
                  itemBuilder: (context, index) {
                    return Card(
                        color: (verzameldeProducten
                                .contains(bestellingLijst[index]['ProductID']))
                            ? GrijsLicht
                            : White,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ListTile(
                          enabled: (verzameldeProducten.contains(
                                  bestellingLijst[index]['ProductID']))
                              ? false
                              : true,
                          onTap: () async {
                            if (verzameldeProducten.contains(
                                bestellingLijst[index]['ProductID'])) {
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                  "€ " +
                                      (bestellingLijst[index]['Aantal'] *
                                              bestellingLijst[index]
                                                  ['ProductAveragePrijs'])
                                          .toStringAsFixed(2),
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Checkbox(
                                  value: verzameldeProducten.contains(
                                      bestellingLijst[index]['ProductID']),
                                  onChanged: null)
                            ],
                          ),
                          leading: Image.network(
                            bestellingLijst[index]['ProductImage'],
                            height: 40,
                          ),
                          title: AutoSizeText(
                              bestellingLijst[index]['Aantal'].toString() +
                                  "x : " +
                                  bestellingLijst[index]['ProductTitel'],
                              maxLines: 2,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              "€ " +
                                  bestellingLijst[index]['ProductAveragePrijs']
                                      .toStringAsFixed(2),
                              style: TextStyle(fontWeight: FontWeight.w400)),
                        ));
                  },
                ),
              ),
              getTotalePrijsWidget()
            ],
          ),
        );
        break;

      case ("ONDERWEG"):
        if (status != vorigBestellingStatus) {
          print("FIRST STATUS");
          vorigBestellingStatus = status;
          getAankoperInfo();
          showNavigation();
        }

        return SingleChildScrollView(
          child: Container(
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
            height: size.height * 0.60,
            child: Column(
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(bottom: 10),
                  decoration: new BoxDecoration(
                      color: Geel.withOpacity(0.6),
                      borderRadius:
                          new BorderRadius.all(Radius.circular(10.0))),
                  width: size.width,
                  child: FlatButton.icon(
                      onPressed: () {
                        showNavigation();
                      },
                      icon: Icon(Icons.map),
                      label: Text(
                        "Routebeschrijving naar klant",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )),
                ),
                getMapEnInfo(status)
              ],
            ),
          ),
        );
        break;

      case ("BESTELLING CONFIRMATIE"):
        if (status != vorigBestellingStatus) {
          vorigBestellingStatus = status;
          getAankoperInfo();
        }
        return Container(
            height: size.height * 0.8, child: getMapEnInfo(status));

        break;
      case ("BEZORGD"):
        return Column(
          children: <Widget>[
            Icon(
              Icons.check_circle,
              color: Geel,
            ),
            getProductenLijst(),
            getTotalePrijsWidget()
          ],
        );
        break;

      default:
        return Padding(padding: EdgeInsets.all(1));
        break;
    }
  }

  getAankoperInfo() {
    if (bestelling != null) {
      var reference = Firestore.instance
          .collection("Users")
          .document(bestelling['AankoperEmail'])
          .get();

      reference.then((onData) {
        if (this.mounted) {
          setState(() {
            aankoperInfo = onData.data;
          });
        }
        getMarkers();
      });
    }
  }

  showGpsSettings() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12.0))),
            title: Text('LOCALISATIE NIET GEACTIVEERD',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: Container(
                height: 85,
                child: SingleChildScrollView(
                  child: Text(
                      "Je moet je GPS-optie op uw toestel activeren om door te kunnen gaan."),
                )),
            contentPadding: EdgeInsets.all(20),
            actions: <Widget>[
              ButtonTheme(
                  minWidth: 400.0,
                  child: FlatButton(
                    color: Geel,
                    child: new Text(
                      "Naar instellingen",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      AppSettings.openLocationSettings();
                      Navigator.pop(context);
                    },
                  )),
            ],
          );
        });
  }

  getMarkers() {
    if (aankoperInfo != null && bestelling != null) {
      num longitudeBezorger = aankoperInfo['Position']['longitude'];
      num latitudeBezorger = aankoperInfo['Position']['latitude'];

      num longitudeBestelling = bestelling['AdresPosition']['longitude'];
      num latitudeBestelling = bestelling['AdresPosition']['latitude'];

      mapController.onReady.then((result) {
        if (this.mounted) {
          verplaatsKaart(mapController,
              LatLng(latitudeBezorger, longitudeBezorger), 15, this);
          if (this.mounted) {
            setState(() {
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;

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
      body: SingleChildScrollView(child: getCorrectInterface()),
      floatingActionButton: (bestelling != null)
          ? ((bestelling['BezorgerEmail'] != connectedUserMail) &&
                  (bestelling['BestellingStatus'] != "AANBIEDING GEKREGEN") &&
                  (bestelling['BestellingStatus'] != "AANVRAAG"))
              ? null
              : getFloatingButtonWidget(bestelling['BestellingStatus'])
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  getMapEnInfo(status) {
    if (aankoperInfo != null) {
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
                    (aankoperInfo['Naam'] + " " + aankoperInfo['Voornaam'])
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
                        onPressed: () {
                          goToConversation(
                              aankoperInfo['Email'],
                              aankoperInfo['Naam'].toUpperCase() +
                                  " " +
                                  aankoperInfo['Voornaam'].toUpperCase(),
                              aankoperInfo['ProfileImage'],
                              connectedUserMail,
                              context,
                              false);
                        }),
                  )),
              (status == "BESTELLING CONFIRMATIE" && mapController != null)
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
                              verplaatsKaart(
                                  mapController,
                                  new LatLng(
                                      aankoperInfo['Position']['latitude'],
                                      aankoperInfo['Position']['longitude']),
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

  navigateToGoogleMaps() async {
    String latitude;
    String longitude;
    var me = await Geolocator().getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);

    latitude = me.latitude.toString();
    longitude = me.longitude.toString();

    String origin = latitude + "," + longitude; // lat,long like 123.34,68.56
    print("NAVIGATE !");
    print(origin);
    String destination = bestelling['AdresPosition']['latitude'].toString() +
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
  }

  showNavigation() {
    LocationPermissions().requestPermissions();
    if (Platform.isIOS) {
      Geolocator()
          .getCurrentPosition(
              desiredAccuracy: LocationAccuracy.bestForNavigation)
          .then((value) async {
        final myPosition = Location(
            latitude: value.latitude, longitude: value.longitude, name: "Ik");

        final bestellingPosition = Location(
            name: "Bestelling",
            latitude: bestelling['AdresPosition']['latitude'],
            longitude: bestelling['AdresPosition']['longitude']);
        await _directions.startNavigation(
            origin: myPosition,
            destination: bestellingPosition,
            mode: NavigationMode.drivingWithTraffic,
            simulateRoute: false);
      });

      _directions = MapboxNavigation(onRouteProgress: (arrived) async {
        if (arrived) await _directions.finishNavigation();
      });
    } else {
      navigateToGoogleMaps();
    }
  }

  getCorrectInterface() {
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
                                    Text(
                                        getDatumEnTijdToString(
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
                                      "STATUS:",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          fontSize: 14),
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
                                          Text(
                                            "MOET WORDEN BEZORGD VOOR",
                                            style: TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          Text(
                                              getDatumEnTijdToString(bestelling[
                                                  'BezorgDatumEnTijd']),
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
                                            "STATUS:",
                                            style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                fontSize: 14),
                                          ),
                                          Text(
                                            bestelling['BestellingStatus'],
                                            style: TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      )))),
                          getProductenLijst(),
                          getAanbodPrijsWidget(),
                          getStatusWidget(bestelling['BestellingStatus'])
                        ],
                      )
                    : (bestelling['BezorgerEmail'] != connectedUserMail &&
                            (bestelling['BestellingStatus'] !=
                                "AANBIEDING GEKREGEN") &&
                            (bestelling['BestellingStatus'] != "AANVRAAG"))
                        ? Column(
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.only(
                                    top: MediaQuery.of(context).size.height *
                                        0.30,
                                    bottom: 20),
                                child: Icon(
                                  Icons.error,
                                  size: 50,
                                ),
                              ),
                              Text(
                                "Deze bestelling werd door een andere bezorger genomen...",
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                    fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        : Container(
                            child: Column(
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(
                                      top: MediaQuery.of(context).size.height *
                                          0.30,
                                      bottom: 20),
                                  child: SpinKitDoubleBounce(
                                    color: Geel,
                                    size: 30,
                                  ),
                                ),
                                Text(
                                  "Je aanbod werd gestuurd, aan " +
                                      bestelling['AankoperEmail'] +
                                      " eventjes wachten op de bevestiging..",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                      fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                                (bestelling['BestellingStatus'] == "AANVRAAG")
                                    ? getAanbodPrijsWidget()
                                    : (bestelling['BestellingStatus'] ==
                                            "AANBIEDING GEKREGEN")
                                        ? getAanbodPrijsWidget()
                                        : getTotalePrijsWidget(),
                              ],
                            ),
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

  getProductenLijst() {
    return Container(
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
                                bestellingLijst[index]['ProductAveragePrijs'])
                            .toStringAsFixed(2),
                    style: TextStyle(fontWeight: FontWeight.bold)),
                leading: Image.network(
                  bestellingLijst[index]['ProductImage'],
                  height: 50,
                  width: 50,
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
    );
  }

  getTotalePrijs() {
    totalePrijs = 0;
    bestellingLijst.forEach((product) {
      totalePrijs =
          totalePrijs + (product['Aantal'] * product['ProductAveragePrijs']);
    });

    return totalePrijs;
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
                        "€ " +
                            (getTotalePrijs() + bestelling['LeveringKosten'])
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
      padding: const EdgeInsets.only(bottom: 20.0, top: 10),
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
    bool isInLijst = false;
    aanbodLijst.forEach((aanbodMap) {
      if (aanbodMap['EmailBezorger'] == connectedUserMail) {
        print("exist in aanbod");
        isInLijst = true;
      }
    });

    return isInLijst;
  }
}
