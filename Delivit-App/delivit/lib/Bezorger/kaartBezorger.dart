import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/Bezorger/bestellingDetailBezorger.dart';
import 'package:delivit/Functies/mapFunctions.dart';
import 'package:delivit/globals.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:location_permissions/location_permissions.dart';
import 'package:app_settings/app_settings.dart';
import 'package:lottie/lottie.dart' as Lottie;

class KaartBezorger extends StatefulWidget {
  KaartBezorger({Key key, this.title}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() => new _KaartBezorgerState();
}

class _KaartBezorgerState extends State<KaartBezorger>
    with TickerProviderStateMixin {
  String connectedUserMail;
  Position userPosition;
  double paddingButton = 0;
  List<Marker> opMapBestellingen = [];

  DateTime startTimerForUpdate;

  Map selectedBestelling = {
    "documentID": null,
    'AantalProducten': " ",
    "Adres": 'Geen adres gevonden...',
    "Distance": "0"
  };

  MapController mapController = new MapController();
  MarkerClusterPlugin markerClusterPlugin;

  bool followUser = false;

  StreamSubscription<Position> _getPositionSubscription;

  StreamSubscription<QuerySnapshot> _getFirebaseSubscription;

  @override
  void dispose() {
    if (_getFirebaseSubscription != null) {
      _getFirebaseSubscription.cancel();
    }
    if (_getPositionSubscription != null) {
      _getPositionSubscription.cancel();
    }
    super.dispose();
  }

  @override
  initState() {
    getCurrentUser();
    startTimerForUpdate = DateTime.now();
    _getData();
    super.initState();
  }

  void getCurrentUser() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    //print(user);
    if (user != null) {
      setState(() {
        connectedUserMail = user.email;
      });
    }
  }

