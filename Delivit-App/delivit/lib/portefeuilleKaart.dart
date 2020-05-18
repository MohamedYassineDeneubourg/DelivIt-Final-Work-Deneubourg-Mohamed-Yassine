import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/globals.dart';
import 'package:delivit/stripeServices.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PortefeuilleKaart extends StatefulWidget {
  @override
  _PortefeuilleKaartState createState() => _PortefeuilleKaartState();
}

class _PortefeuilleKaartState extends State<PortefeuilleKaart> {
  String cardNumber = "**** **** **** ****";
  String month = "**";
  String year = "**";
  String cvc = "***";

  var _formKey = new GlobalKey<FormState>();

  String connectedUserMail;

  Map gebruikerData;

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  void getCurrentUser() async {
    final FirebaseUser userData = await FirebaseAuth.instance.currentUser();
    if (userData != null) {
      setState(() {
        connectedUserMail = userData.email;
      });
      _getData();
    }
  }

  _getData() {
    var reference = Firestore.instance
        .collection("Users")
        .document(connectedUserMail)
        .snapshots();

    reference.listen((data) {
      if (this.mounted) {
        setState(() {
          //print("Card..");
          gebruikerData = data.data;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    //print(size.height);
    return Scaffold(
      appBar: AppBar(
          backgroundColor: White,
          textTheme: TextTheme(
              headline6: TextStyle(
                  color: Geel,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  fontFamily: "Montserrat")),
          centerTitle: true,
          title: Text("KAART")),
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
            "KAART TOEVOEGEN",
            style: TextStyle(color: White, fontWeight: FontWeight.w800),
          ),
          onPressed: kaartToevoegen,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding:
                EdgeInsets.only(top: size.height * 0.15, right: 25.0, left: 25),
            child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Geel,
                ),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: GrijsDark,
                          child: Icon(
                            Icons.credit_card,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        Text(
                          "CARD",
                          style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 16,
                              color: GrijsDark,
                              fontWeight: FontWeight.w900),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 32,
                    ),
                    Text(
                      cardNumber,
                      style: TextStyle(
                          fontSize: 30,
                          color: GrijsDark,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0),
                    ),
                    SizedBox(
                      height: 32,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              "CARD HOLDER",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: White,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.0),
                            ),
                            Text(
                              gebruikerData['Naam'],
                              style: TextStyle(
                                  fontSize: 16,
                                  color: GrijsDark,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.0),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              "EXPIRES",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.0),
                            ),
                            Text(
                              month + "/" + year,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: GrijsDark,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.0),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              "CVV",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: White,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.0),
                            ),
                            Text(
                              cvc,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: GrijsDark,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.0),
                            ),
                          ],
                        )
                      ],
                    )
                  ],
                )),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 25.0, left: 25),
            child: Form(
                key: _formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.only(top: 20, bottom: 20.0),
                          child: TextFormField(
                            inputFormatters: <TextInputFormatter>[
                              WhitelistingTextInputFormatter.digitsOnly
                            ],
                            keyboardType: TextInputType.number,
                            maxLength: 19,
                            decoration: InputDecoration(
                                errorStyle:
                                    TextStyle(fontWeight: FontWeight.w700),
                                prefixIcon: Icon(
                                  Icons.credit_card,
                                  color: Geel,
                                ),
                                fillColor: Colors.white,
                                filled: true,
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Geel, width: 6),
                                ),
                                border: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Geel, width: 30)),
                                enabledBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Geel, width: 3)),
                                errorBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.red, width: 6),
                                ),
                                labelText: 'Kaartnummer',
                                hintText: '**** **** **** ****'),
                            validator: (value) {
                              if (value.isEmpty) {
                                return "Kaartnummer moet ingevuld zijn";
                              }
                              return null;
                              /*if(!validateCardNumWithLuhnAlgorithm(value)){
                                return "Kaartnummer is niet correct";

                              }*/
                            },
                            onChanged: (value) {
                              setState(() {
                                //print(value);
                                cardNumber = value;
                              });
                            },
                          )),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Flexible(
                            child: TextFormField(
                              inputFormatters: <TextInputFormatter>[
                                WhitelistingTextInputFormatter.digitsOnly
                              ],
                              keyboardType: TextInputType.number,
                              maxLength: 2,
                              decoration: InputDecoration(
                                  errorStyle:
                                      TextStyle(fontWeight: FontWeight.w700),
                                  prefixIcon: Icon(
                                    Icons.calendar_today,
                                    color: Geel,
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Geel, width: 6),
                                  ),
                                  border: new UnderlineInputBorder(),
                                  errorBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.red, width: 6),
                                  ),
                                  labelText: 'Maand',
                                  hintText: 'E.g 02'),
                              validator: (value) {
                                if (value.isEmpty) {
                                  return "Maand moet ingevuld zijn.";
                                }

                                if (value.length < 1) {
                                  return "Maand is niet correct.";
                                }

                                return null;
                              },
                              onChanged: (value) {
                                setState(() {
                                  //print(value);
                                  month = value;
                                });
                              },
                            ),
                          ),
                          Text(
                            "/",
                            style: TextStyle(fontSize: 30),
                          ),
                          Flexible(
                            child: TextFormField(
                                maxLength: 2,
                                inputFormatters: <TextInputFormatter>[
                                  WhitelistingTextInputFormatter.digitsOnly
                                ],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                    errorStyle:
                                        TextStyle(fontWeight: FontWeight.w700),
                                    fillColor: Colors.white,
                                    filled: true,
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Geel, width: 6),
                                    ),
                                    border: new UnderlineInputBorder(),
                                    errorBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.red, width: 6),
                                    ),
                                    labelText: 'Jaar',
                                    hintText: 'E.g 22'),
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return "Jaar moet ingevuld zijn.";
                                  }

                                  if (value.length != 2) {
                                    return "Jaar is niet correct.";
                                  }

                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    //print(value);
                                    year = "20" + value;
                                  });
                                }),
                          ),
                          Padding(padding: EdgeInsets.only(right: 30)),
                          Flexible(
                            flex: 1,
                            child: TextFormField(
                              maxLength: 4,
                              inputFormatters: <TextInputFormatter>[
                                WhitelistingTextInputFormatter.digitsOnly
                              ],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                  errorStyle:
                                      TextStyle(fontWeight: FontWeight.w700),
                                  prefixIcon: Icon(
                                    Icons.closed_caption,
                                    color: Geel,
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Geel, width: 6),
                                  ),
                                  border: new UnderlineInputBorder(),
                                  errorBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.red, width: 6),
                                  ),
                                  labelText: 'CVV',
                                  hintText: '***'),
                              validator: (value) {
                                if (value.isEmpty) {
                                  return "CVV moet ingevuld zijn.";
                                }

                                if (value.length != 3) {
                                  return "CVV is niet correct.";
                                }

                                return null;
                              },
                              onChanged: (value) {
                                setState(() {
                                  //print(value);
                                  cvc = value;
                                });
                              },
                            ),
                          ),
                        ],
                      )
                    ])),
          )
        ],
      ),
    );
  }

  static bool validateCardNumWithLuhnAlgorithm(String input) {
    if (input.isEmpty) {
      return false;
    }
    if (input.length < 8) {
      // No need to even proceed with the validation if it's less than 8 characters
      return false;
    }

    int sum = 0;
    int length = input.length;
    for (var i = 0; i < length; i++) {
      // get digits in reverse order
      int digit = int.parse(input[length - i - 1]);

      // every 2nd number multiply with 2
      if (i % 2 == 1) {
        digit *= 2;
      }
      sum += digit > 9 ? (digit - 9) : digit;
    }

    if (sum % 10 == 0) {
      return false;
    }

    return true;
  }

  void kaartToevoegen() {
    if (valideerEnSave()) {
      StripeServices().addCard(
          context: context,
          email: connectedUserMail,
          stripeId: gebruikerData['stripeId'].toString(),
          cardNumber: cardNumber,
          cvc: cvc,
          year: year,
          month: month);
    }
  }

  bool valideerEnSave() {
    final form = _formKey.currentState;

    if (form.validate()) {
      form.save();
      //print('Form is valid.');
      return true;
    }

    return false;
  }
}
