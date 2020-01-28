import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BestellingConfirmAankoper extends StatefulWidget {
  @override
  _BestellingConfirmAankoperState createState() =>
      _BestellingConfirmAankoperState();
}

class _BestellingConfirmAankoperState extends State<BestellingConfirmAankoper> {
  List _productenLijst = new List();
  String userEmail;
  List bestellingLijst = new List();
  void _getData() async {
    final FirebaseUser userData = await FirebaseAuth.instance.currentUser();
    if (userData != null) {
      userEmail = userData.email;
      var reference =
          Firestore.instance.collection("Users").document(userData.email);

      reference.snapshots().listen((querySnapshot) {
        if (this.mounted) {
          setState(() {
            print("Refreshed");
            _productenLijst = querySnapshot.data['ShoppingBag'];
            _productenLijst.forEach((product) {
              Map productMap = {"ProductID": product, "Aantal": 1};

              bestellingLijst.add(productMap);
            });
          });
        }
      });
    }
  }

  @override
  void initState() {
    print("init!");
    _getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        body: new Container(
            padding: new EdgeInsets.only(top: 8.0, bottom: 20),
            child: new Center(
              child: new Expanded(
                  child: new ListView.builder(
                itemCount: bestellingLijst.length,
                itemBuilder: (context, index) {
                  var reference = Firestore.instance
                      .collection("Users")
                      .document(bestellingLijst[index]['ProductID'])
                      .get();

                  reference.then((product) {
                    return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: ListTile(
                          onLongPress: () {
                            _showDeleteVraag(_productenLijst[index]);
                          },
                          onTap: () {
                            // goToDetail(_productenLijst[index]);
                          },
                          trailing: Text(_productenLijst[index]["Aantal"]),
                          leading: CircleAvatar(
                            backgroundColor: Geel,
                          ),
                          title: Text('${product['ProductTitel']}',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${product['ProductBeschrijving']}'),
                        ));
                  });

                  return null;
                },
              )),
            )),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: FloatingActionButton.extended(
            heroTag: "ButtonBestelling",
            splashColor: GrijsDark,
            elevation: 4.0,
            backgroundColor: Geel,
            icon: const Icon(
              FontAwesomeIcons.check,
              color: White,
            ),
            label: Text(
              "BESTELLING BEVESTIGEN",
              style: TextStyle(color: White, fontWeight: FontWeight.w800),
            ),
            onPressed: confirmBestelling,
          ),
        ));
  }

  void confirmBestelling() async {
    /* Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddTodo(
                title: "Nieuwe Todo",
              ),
          fullscreenDialog: true),
    ); */
  }

  void _showDeleteVraag(Map todoMap) {
    String productNaam = "'" + todoMap['ProductTitel'] + "'";
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Verwijderen?"),
          content: new Text("Wil je $productNaam Verwijderen?"),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            FlatButton(
              color: Geel,
              child: new Text(
                "Ja",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                verwijderVanBestelling(todoMap);
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

  verwijderVanBestelling(Map productMap) async {
    print(userEmail);
    Firestore.instance.collection('Users').document(userEmail).updateData({
      "Todos": FieldValue.arrayRemove([productMap])
    }).then((l) {
      Navigator.of(context).pop();
      print('Verwijderd!');
    });
  }
}
