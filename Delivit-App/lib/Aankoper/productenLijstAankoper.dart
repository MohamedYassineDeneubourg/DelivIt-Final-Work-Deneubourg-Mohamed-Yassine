import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/Aankoper/bestellingConfirmAankoper.dart';
import 'package:delivit/globals.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:toast/toast.dart';

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

    List<DocumentSnapshot> documents = reference.documents;

    setState(() {
      producten = documents;
    });
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
        .orderBy("ProductTitel")
        .startAt([toBeginningOfSentenceCase(zoekWoord)]).endAt(
            [toBeginningOfSentenceCase(zoekWoord) + '\uf8ff']).getDocuments();
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
            headline6: TextStyle(
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
              if (toonSearchbar == false) {
                getData();
              }
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
            Container(
              width: 70,
              child: Text(
                name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            )
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
                    'Zoet',
                    FontAwesomeIcons.cookieBite,
                  ),
                  categorieButton(
                    'Fruit&Groenten',
                    FontAwesomeIcons.leaf,
                  ),
                  categorieButton(
                    'Charcuterie',
                    FontAwesomeIcons.shapes,
                  ),
                  categorieButton(
                    'Hygiëne',
                    FontAwesomeIcons.soap,
                  ),
                  categorieButton(
                    'Baby',
                    FontAwesomeIcons.baby,
                  ),
                  categorieButton(
                    'Dieren',
                    FontAwesomeIcons.cat,
                  )
                ],
              ),
            )
          ],
        ),
      );
    }

    return Scaffold(
      floatingActionButton: (bestellingProducten.length < 1)
          ? null
          : Padding(
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
                    "BESTELLEN (" +
                        (bestellingProducten.length).toString() +
                        ")",
                    style: TextStyle(color: White, fontWeight: FontWeight.w800),
                  ),
                  onPressed: () {
                    if (bestellingProducten.length < 1) {
                      Toast.show(
                          "Je moet minstens 1 product selecteren.", context,
                          duration: Toast.LENGTH_SHORT,
                          gravity: Toast.BOTTOM,
                          backgroundColor: Colors.red);
                    } else {
                      Navigator.push(
                        context,
                        SlideTopRoute(
                          page: BestellingConfirmAankoper(),
                        ),
                      ).then((e) {
                        setState(() {
                          bestellingProducten = [];
                          getShoppingBag();
                        });
                      });
                    }
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
            child: Container(
              padding: EdgeInsets.only(right: 15, left: 15),
              child: GridView.builder(
                itemCount: producten.length,
                itemBuilder: (context, product) {
                  //print(product);
                  return Container(
                    child: RaisedButton(
                        color: White,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            side: BorderSide(
                                color: (bestellingProducten.contains(
                                        producten[product].documentID))
                                    ? Geel
                                    : GrijsMidden,
                                width: (bestellingProducten.contains(
                                        producten[product].documentID))
                                    ? 4
                                    : 1),
                            borderRadius: BorderRadius.circular(5)),
                        onPressed: () {
                          if (bestellingProducten
                              .contains(producten[product].documentID)) {
                            setState(() {
                              bestellingProducten
                                  .remove(producten[product].documentID);
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

                          reference
                              .updateData({"ShoppingBag": bestellingProducten});
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(top: 15),
                              child: AutoSizeText(
                                producten[product].data["ProductTitel"],
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Image.network(
                                producten[product].data['ProductImage'],
                                height: 100,
                                fit: BoxFit.cover),
                            Container(
                              margin: EdgeInsets.only(bottom: 10),
                              padding: EdgeInsets.only(
                                  top: 5, left: 10, right: 10, bottom: 5),
                              decoration: BoxDecoration(
                                  color: Geel.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(50)),
                              child: Center(
                                child: Text(
                                    "€ " +
                                        producten[product]
                                            .data["ProductAveragePrijs"]
                                            .toStringAsFixed(2),
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700)),
                              ),
                            )
                          ],
                        )),
                  );
                },
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15.0,
                  mainAxisSpacing: 15.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
