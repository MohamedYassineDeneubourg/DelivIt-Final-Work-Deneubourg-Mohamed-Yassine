import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

const Geel = Color(0xFFF3D511);
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
        Icons.sync,
        size: 30,
        color: Colors.orange,
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

getIconAankoper(status) {
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
        color: Colors.orange,
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

    case ("BESTELLING CONFIRMATIE"):
      return Icon(
        Icons.transfer_within_a_station,
        size: 30,
        color: Geel,
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



extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
