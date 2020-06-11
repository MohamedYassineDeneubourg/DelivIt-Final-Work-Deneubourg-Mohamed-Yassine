import 'package:flutter/animation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong/latlong.dart';

getDistance(position, userPosition) async {
  double distance = await Geolocator().distanceBetween(position['latitude'],
      position['longitude'], userPosition.latitude, userPosition.longitude);
  return (distance / 1000).toStringAsFixed(1);
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
