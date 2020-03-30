library delivit.globals;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
