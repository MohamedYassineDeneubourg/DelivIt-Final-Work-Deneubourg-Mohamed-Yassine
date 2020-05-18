import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

const Geel = Color(0xFFF3D511);
const GeelAccent = Color(0xFFF7E710);
const GrijsDark = Color(0xFF717070);
const GrijsMidden = Color(0xFFCCCACA);
const GrijsLicht = Color(0xFFEFEFEF);
const White = Colors.white;

num leveringPrijs = 3.5;
Map leveringGlobals;
num percentageCommisie = 0.10;

getGlobals() {
  Firestore.instance
      .collection("Globals")
      .document("Globals")
      .snapshots()
      .listen((e) {
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
