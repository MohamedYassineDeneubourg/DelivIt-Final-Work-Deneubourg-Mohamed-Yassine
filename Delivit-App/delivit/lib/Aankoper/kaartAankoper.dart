import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/globals.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
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

class _KaartAankoperState extends State<KaartAankoper> {
  String userEmail;
  Position userPosition;
  bool isVisible = false;
  double paddingButton = 0;
  List<Marker> opMapUsers = [];
  Map selectedUser = {'naam': " ", "email": 'test@test.be'};
  MapController mapController = new MapController();
  @override
  initState() {
    super.initState();
    _getData();
  }

  showGpsSettings() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new AlertDialog(
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
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.lowest)
        .catchError((e) {
      print(e);
    });
    setState(() {
      userPosition = position;
    });

    var locationOptions =
        LocationOptions(accuracy: LocationAccuracy.lowest, distanceFilter: 0);

    Firestore.instance.collection('Users').snapshots().listen((querySnapshot) {
      //print("NEW ON MAP");
      opMapUsers = [
          
      new Marker(
        width: 35.0,
        height: 35.0,
        point: new LatLng(userPosition.latitude, userPosition.longitude),
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
        ),)

      ];
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
                      selectedUser = {
                        "naam": gebruiker['Naam'],
                        "email": gebruiker.documentID
                      };
                      isVisible = true;
                      paddingButton = 100;
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

    geolocator.getPositionStream(locationOptions).listen((Position position) {
      if (this.mounted) {
        setState(() {
          userPosition = position;
        });
      }
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
                              leading: CircleAvatar(
                                backgroundColor: GeelAccent,
                              ),
                              title: Text(selectedUser['naam'],
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(selectedUser['email']),
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
                isVisible = false;
                paddingButton = 0;
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
}
