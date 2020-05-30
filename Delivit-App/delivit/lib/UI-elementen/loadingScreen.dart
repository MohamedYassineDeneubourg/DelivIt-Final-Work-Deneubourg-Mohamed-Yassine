import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:delivit/globals.dart';

Widget loadingScreen = Stack(children: <Widget>[
  Container(
    decoration: new BoxDecoration(color: Geel.withOpacity(0.5)),
    child: new BackdropFilter(
      filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
      child: SpinKitDoubleBounce(
        color: Geel,
        size: 200,
      ),
    ),
  ),
  SpinKitDoubleBounce(
    color: GeelAccent,
    size: 60,
  ),
  SpinKitDualRing(
    color: Colors.white,
  )
]);
