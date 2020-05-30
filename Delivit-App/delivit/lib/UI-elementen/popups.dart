  import 'package:delivit/Algemeen/portefeuille.dart';
import 'package:delivit/globals.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

nietGenoegSaldoWidget(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12.0))),
          title: new Text(
            "Onvoeldoende geld..",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: new Text(
              "Jij hebt onvoeldoende geld in je portefeuille... Gelieve geld toe te voegen."),
          actions: <Widget>[
            ButtonTheme(
                minWidth: 400.0,
                child: RaisedButton(
                  color: Geel,
                  child: Text(
                    "GA NAAR PORTEFEUILLE",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                        context, SlideTopRoute(page: Portefeuille()));
                    print("Naar portefeuille!");

                    //  signIn();
                  },
                )),
            ButtonTheme(
                minWidth: 400.0,
                child: RaisedButton(
                  color: GrijsDark,
                  child: Text(
                    "BESTELLING WIJZIGEN",
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