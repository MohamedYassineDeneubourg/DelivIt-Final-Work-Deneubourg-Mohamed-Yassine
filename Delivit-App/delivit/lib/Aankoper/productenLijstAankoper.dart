import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/Aankoper/bestellingConfirmAankoper.dart';
import 'package:delivit/globals.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class ProductenLijstAankoper extends StatefulWidget {
  @override
  _ProductenLijstAankoperState createState() => _ProductenLijstAankoperState();
}

class _ProductenLijstAankoperState extends State<ProductenLijstAankoper> {
  @override
  void initState() {
    getCurrentUser();
    getData();
    super.initState();
  }

  String connectedUserMail;

  void getCurrentUser() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    print(user);
    if (user != null) {
      setState(() {
        connectedUserMail = user.email;
      });
    }
    getShoppingBag();
  }

  List producten = new List();
  List bestellingProducten = new List();
  Future<void> getData() async {
    var reference;
    if (selectedCategory == 'Alles') {
      reference =
          await Firestore.instance.collection("Products").getDocuments();
    } else {
      reference = await Firestore.instance
          .collection("Products")
          .where('Categorie', isEqualTo: selectedCategory)
          .getDocuments();
    }

    print(selectedCategory);
    List<DocumentSnapshot> documents = reference.documents;

    setState(() {
      producten = documents;
      documents.forEach((object) {
        // print(object.data);
      });
    });
    //print(producten);
    print("GetData is done..");
  }

  getShoppingBag() {
    var reference = Firestore.instance
        .collection("Users")
        .document(connectedUserMail)
        .get();

    reference.then((data) {
      print(data.documentID);
      List shoppingBag = data["ShoppingBag"];
      if (this.mounted) {
        setState(() {
          if (shoppingBag.length > 0) {
            bestellingProducten = []
              ..addAll(bestellingProducten)
              ..addAll(shoppingBag);
          }
        });
      }
    });
  }

  getDatabySearch(zoekWoord) async {
    print(zoekWoord);
    var reference = await Firestore.instance
        .collection("Products")
        .where("ProductTitel",
            isGreaterThanOrEqualTo: toBeginningOfSentenceCase(zoekWoord))
        .getDocuments();
    List<DocumentSnapshot> documents = reference.documents;

    setState(() {
      print(documents.length);
      if (documents.length == 0) {
        print("no!");
        producten = [];
      } else {
        print("yesè");
        producten = documents;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: White,
      appBar: AppBar(
        backgroundColor: White,
        textTheme: TextTheme(
            title: TextStyle(
                color: Geel,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                fontFamily: "Montserrat")),
        centerTitle: true,
        title: new Text("KIES JE PRODUCTEN"),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              toonSearchbar ? Icons.list : Icons.search,
              color: GrijsDark,
            ),
            onPressed: () {
              setState(() {
                toonSearchbar = !toonSearchbar;
              });
            },
          )
        ],
      ),
      body: lijst(context),
    );
  }

  String selectedCategory = "Alles";
  bool toonSearchbar = false;
  returnColor(name) {
    if (name == selectedCategory) {
      return true;
    } else {
      return false;
    }
  }

  Widget topWidget;

  Widget lijst(BuildContext context) {
    Widget categorieButton(
      String name,
      IconData icon,
    ) {
      return Container(
        margin: EdgeInsets.only(left: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
                margin: EdgeInsets.only(bottom: 10),
                width: 65,
                height: 65,
                child: RaisedButton(
                  color: returnColor(name) ? Geel : White,
                  shape: RoundedRectangleBorder(
                      side: BorderSide(color: GrijsDark.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(6.0)),
                  onPressed: () {
                    setState(() {
                      selectedCategory = name;
                    });
                    getData();
                  },
                  child: Icon(icon,
                      size: 28, color: returnColor(name) ? White : GrijsDark),
                )),
            Text(name)
          ],
        ),
      );
    }

    Widget filterCategorieMenu() {
      return Padding(
        key: Key("filterCategorieMenu"),
        padding: const EdgeInsets.only(top: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                children: <Widget>[
                  categorieButton(
                    'Alles',
                    FontAwesomeIcons.list,
                  ),
                  categorieButton(
                    'Dranken',
                    FontAwesomeIcons.glassWhiskey,
                  ),
                  categorieButton(
                    'Alcohol',
                    FontAwesomeIcons.glassCheers,
                  ),
                  categorieButton(
                    'Zoet',
                    FontAwesomeIcons.cookieBite,
                  ),
                  categorieButton(
                    'Fruit&Gr.',
                    FontAwesomeIcons.leaf,
                  ),
                  categorieButton(
                    'Charcuter.',
                    FontAwesomeIcons.shapes,
                  ),
                ],
              ),
            )
          ],
        ),
      );
    }

    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: FloatingActionButton.extended(
            heroTag: "ButtonBestelling",
            splashColor: GrijsDark,
            elevation: 4.0,
            backgroundColor: Geel,
            icon: const Icon(
              Icons.shopping_cart,
              color: White,
            ),
            label: Text(
              "BESTELLEN (" + (bestellingProducten.length).toString() + ")",
              style: TextStyle(color: White, fontWeight: FontWeight.w800),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => BestellingConfirmAankoper(),
                    fullscreenDialog: true),
              ).then((e) {
                setState(() {
                  bestellingProducten = [];
                  getShoppingBag();
                });
              });
            }),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Column(
        children: <Widget>[
          AnimatedSwitcher(
            child: toonSearchbar
                ? Padding(
                    padding: const EdgeInsets.only(
                        top: 30.0, right: 15, left: 15, bottom: 30),
                    child: Material(
                      elevation: 3,
                      child: TextFormField(
                        //  autofocus: true,
                        decoration: InputDecoration(
                            errorStyle: TextStyle(fontWeight: FontWeight.w700),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Geel,
                            ),
                            // border: OutlineInputBorder(borderSide: BorderSide(color: Geel,width: 20)),
                            fillColor: Colors.white,
                            filled: true,
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Geel)),
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: GrijsMidden)),
                            errorBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.red, width: 6),
                            ),
                            labelText: 'Product',
                            hintText: 'E.g Coca-cola'),
                        validator: (value) =>
                            value.isEmpty ? "moet ingevuld zijn" : null,
                        onChanged: (value) {
                          getDatabySearch(value);
                          print(value);
                        },
                      ),
                    ),
                    key: Key("SearchBar"),
                  )
                : filterCategorieMenu(),
            layoutBuilder:
                (Widget currentChild, List<Widget> previousChildren) {
              return currentChild;
            },
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(
                child: child,
                scale: animation,
              );
            },
            duration: const Duration(milliseconds: 250),
          ),
          Expanded(
            child: GridView.builder(
              itemCount: producten.length,
              itemBuilder: (context, product) {
                //print(product);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: Center(
                    child: Stack(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10.0, left: 3),
                          child: Container(
                              width: 175,
                              height: 200,
                              child: RaisedButton(
                                  color: White,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                          color: (bestellingProducten.contains(
                                                  producten[product]
                                                      .documentID))
                                              ? Geel
                                              : GrijsMidden,
                                          width: (bestellingProducten.contains(
                                                  producten[product]
                                                      .documentID))
                                              ? 4
                                              : 1),
                                      borderRadius: BorderRadius.circular(5)),
                                  onPressed: () {
                                    if (bestellingProducten.contains(
                                        producten[product].documentID)) {
                                      setState(() {
                                        bestellingProducten.remove(
                                            producten[product].documentID);
                                      });
                                    } else {
                                      setState(() {
                                        bestellingProducten
                                            .add(producten[product].documentID);
                                        print(bestellingProducten);
                                      });
                                    }

                                    var reference = Firestore.instance
                                        .collection("Users")
                                        .document(connectedUserMail);

                                    reference.updateData(
                                        {"ShoppingBag": bestellingProducten});
                                  },
                                  child: Hero(
                                      transitionOnUserGestures: true,
                                      tag: producten[product].documentID,
                                      child: Image.network(
                                        producten[product]
                                            .data['ProductImage'],
                                        height: 100,fit: BoxFit.cover
                                      )))),
                        ),
                        Positioned(
                          top: 15,
                          left: 15,
                          child: Text(
                            producten[product].data["ProductTitel"],
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Positioned(
                            bottom: 20,
                            right: 10,
                            left: 10,
                            child: Container(
                              padding: EdgeInsets.only(
                                  top: 5, left: 10, right: 10, bottom: 5),
                              decoration: BoxDecoration(
                                  color: Geel.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(50)),
                              child: Center(
                                child: Text(
                                    "€ " +
                                        producten[product]
                                            .data["ProductDefaultPrijs"]
                                            .toString(),
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700)),
                              ),
                            )),
                      ],
                    ),
                  ),
                );
              },
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 1.0,
                mainAxisSpacing: 5.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
