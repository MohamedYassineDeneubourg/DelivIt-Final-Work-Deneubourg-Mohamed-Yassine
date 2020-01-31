import 'package:flutter/material.dart';

class BestellingDetailAankoper extends StatefulWidget {
  BestellingDetailAankoper({Key key, this.bestellingId}) : super(key: key);
  final String bestellingId;

  @override
  _BestellingDetailAankoperState createState() =>
      _BestellingDetailAankoperState(bestellingId: this.bestellingId);
}

class _BestellingDetailAankoperState extends State<BestellingDetailAankoper> {
  _BestellingDetailAankoperState({Key key, @required this.bestellingId});

  String bestellingId;
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