  _getData() async {
    await LocationPermissions().requestPermissions();

    ServiceStatus serviceStatus =
        await LocationPermissions().checkServiceStatus();
    if (serviceStatus == ServiceStatus.disabled) {
      AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0))),
        title: Text("GPS niet geactiveerd"),
        content: SingleChildScrollView(
          child: Text(
              "Je moet je GPS-optie op uw toestel activeren om door te kunnen gaan."),
        ),
        actions: <Widget>[
          FlatButton(
            child: Text("Naar instellingen"),
            onPressed: () {
              AppSettings.openLocationSettings();

              Navigator.of(context).pop();
            },
          ),
        ],
      );
    }

    var geolocator = Geolocator();
    GeolocationStatus geolocationStatus =
        await geolocator.checkGeolocationPermissionStatus();
    var locationOptions = LocationOptions(
        accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 0);

    if (geolocationStatus == GeolocationStatus.granted) {
      Position position = await geolocator
          .getCurrentPosition(
              desiredAccuracy: LocationAccuracy.bestForNavigation)
          .catchError((e) {
        print(e);
      });
      if (this.mounted) {
        setState(() {
          userPosition = position;
        });
      }
    }

    if (geolocationStatus == GeolocationStatus.granted) {
      _getPositionSubscription = geolocator
          .getPositionStream(locationOptions)
          .listen((Position position) {
        if (this.mounted) {
          setState(() {
            userPosition = position;
          });
          if (followUser) {
            verplaatsKaart(mapController,
                LatLng(position.latitude, position.longitude), 18, this);
          }
          //Hier print ik de timer:
          //  print(DateTime.now().difference(startTimerForUpdate).inSeconds);

//Wanneer 10seconden gepasseerd zijn, ga ik updaten
          if (DateTime.now().difference(startTimerForUpdate).inSeconds > 10) {
            Firestore.instance
                .collection('Users')
                .document(connectedUserMail)
                .updateData({
              "Position": {
                'latitude': position.latitude,
                'longitude': position.longitude,
              }
            });
          }
        }
      });
    }

    _getFirebaseSubscription = Firestore.instance
        .collection('Commands')
        .where("isBeschikbaar", isEqualTo: true)
        .snapshots()
        .listen((querySnapshot) {
      //print("NEW ON MAP");
      opMapBestellingen = [];
      for (int i = 0; i < querySnapshot.documents.length; i++) {
        DocumentSnapshot bestelling = querySnapshot.documents[i];
        Map positionMap = bestelling['AdresPosition'];

        if (connectedUserMail != bestelling['AankoperEmail']) {
          if (opMapBestellingen != null) {
            opMapBestellingen.add(
              new Marker(
                width: 100.0,
                height: 100.0,
                point: new LatLng(
                    positionMap['latitude'], positionMap['longitude']),
                builder: (ctx) => new Container(
                    child: Column(
                  children: <Widget>[
                    new RawMaterialButton(
                      padding: (selectedBestelling['documentID'] ==
                              bestelling.documentID)
                          ? EdgeInsets.all(10)
                          : EdgeInsets.all(2),
                      onPressed: () async {
                        _toonPopupMarker(context, bestelling);
                        setState(() {
                          selectedBestelling['documentID'] =
                              bestelling.documentID;
                        });
                        print(selectedBestelling);
                      },
                      child: new Icon(
                        Icons.shopping_cart,
                        color: Geel,
                        size: 25.0,
                      ),
                      shape: new CircleBorder(),
                      elevation: 2.0,
                      fillColor: Colors.white,
                    )
                  ],
                )),
              ),
            );
          }
          setState(() {
            opMapBestellingen = opMapBestellingen;
          });
        }
      }
    });
    if (this.mounted) {
      setState(() {
        markerClusterPlugin = MarkerClusterPlugin();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userPosition != null) {
      return Scaffold(
        floatingActionButton: Stack(
          children: <Widget>[
            Padding(
                padding: EdgeInsets.only(bottom: paddingButton),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: FloatingActionButton(
                    backgroundColor: followUser ? Colors.blue : Colors.white,
                    onPressed: () {
                      verplaatsKaart(
                          mapController,
                          LatLng(userPosition.latitude, userPosition.longitude),
                          18,
                          this);
                      if (this.mounted) {
                        setState(() {
                          followUser = !followUser;
                        });
                      }
                    },
                    child: Icon(
                      FontAwesomeIcons.crosshairs,
                      color: followUser ? Colors.white : GrijsDark,
                    ),
                  ),
                )),
          ],
        ),
        body: new FlutterMap(
          mapController: mapController,
          options: new MapOptions(
            onTap: (LatLng eo) {
              if (this.mounted) {
                setState(() {
                  followUser = false;
                  paddingButton = 0;
                  selectedBestelling['documentID'] = "";
                });
              }
            },
            center: new LatLng(userPosition.latitude, userPosition.longitude),
            plugins: [markerClusterPlugin],
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
              markers: [
                new Marker(
                  anchorPos: AnchorPos.align(AnchorAlign.center),
                  width: 35.0,
                  height: 35.0,
                  point: new LatLng(
                    userPosition.latitude,
                    userPosition.longitude,
                  ),
                  builder: (ctx) => new Container(
                    child: new RawMaterialButton(
                      onPressed: null,
                      child: Transform.rotate(
                          angle: userPosition.heading,
                          child: Icon(
                            Icons.person_pin,
                            color: Colors.white,
                            size: 20.0,
                          )),
                      shape: new CircleBorder(),
                      elevation: 1.0,
                      fillColor: Colors.blue,
                    ),
                  ),
                )
              ],
            ),
            (markerClusterPlugin != null && opMapBestellingen.isNotEmpty)
                ? MarkerClusterLayerOptions(
                    markers: opMapBestellingen,
                    polygonOptions: PolygonOptions(
                        borderColor: Geel, color: White, borderStrokeWidth: 10),
                    maxClusterRadius: 120,
                    size: Size(35, 35),
                    builder: (context, markers) {
                      return FloatingActionButton(
                        heroTag: "markers",
                        child: Text(
                          markers.length.toString(),
                          style: TextStyle(
                              color: GrijsDark, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Geel,
                        onPressed: null,
                      );
                    },
                  )
                : MarkerLayerOptions(
                    markers: opMapBestellingen,
                  ),
          ],
        ),
      );
    } else {
      return Container(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
            SpinKitDoubleBounce(
              color: Geel,
              size: 100,
            ),
            Padding(
                padding: const EdgeInsets.only(top: 100.0),
                child: RaisedButton.icon(
                    onPressed: () {
                      AppSettings.openLocationSettings();
                    },
                    label: Text(
                      "Localisatie & Wifi activeren",
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                    icon: Lottie.Lottie.asset('assets/Animations/settings.json',
                        width: 30))),
          ]));
    }
  }

  _toonPopupMarker(context, DocumentSnapshot selectedBestelling) async {
    String distance =
        await getDistance(selectedBestelling['AdresPosition'], userPosition);
    showModalBottomSheet(
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        context: context,
        builder: (BuildContext context) {
          return Container(
            padding: EdgeInsets.only(top: 10, bottom: 30),
            decoration: BoxDecoration(
                color: White,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.only(
                          top: 4, right: 0, left: 15, bottom: 4),
                      onTap: () {
                        naarDetailBestelling(selectedBestelling.documentID);
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(distance.toString() + "km",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                              icon: Icon(Icons.arrow_forward_ios),
                              onPressed: () {
                                naarDetailBestelling(
                                    selectedBestelling.documentID);
                              })
                        ],
                      ),
                      leading: CircleAvatar(
                        child: Icon(
                          Icons.shopping_cart,
                          color: Colors.black,
                          size: 20,
                        ),
                        backgroundColor: GeelAccent,
                      ),
                      title: Text(
                        getDatumEnTijdToString(
                            selectedBestelling['BezorgDatumEnTijd']),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(selectedBestelling['Adres']),
                    )),
                AutoSizeText(
                    (selectedBestelling['BestellingLijst'].length).toString() +
                        " PRODUCTEN TE BEZORGEN",
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    )),
              ],
            ),
          );
        });
  }

  void naarDetailBestelling(bestellingId) {
    Navigator.push(
        context,
        SlideTopRoute(
          page: BestellingDetailBezorger(
            bestellingId: bestellingId,
            connectedUserMail: connectedUserMail,
          ),
        ));
  }
}
