import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:todo_yassine/gebruikerPagina.dart';

import 'dialog_modal.dart';

class BetaalPersoon extends StatefulWidget {
  BetaalPersoon({Key key, this.persoonEmail}) : super(key: key);
  final String persoonEmail;
  @override
  _BetaalPersoonState createState() =>
      _BetaalPersoonState(persoonEmail: this.persoonEmail);
}

class _BetaalPersoonState extends State<BetaalPersoon> {
  _BetaalPersoonState({Key key, this.persoonEmail});
  final String persoonEmail;
  double stuurGeld = 1.00;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          centerTitle: true, 
          title: Text("Betaal"),
        ),
        floatingActionButton: FloatingActionButton.extended(
            elevation: 4.0,
            icon: const Icon(Icons.compare_arrows),
            label: const Text('Stuur geld'),
            onPressed: () {
              _bevestigGeldSturen();
            }),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          child: new Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                icon: Icon(null),
                onPressed: () {},
              ),
            ],
          ),
        ),
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
              Icon(Icons.monetization_on, size: 200),
              Center(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text("€ $stuurGeld", style: TextStyle(fontSize: 45)),
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: Colors.green,
                    ),
                    onPressed: () {
                      _showDialog();
                    },
                  ),
                ],
              )),
              Text(
                "Aan $persoonEmail",
                style: TextStyle(fontSize: 20),
              )
            ])));
  }

  Future _showDialog() async {
    await showDialog<num>(
      context: context,
      builder: (BuildContext context) {
        return new NumberPickerDialog.decimal(
          minValue: 1,
          maxValue: 999,
          decimalPlaces: 2,
          initialDoubleValue: stuurGeld,
          title: new Text("Voeg geld toe"),
        );
      },
    ).then((num value) {
      print(value);
      if (value != null && value >= 1) {
        if (this.mounted){ 
        setState(() => stuurGeld = value);
        }
      }
    });
  }

  void _bevestigGeldSturen() {
    // flutter defined function
    if (stuurGeld <= 0) {
      showAlertDialog(
          context: context,
          title: "Niet mogelijk..",
          description: "Je moet meer dan €1 geld sturen");
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            title: new Text("Bevestiging"),
            content: new Text("Wil je $stuurGeld aan $persoonEmail sturen ?"),
            actions: <Widget>[
              // usually buttons at the bottom of the dialog
              FlatButton(
                color: Colors.amber,
                child: new Text(
                  "Ja",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  _geldSturen();
                },
              ),
              FlatButton(
                child: new Text("Neen"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        },
      );
    }
  }

  void _geldSturen() async {
    final FirebaseUser userData = await FirebaseAuth.instance.currentUser();
    String currentUserEmail = userData.email;
    num userGeld = 0.0;

    await Firestore.instance
        .collection("Users")
        .document(currentUserEmail)
        .get()
        .then((onValue) {
      print(onValue.data);
      userGeld = onValue.data['GeldEuro'];
      print(" the: $userGeld");

      print(userGeld);
      if (userGeld >= stuurGeld) {
        print(userGeld);
        print(stuurGeld);
        Firestore.instance
            .collection('Users')
            .document(currentUserEmail)
            .updateData({"GeldEuro": FieldValue.increment(-stuurGeld)}).then(
                (l) {
          print('GELD UIT CURRENT ACCOUNT GEHAALD');

          Firestore.instance
              .collection('Users')
              .document(persoonEmail)
              .updateData({"GeldEuro": FieldValue.increment(stuurGeld)}).then(
                  (l) {
            print('GELD IS AAN PERSOON GESTUURD');
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                      title: new Text("Geld is gestuurd!"),
                      content: Icon(Icons.verified_user,
                          color: Colors.green, size: 50));
                });
          });
        });
      } else {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return Center(
                  child: AlertDialog(
                title: new Text("Niet genoeg geld.."),
                content: Icon(Icons.error_outline, color: Colors.red, size: 50),
                actions: <Widget>[
                  RaisedButton.icon(
                    icon: Icon(
                      Icons.add_box,
                      color: Colors.black,
                    ),
                    label: Text(
                      "Voeg geld",
                      style: TextStyle(color: Colors.black),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GebruikerPagina()),
                      );
                    },
                  )
                ],
              ));
            });
      }
    });
  }
}
