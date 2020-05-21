import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/globals.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:location_permissions/location_permissions.dart';
import 'package:app_settings/app_settings.dart';
import 'package:lottie/lottie.dart';

class KaartAankoper extends StatefulWidget {
  KaartAankoper({Key key, this.title}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() => new _KaartAankoperState();
}

class _KaartAankoperState extends State<KaartAankoper>
    with TickerProviderStateMixin {
  String connectedUserMail;
  Position userPosition;
  List<Marker> opMapUsers = [];
  MapController mapController = new MapController();
  DateTime startTimerForUpdate;
  bool followUser = false;
  StreamSubscription _getPositionSubscription;
  StreamSubscription _getFirebaseSubscription;

  void getCurrentUser() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    //print(user);
    if (user != null) {
      setState(() {
        connectedUserMail = user.email;
      });
    }
  }

  @override
  void dispose() {
    _getPositionSubscription.cancel();
    _getFirebaseSubscription.cancel();
    super.dispose();
  }

  @override
  initState() {
    getCurrentUser();
    startTimerForUpdate = DateTime.now();
    super.initState();
    _getData();
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

  _getData() async {
    print('!GetData?');

    ServiceStatus serviceStatus =
        await LocationPermissions().checkServiceStatus();
    print(serviceStatus);
    if (serviceStatus == ServiceStatus.disabled) {
      showGpsSettings();
    }
    var geolocator = Geolocator();
    GeolocationStatus geolocationStatus =
        await geolocator.checkGeolocationPermissionStatus();
    print(geolocationStatus);
    final FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();
    print(userPosition);

    Position position = await geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation)
        .catchError((e) {
      print(e);
    });
    if (this.mounted) {
      setState(() {
        userPosition = position;
      });
    }

    var locationOptions = LocationOptions(
        accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 0);

    _getFirebaseSubscription = Firestore.instance
        .collection('Users')
        .snapshots()
        .listen((querySnapshot) {
      print("NEW ON MAP");
      for (int i = 0; i < querySnapshot.documents.length; i++) {
        DocumentSnapshot gebruiker = querySnapshot.documents[i];
        Map positionMap = gebruiker['Position'];
        if (gebruiker.documentID != currentUser.email) {
          opMapUsers.add(
            new Marker(
              width: 100.0,
              height: 100.0,
              point:
                  new LatLng(positionMap['latitude'], positionMap['longitude']),
              builder: (ctx) => new Container(
                  child: Column(
                children: <Widget>[
                  Text(gebruiker['Naam']),
                  new RawMaterialButton(
                    onPressed: () {
                      print("click");
                      _toonPopupMarker(context, gebruiker);
                      print('Follow user?');
                      if (this.mounted) {
                        setState(() {
                          followUser = false;
                        });
                      }
                    },
                    child: new Icon(
                      Icons.motorcycle,
                      color: Geel,
                      size: 30.0,
                    ),
                    shape: new CircleBorder(),
                    elevation: 2.0,
                    fillColor: Colors.white,
                  ),
                ],
              )),
            ),
          );
        }
      }
    });

    _getPositionSubscription = geolocator
        .getPositionStream(locationOptions)
        .listen((Position position) {
      print("GET POSITION IN AANKOPER");
      if (this.mounted) {
        setState(() {
          userPosition = position;
        });
      }
      if (followUser) {
        verplaatsKaart(mapController,
            LatLng(position.latitude, position.longitude), 18, this);
      }
      //Hier print ik de timer:
      //  print(DateTime.now().difference(startTimerForUpdate).inSeconds);

//Wanneer 10seconden gepasseerd zijn, ga ik updaten
      if (DateTime.now().difference(startTimerForUpdate).inSeconds > 10) {
        print("UPDATE POSITION AANKOPER!");
        //   print('10seconds passed');
        Firestore.instance
            .collection('Users')
            .document(connectedUserMail)
            .updateData({
          "Position": {
            'latitude': position.latitude,
            'longitude': position.longitude,
          }
        });
        if (this.mounted) {
          setState(() {
            startTimerForUpdate = DateTime.now();
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userPosition != null) {
      return Scaffold(
          floatingActionButton: FloatingActionButton(
            backgroundColor: followUser ? Colors.blue : Colors.white,
            onPressed: () {
              setState(() {
                followUser = !followUser;
              });
              verplaatsKaart(
                  mapController,
                  LatLng(userPosition.latitude, userPosition.longitude),
                  18,
                  this);
            },
            child: Icon(
              FontAwesomeIcons.crosshairs,
              color: followUser ? Colors.white : GrijsDark,
            ),
          ),
          body: new FlutterMap(
            mapController: mapController,
            options: new MapOptions(
              onTap: (LatLng eo) {
                followUser = false;
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
                markers: [
                  new Marker(
                    width: 35.0,
                    height: 35.0,
                    point: new LatLng(
                        userPosition.latitude, userPosition.longitude),
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
              new MarkerLayerOptions(
                markers: opMapUsers,
              ),
            ],
          ));
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
                    icon: Lottie.asset('assets/Animations/settings.json',
                        width: 30))),
          ]));
    }
  }

  _toonPopupMarker(context, DocumentSnapshot persoon) async {
    String distance = await getDistance(persoon['Position']);
    print(distance);
    showModalBottomSheet(
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        context: context,
        builder: (BuildContext context) {
          return Container(
            decoration: BoxDecoration(
                color: White,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20))),
            child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: ListTile(
                  contentPadding:
                      EdgeInsets.only(top: 4, right: 0, left: 15, bottom: 4),
                  onTap: () {
                    //naar profiel pagina
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(distance.toString() + "km",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                          icon: Icon(Icons.arrow_forward_ios),
                          onPressed: () {
                            //NAAR PROFIEL PAGINA
                          })
                    ],
                  ),
                  leading: Image.network(
                    persoon['ProfileImage'],
                    height: 40,
                  ),
                  title: Text((persoon['Naam']) + (persoon['Voornaam']),
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: RatingBarIndicator(
                    rating: persoon['RatingScore'],
                    itemBuilder: (context, index) => Icon(
                      Icons.star,
                      color: Geel,
                    ),
                    itemCount: 5,
                    itemSize: 20.0,
                    direction: Axis.horizontal,
                  ),
                )),
          );
        });
  }

  getDistance(position) async {
    double distance = await Geolocator().distanceBetween(position['latitude'],
        position['longitude'], userPosition.latitude, userPosition.longitude);
    return (distance / 1000).toStringAsFixed(1);
  }
}
