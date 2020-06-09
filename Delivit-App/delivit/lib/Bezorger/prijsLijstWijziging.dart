import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/globals.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:toast/toast.dart';

class PrijsLijstWijzigingBezorger extends StatefulWidget {
  @override
  _PrijsLijstWijzigingBezorgerState createState() =>
      _PrijsLijstWijzigingBezorgerState();
}

class _PrijsLijstWijzigingBezorgerState
    extends State<PrijsLijstWijzigingBezorger> {
  StreamSubscription<DocumentSnapshot> _getFirebaseSubscription;

  @override
  void dispose() {
    if (_getFirebaseSubscription != null) {
      _getFirebaseSubscription.cancel();
    }
    super.dispose();
  }

  @override
  void initState() {
    getCurrentUser();
    getData();
    super.initState();
  }

  String connectedUserMail;
  Map mijnPrijsLijst;
  List producten = new List();

  String selectedCategory = "Alles";
  bool toonSearchbar = false;
  Size size;

  void getCurrentUser() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    print(user);
    if (user != null) {
      setState(() {
        connectedUserMail = user.email;
      });
      getMijnPrijsLijst();
    }
  }

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

    List list = reference.documents;
    list.sort(
        (a, b) => a.data['ProductTitel'].compareTo(b.data['ProductTitel']));

    setState(() {
      producten = list;
    });
    checkInMijnPrijsLijst();
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
        producten = [];
      } else {
        producten = documents;
      }
    });
    checkInMijnPrijsLijst();
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
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
        title: new Text("MIJN PRIJSLIJST"),
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
                  return Container(
                    child: RaisedButton(
                        color: White,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            side: BorderSide(color: GrijsMidden, width: 1),
                            borderRadius: BorderRadius.circular(5)),
                        onPressed: () {
                          toonDetailProduct(producten[product]);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Padding(
                                padding: EdgeInsets.only(
                                    top: (size.aspectRatio > 0.57) ? 10 : 15),
                                child: Text(
                                  producten[product]["ProductTitel"],
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            Image.network(producten[product]['ProductImage'],
                                height: (size.aspectRatio > 0.57) ? 90 : 100,
                                fit: BoxFit.cover),
                            Container(
                              padding: (size.aspectRatio > 0.57)
                                  ? EdgeInsets.only(
                                      top: 0, left: 10, right: 10, bottom: 0)
                                  : EdgeInsets.only(
                                      top: 5, left: 10, right: 10, bottom: 5),
                              decoration: BoxDecoration(
                                  color: (producten[product]
                                              ['GewijzigdPrijs'] ==
                                          null)
                                      ? Geel.withOpacity(0.3)
                                      : Colors.orangeAccent.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(50)),
                              child: Center(
                                child: Text(
                                    "€ " +
                                        (producten[product]['GewijzigdPrijs'] ==
                                                null
                                            ? producten[product]
                                                    ["ProductDefaultPrijs"]
                                                .toStringAsFixed(2)
                                            : producten[product]
                                                    ["GewijzigdPrijs"]
                                                .toStringAsFixed(2)),
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                            (producten[product]['GewijzigdPrijs'] != null)
                                ? Text(
                                    "Gewijzigd",
                                    style: TextStyle(fontSize: 10),
                                  )
                                : Container(),
                            SizedBox(
                              height: 10,
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

  checkInMijnPrijsLijst() async {
    List productenTemp = [];
    producten.forEach((element) {
      var elementTemp = element.data;
      elementTemp['documentID'] = element.documentID;
      if (mijnPrijsLijst.containsKey(element.documentID)) {
        elementTemp['GewijzigdPrijs'] = mijnPrijsLijst[element.documentID];
      }
      productenTemp.add(elementTemp);
    });

    setState(() {
      producten = productenTemp;
    });
  }

  getMijnPrijsLijst() {
    _getFirebaseSubscription = Firestore.instance
        .collection("Users")
        .document(connectedUserMail)
        .snapshots()
        .listen((data) {
      mijnPrijsLijst = data['PrijsLijstBezorger'];
    });
  }

  veranderPrijsLijst(productId, oudePrijs, nieuwePrijs) {
    setState(() {
      if (oudePrijs == nieuwePrijs) {
        mijnPrijsLijst.remove(productId);
      } else {
        mijnPrijsLijst[productId] = nieuwePrijs;
      }
    });
    try {
      Firestore.instance
          .collection("Users")
          .document(connectedUserMail)
          .updateData({'PrijsLijstBezorger': mijnPrijsLijst});

      Firestore.instance
          .collection("Users")
          .where("PrijsLijstBezorger", isGreaterThan: {})
          .getDocuments()
          .then((documents) {
            double prijsVanIedereen = 0;
            int aantalBezorgersMetDitProduct = 0;
            documents.documents.forEach((element) {
              if (element.data['PrijsLijstBezorger'].containsKey(productId)) {
                prijsVanIedereen +=
                    element.data['PrijsLijstBezorger'][productId];
                aantalBezorgersMetDitProduct++;
              }
            });
            double nieuweAveragePrijs = double.parse(
                ((prijsVanIedereen + oudePrijs) /
                        (aantalBezorgersMetDitProduct + 1))
                    .toStringAsFixed(2));

            Firestore.instance
                .collection("Products")
                .document(productId)
                .updateData({'ProductAveragePrijs': nieuweAveragePrijs});
          })
          .then((value) {
            Navigator.pop(context);
            setState(() {
              getData();
              toonSearchbar = false;
            });
          });
    } catch (e) {
      Toast.show("Oeps... Je kan binnenkort nog eens proberen...", context,
          duration: Toast.LENGTH_LONG,
          gravity: Toast.BOTTOM,
          backgroundColor: Colors.red);
      Navigator.pop(context);
    }
  }

  getMinimumPrijs(standaardPrijs) {
    return standaardPrijs -= (standaardPrijs * 0.25);
  }

  getMaximumPrijs(standaardPrijs) {
    return standaardPrijs += (standaardPrijs * 0.25);
  }

  toonDetailProduct(productMap) {
    double prijsWijziging = (productMap['GewijzigdPrijs'] == null
        ? productMap["ProductDefaultPrijs"].toDouble()
        : productMap["GewijzigdPrijs"].toDouble());

    showModalBottomSheet(
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                  color: White,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20))),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(
                          top: 4, right: 0, left: 15, bottom: 4),
                      decoration: BoxDecoration(
                          color: GrijsLicht,
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20))),
                      child: Row(
                        children: <Widget>[
                          Image.network(productMap['ProductImage'],
                              height: size.width * 0.2,
                              width: size.width * 0.2,
                              fit: BoxFit.cover),
                          SizedBox(width: size.width * 0.05),
                          Expanded(
                            child: AutoSizeText(
                              productMap["ProductTitel"],
                              style: TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 20),
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(
                          top: 20, right: 15, left: 15, bottom: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Prijzen",
                            style: TextStyle(
                                color: GrijsDark,
                                fontWeight: FontWeight.w900,
                                fontSize: 18),
                            textAlign: TextAlign.start,
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 10, bottom: 10),
                            height: 2,
                            width: 50,
                            color: Geel,
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: size.width * 0.0),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                    child: Text(
                                  "Standaard prijs",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600),
                                )),
                                Text(
                                  "€ " +
                                      productMap["ProductDefaultPrijs"]
                                          .toStringAsFixed(2),
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600),
                                )
                              ],
                            ),
                          ),
                          Row(
                            children: <Widget>[
                              Expanded(
                                  child: Text(
                                "Gemiddelde prijs",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                              )),
                              Text(
                                "€ " +
                                    productMap["ProductAveragePrijs"]
                                        .toStringAsFixed(2),
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                              )
                            ],
                          ),
                          Divider(),
                          Padding(
                            padding: EdgeInsets.only(right: size.width * 0.0),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                    child: Text(
                                  "Jouw prijs",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900),
                                )),
                                Text(
                                  "€ " +
                                      (productMap['GewijzigdPrijs'] == null
                                          ? productMap["ProductDefaultPrijs"]
                                              .toStringAsFixed(2)
                                          : productMap["GewijzigdPrijs"]
                                              .toStringAsFixed(2)),
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900),
                                )
                              ],
                            ),
                          ),
                          (productMap['GewijzigdPrijs'] != null)
                              ? Text("Gewijzigd",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ))
                              : Container(),
                          SizedBox(height: size.height * 0.03),
                          Text(
                            "Eigen prijs wijzigen",
                            style: TextStyle(
                                color: GrijsDark,
                                fontWeight: FontWeight.w900,
                                fontSize: 18),
                            textAlign: TextAlign.start,
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 10, bottom: 10),
                            height: 2,
                            width: 50,
                            color: Geel,
                          ),
                          Center(
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  IconButton(
                                    icon: Icon(
                                      Icons.remove_circle,
                                      size: 30,
                                    ),
                                    onPressed: () {
                                      if (prijsWijziging >
                                          getMinimumPrijs(
                                              productMap["ProductDefaultPrijs"]
                                                  .toDouble())) {
                                        setState(() {
                                          prijsWijziging =
                                              prijsWijziging - 0.10;
                                        });
                                      }
                                    },
                                  ),
                                  Text(
                                    "€ " + prijsWijziging.toStringAsFixed(2),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 30),
                                  ),
                                  IconButton(
                                      icon: Icon(
                                        Icons.add_circle,
                                        color: Geel,
                                        size: 30,
                                      ),
                                      onPressed: () {
                                        if (prijsWijziging <
                                            getMaximumPrijs(productMap[
                                                    "ProductDefaultPrijs"]
                                                .toDouble())) {
                                          setState(() {
                                            prijsWijziging =
                                                prijsWijziging + 0.10;
                                          });
                                        }
                                      }),
                                ]),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 15.0, bottom: 10),
                            child: Center(
                              child: FloatingActionButton.extended(
                                hoverElevation: 12,
                                heroTag: "INSCRIPTION",
                                splashColor: GrijsDark,
                                elevation: 2.0,
                                backgroundColor: Geel,
                                icon: const Icon(
                                  FontAwesomeIcons.sync,
                                  size: 20,
                                  color: White,
                                ),
                                label: Text(
                                  "PRIJS WIJZIGEN",
                                  style: TextStyle(
                                      color: White,
                                      fontWeight: FontWeight.w900),
                                ),
                                onPressed: () {
                                  veranderPrijsLijst(
                                      productMap['documentID'],
                                      productMap["ProductDefaultPrijs"],
                                      prijsWijziging);
                                },
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          });
        });
  }
}
