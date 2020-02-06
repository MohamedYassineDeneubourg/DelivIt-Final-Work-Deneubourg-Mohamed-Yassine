import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/Aankoper/laatsteStapBestellingAankoper.dart';
import 'package:delivit/colors.dart';
import 'package:delivit/portefeuille.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BestellingConfirmAankoper extends StatefulWidget {
  @override
  _BestellingConfirmAankoperState createState() =>
      _BestellingConfirmAankoperState();
}

class _BestellingConfirmAankoperState extends State<BestellingConfirmAankoper> {
  List _productenLijst = [];
  String userEmail;
  List bestellingLijst = [];
  String connectedUserMail;
  double totalePrijs = 0.0;
  void getCurrentUser() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    print(user);
    if (user != null) {
      setState(() {
        connectedUserMail = user.email;
      });
    }
  }

  void _getData() async {
    final FirebaseUser userData = await FirebaseAuth.instance.currentUser();
    if (userData != null) {
      userEmail = userData.email;
      var reference =
          Firestore.instance.collection("Users").document(userData.email).get();

      reference.then((data) {
        if (this.mounted) {
          setState(() {
            print("Refreshed");
            _productenLijst = []..addAll(data.data['ShoppingBag']);
            _productenLijst.forEach((product) {
              var reference = Firestore.instance
                  .collection("Products")
                  .document(product)
                  .get();

              reference.then((data) {
                print(data);

                Map productMap = {
                  "ProductID": product,
                  "Aantal": 1,
                  "ProductTitel": data.data["ProductTitel"],
                  "ProductAveragePrijs": data.data['ProductAveragePrijs'],
                  "ProductImage": data.data['ProductImage']
                };

                setState(() {
                  bestellingLijst.add(productMap);
                });
              });
              print(product);
            });
          });
        }
        setState(() {
          getTotalePrijs();
        });
      });
    }
  }

  @override
  void initState() {
    print("init!");
    getCurrentUser();
    _getData();
    setState(() {
      getTotalePrijs();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: White,
        textTheme: TextTheme(
            title: TextStyle(
                color: Geel,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                fontFamily: "Montserrat")),
        centerTitle: true,
        title: new Text("BEVESTIGING"),
      ),
      body: new Container(
          height: size.height * 0.78,
          padding:
              new EdgeInsets.only(top: 8.0, bottom: 20, right: 15, left: 15),
          child: new Column(
            children: <Widget>[
              new Expanded(
                  child: new ListView.builder(
                itemCount: bestellingLijst.length,
                itemBuilder: (context, index) {
                  var reference = Firestore.instance
                      .collection("Users")
                      .document(connectedUserMail);

                  reference
                      .updateData({"MomenteleBestelling": bestellingLijst});
                  getTotalePrijs();
                  return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: ListTile(
                        onLongPress: () {
                          _showDeleteVraag(bestellingLijst[index]);
                        },
                        onTap: null,
                        trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(
                                icon: Icon(Icons.remove_circle),
                                onPressed: () {
                                  if (bestellingLijst[index]['Aantal'] <= 1) {
                                    _showDeleteVraag(bestellingLijst[index]);
                                  } else {
                                    setState(() {
                                      bestellingLijst[index]['Aantal']--;
                                      getTotalePrijs();
                                    });
                                  }
                                },
                              ),
                              Text(
                                (bestellingLijst[index]["Aantal"]).toString(),
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 20),
                              ),
                              IconButton(
                                  icon: Icon(
                                    Icons.add_circle,
                                    color: Geel,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      bestellingLijst[index]['Aantal']++;
                                      getTotalePrijs();
                                    });
                                  }),
                            ]),
                        leading: Image.network(
                            bestellingLijst[index]['ProductImage']),
                        title: Text(bestellingLijst[index]['ProductTitel'],
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          "€ " +
                              bestellingLijst[index]['ProductAveragePrijs']
                                  .toStringAsFixed(2),
                        ),
                      ));
                },
              )),
              Divider(
                color: GrijsDark,
                height: 30,
                thickness: 2,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 20, left: 20),
                child: Row(
                  children: <Widget>[
                    Expanded(
                        child: Text(
                      "Artikelen",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    )),
                    Text(
                      "€ " + getTotalePrijs(),
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 20, left: 20),
                child: Row(
                  children: <Widget>[
                    Expanded(
                        child: Text(
                      "Leveringskosten",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    )),
                    Text(
                      "€ " + leveringPrijs.toString(),
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    )
                  ],
                ),
              ),
              Divider(),
              Padding(
                padding: const EdgeInsets.only(right: 20, left: 20),
                child: Row(
                  children: <Widget>[
                    Expanded(
                        child: Text(
                      "Totale prijs",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    )),
                    Text(
                      "€ " +
                          (double.parse(getTotalePrijs()) + leveringPrijs)
                              .toString(),
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    )
                  ],
                ),
              )
            ],
          )),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: FloatingActionButton.extended(
          heroTag: "ButtonBestellingConfirmatie",
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  getTotalePrijs() {
    totalePrijs = 0;
    bestellingLijst.forEach((product) {
      totalePrijs =
          totalePrijs + (product['Aantal'] * product['ProductAveragePrijs']);
    });

    return totalePrijs.toStringAsFixed(2);
  }

  void confirmBestelling() async {
    num portefeuille = 0;
    var reference = Firestore.instance
        .collection("Users")
        .document(connectedUserMail)
        .get();

    reference.then((data) {
      portefeuille = data.data['Portefeuille'];
      print(portefeuille);
      if ((totalePrijs + leveringPrijs + 5) > (portefeuille)) {
        print("Niet genoeg geld");
        nietGenoegSaldo();
      } else {
        print("genoeg geld");
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => LaatsteStapBestellingAankoper(),
              fullscreenDialog: true),
        );
      }
    });
  }

  void _showDeleteVraag(Map productMap) {
    String productNaam = "'" + productMap['ProductTitel'] + "'";
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text(
            "Verwijderen?",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: new Text("Wil je $productNaam Verwijderen?"),
          actions: <Widget>[
            ButtonTheme(
                minWidth: 400.0,
                child: FlatButton(
                  color: Geel,
                  child: new Text(
                    "JA",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    verwijderVanBestelling(productMap);
                  },
                )),
            ButtonTheme(
                minWidth: 400.0,
                child: FlatButton(
                  color: GrijsDark,
                  child: new Text(
                    "NEEN",
                    style: TextStyle(color: White, fontWeight: FontWeight.bold),
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

  verwijderVanBestelling(Map productMap) async {
    setState(() {
      bestellingLijst.remove(productMap);
      _productenLijst.remove(productMap['ProductID']);

      var reference =
          Firestore.instance.collection("Users").document(connectedUserMail);

      reference.updateData({"ShoppingBag": _productenLijst});
      getTotalePrijs();
    });
    Navigator.pop(context);
  }

  nietGenoegSaldo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
                        context,
                        MaterialPageRoute(
                            builder: (context) => Portefeuille()));
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
}
