import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong/latlong.dart';
import 'package:intl/intl.dart';

const Geel = Color(0xFFF3D511);
const GeelDark = Color(0xFFada766);

const GeelAccent = Color(0xFFF7E710);
const GrijsDark = Color(0xFF717070);
const GrijsMidden = Color(0xFFCCCACA);
const GrijsLicht = Color(0xFFEFEFEF);
const White = Colors.white;
const Black = Colors.black;

num leveringPrijs = 3.5;
Map leveringGlobals;
num percentageCommisie = 0.10;
StreamSubscription getFirebaseGlobalSubscription;
String serverUrlGlobals;
getGlobals() {
  getFirebaseGlobalSubscription = Firestore.instance
      .collection("Globals")
      .document("Globals")
      .snapshots()
      .listen((e) {});

  getFirebaseGlobalSubscription.onData((e) {
    print("------------------------- YOOOOO");
    DateTime beginNachtijd = e.data['BeginNachtTijd'].toDate();
    DateTime eindeNachtTijd = e.data['EindeNachtTijd'].toDate();
    int actueeltijd = DateTime.now().hour;

    double leveringprijsOk;

    if (actueeltijd < beginNachtijd.hour && actueeltijd > eindeNachtTijd.hour) {
      //Dag-leveringkosten:
      leveringprijsOk = e.data['LeveringKosten'].toDouble();
    } else {
      leveringprijsOk = e.data['NachtLeveringKosten'].toDouble();
    }
    percentageCommisie = e.data["PercentageCommisie"];
    leveringPrijs = leveringprijsOk;
    leveringGlobals = e.data;
    serverUrlGlobals = e.data['ServerUrl'];
  });
}

void verplaatsKaart(MapController mapController, LatLng destLocation,
    double destZoom, var vsync) {
  final _latTween = Tween<double>(
      begin: mapController.center.latitude, end: destLocation.latitude);
  final _lngTween = Tween<double>(
      begin: mapController.center.longitude, end: destLocation.longitude);
  final _zoomTween = Tween<double>(begin: mapController.zoom, end: destZoom);

  var controller =
      AnimationController(duration: Duration(milliseconds: 500), vsync: vsync);

  Animation<double> animation =
      CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

  controller.addListener(() {
    mapController.move(
        LatLng(_latTween.evaluate(animation), _lngTween.evaluate(animation)),
        _zoomTween.evaluate(animation));
  });

  animation.addStatusListener((status) {
    if (status == AnimationStatus.completed) {
      controller.dispose();
    } else if (status == AnimationStatus.dismissed) {
      controller.dispose();
    }
  });

  controller.forward();
}

class SlideTopRoute extends PageRouteBuilder {
  final Widget page;
  SlideTopRoute({this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
}

getDatumEnTijdToString(timestamp) {
  if (timestamp == null) {
    return "00/00/0000 - 00:00";
  }
  String datum = new DateFormat.d().format(timestamp.toDate()).toString() +
      "/" +
      DateFormat.M().format(timestamp.toDate()).toString() +
      "/" +
      DateFormat.y().format(timestamp.toDate()).toString();

  String tijd = new DateFormat.Hm().format(timestamp.toDate()).toString();

  return datum + " - " + tijd;
}

getDatumToString(timestamp) {
  if (timestamp == null) {
    return "00/00/0000";
  }
  String datum = new DateFormat.d().format(timestamp.toDate()).toString() +
      "/" +
      DateFormat.M().format(timestamp.toDate()).toString() +
      "/" +
      DateFormat.y().format(timestamp.toDate()).toString();

  return datum;
}

getIconBezorger(status) {
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

    case ("PRODUCTEN VERZAMELEN"):
      return Icon(
        Icons.shopping_cart,
        size: 30,
        color: Geel,
      );
      break;

    case ("ONDERWEG"):
      return Icon(
        Icons.directions_bike,
        size: 30,
        color: Geel,
      );
      break;

    case ("BESTELLING CONFIRMATIE"):
      return Icon(
        Icons.access_time,
        size: 30,
        color: Colors.orange,
      );
      break;
    case ("BEZORGD"):
      return Icon(
        Icons.check,
        size: 30,
        color: Geel,
      );
      break;

    case ("GEANNULEERD"):
      return Icon(
        Icons.delete,
        size: 30,
        color: Colors.redAccent.withOpacity(0.4),
      );
      break;

    default:
      return Icon(
        Icons.help_outline,
        size: 30,
        color: Geel,
      );
      break;
  }
}

passwordreset(connectedUserMail, context) {
  FirebaseAuth.instance.sendPasswordResetEmail(email: connectedUserMail);
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0))),
        title: new Text(
          "WACHTWOORD",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.check_circle, size: 24, color: Geel),
            SizedBox(
              height: 10,
            ),
            Text(
                "Je hebt een mail gekregen op " +
                    connectedUserMail +
                    " om je wachtwoord te wijzigen.",
                style: TextStyle(fontWeight: FontWeight.bold))
          ],
        ),
        actions: <Widget>[
          ButtonTheme(
              minWidth: 400.0,
              child: RaisedButton(
                color: GrijsDark,
                child: Text(
                  "OK",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ))
        ],
      );
    },
  );
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
