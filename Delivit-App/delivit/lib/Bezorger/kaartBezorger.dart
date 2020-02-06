import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:location_permissions/location_permissions.dart';
import 'package:app_settings/app_settings.dart';

class KaartBezorger extends StatefulWidget {
  KaartBezorger({Key key, this.title}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() => new _KaartBezorgerState();
}

class _KaartBezorgerState extends State<KaartBezorger> {
  String userEmail;
  Position userPosition;
  bool isVisible = false;
  double paddingButton = 0;
  List<Marker> opMapBestellingen = [];
  List<Marker> currentUserPin = [];
  Map selectedBestelling = {
    "documentID": null,
    'AantalProducten': " ",
    "Adres": 'Geen adres gevonden...',
    "Distance": "0"
  };
  MapController mapController = new MapController();
  @override
  initState() {
    super.initState();
    _getData();
  }

  _getData() async {
    print('!GetData?');

    ServiceStatus serviceStatus =
        await LocationPermissions().checkServiceStatus();
    print(serviceStatus);
    if (serviceStatus == ServiceStatus.disabled) {
      AlertDialog(
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
    print(geolocationStatus);
    final FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();

    var locationOptions = LocationOptions(
        accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 0);
    print('!GeoLocator?');

    geolocator.getPositionStream(locationOptions).listen((Position position) {
      if (this.mounted) {
        setState(() {
          userPosition = position;
        });
      }

      currentUserPin = [
        new Marker(
          width: 35.0,
          height: 35.0,
          point: new LatLng(userPosition.latitude, userPosition.longitude),
          builder: (ctx) => new Container(
            child: new RawMaterialButton(
              onPressed: null,
              child: new Icon(
                Icons.person_pin,
                color: Colors.white,
                size: 20.0,
              ),
              shape: new CircleBorder(),
              elevation: 1.0,
              fillColor: Colors.blue,
            ),
          ),
        )
      ];
      Firestore.instance
          .collection('Users')
          .document(currentUser.email)
          .updateData({
        "Position": {
          'latitude': position.latitude,
          'longitude': position.longitude,
        }
      });
    });

    Firestore.instance
        .collection('Commands')
        .where("isBeschikbaar", isEqualTo: true)
        .snapshots()
        .listen((querySnapshot) {
      print("NEW ON MAP");

      for (int i = 0; i < querySnapshot.documents.length; i++) {
        DocumentSnapshot bestelling = querySnapshot.documents[i];
        Map positionMap = bestelling['AdresPosition'];
        print("NEW ON " + i.toString());
        opMapBestellingen.add(
          new Marker(
            width: 100.0,
            height: 100.0,
            point:
                new LatLng(positionMap['latitude'], positionMap['longitude']),
            builder: (ctx) => new Container(
                child: Column(
              children: <Widget>[
                new RawMaterialButton(
                  padding: (selectedBestelling['documentID'] ==
                          bestelling.documentID)
                      ? EdgeInsets.all(10)
                      : EdgeInsets.all(2),
                  onPressed: () async {
                    String distance =
                        await getDistance(bestelling['AdresPosition']);
                    print("yo");
                    print(distance);
                    setState(() {
                      selectedBestelling = {
                        "AantalProducten":
                            (bestelling['BestellingLijst'].length).toString() +
                                " Prod. te bezorgen",
                        "Adres": bestelling['Adres'],
                        "Distance": distance,
                        "documentID": bestelling.documentID
                      };
                      print(bestelling['AdresPosition']);
                      isVisible = true;
                      paddingButton = 100;
                    });
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
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userPosition != null) {
      return Scaffold(
          floatingActionButton: Stack(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(left: 31),
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Visibility(
                        visible: isVisible,
                        child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.only(
                                  top: 4, right: 0, left: 15, bottom: 4),
                              onTap: () {
                                naarDetailBestelling(
                                    selectedBestelling['documentID']);
                              },
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(selectedBestelling['Distance'] + "km",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  IconButton(
                                      icon: Icon(Icons.arrow_forward_ios),
                                      onPressed: () {
                                        naarDetailBestelling(
                                            selectedBestelling['documentID']);
                                      })
                                ],
                              ),
                              leading: CircleAvatar(
                                child: Icon(
                                  Icons.shopping_cart,
                                  color: GrijsDark,
                                  size: 20,
                                ),
                                backgroundColor: GeelAccent,
                              ),
                              title: Text(selectedBestelling['AantalProducten'],
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(selectedBestelling['Adres']),
                            )))),
              ),
              Padding(
                  padding: EdgeInsets.only(bottom: paddingButton),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: FloatingActionButton(
                      backgroundColor: Colors.white,
                      onPressed: () {
                        mapController.move(
                            LatLng(
                                userPosition.latitude, userPosition.longitude),
                            18);
                      },
                      child: Icon(
                        FontAwesomeIcons.crosshairs,
                        color: GrijsDark,
                      ),
                    ),
                  )),
            ],
          ),
          body: new FlutterMap(
            mapController: mapController,
            options: new MapOptions(
              onTap: (LatLng eo) {
                setState(() {
                  isVisible = false;
                  paddingButton = 0;
                  selectedBestelling['documentID'] = "";
                });
              },
              center: new LatLng(userPosition.latitude, userPosition.longitude),
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
                markers: currentUserPin..addAll(opMapBestellingen),
              ),
            ],
          ));
    } else {
      return Container(
        child: SpinKitDoubleBounce(
          color: Geel,
          size: 100,
        ),
      );
    }
  }

  getDistance(adresPosition) async {
    double distance = await Geolocator().distanceBetween(
        adresPosition['latitude'],
        adresPosition['longitude'],
        userPosition.latitude,
        userPosition.longitude);
    return (distance / 1000).toStringAsFixed(1);
  }

  void naarDetailBestelling(bestellingId) {
    print(bestellingId);
  }
}
