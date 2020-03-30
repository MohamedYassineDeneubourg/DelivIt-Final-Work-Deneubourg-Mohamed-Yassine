import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/Aankoper/homeAankoper.dart';
import 'package:delivit/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class LaatsteStapBestellingAankoper extends StatefulWidget {
  @override
  _LaatsteStapBestellingAankoperState createState() =>
      _LaatsteStapBestellingAankoperState();
}

class _LaatsteStapBestellingAankoperState
    extends State<LaatsteStapBestellingAankoper> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _straat, _nummer, _postcode, _additioneleInformatie = '';
  DateTime datum;
  final _formKey = new GlobalKey<FormState>();
  String connectedUserMail;
  List bestellingLijst = [];
  Map adresPosition;

  final straatController = TextEditingController();
  final nummerController = TextEditingController();
  final postcodeController = TextEditingController();

  void getCurrentUser() {
    FirebaseAuth.instance.currentUser().then((e) {
      setState(() {
        connectedUserMail = e.email;
      });
      print(e.email);
      var reference =
          Firestore.instance.collection("Users").document(e.email).get();

      reference.then((data) {
        if (this.mounted) {
          setState(() {
            connectedUserMail = e.email;
            bestellingLijst = []..addAll(data.data['MomenteleBestelling']);
          });
        }
      });
    });
  }

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print("build..");

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
            onPressed: finalisatieBestelling,
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        key: _scaffoldKey,
        resizeToAvoidBottomPadding: false,
        body: Stack(children: <Widget>[
          ColorFiltered(
              colorFilter: ColorFilter.mode(
                  Colors.white.withOpacity(0.9), BlendMode.srcOver),
              child: Image.asset(
                'assets/images/backgroundLogin.jpg',
                width: size.width,
                height: size.height,
                fit: BoxFit.cover,
              )),
          Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Form(
                    key: _formKey,
                    child: Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                            padding: EdgeInsets.only(
                              right: 20,
                              left: 20,
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 0.0, bottom: 0),
                                      child: Text(
                                        "VOEG HET BEZORGADRES",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: GrijsDark,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 20),
                                      ),
                                    ),
                                  ),
                                  FlatButton.icon(
                                    onPressed: () {
                                      Geolocator()
                                          .getCurrentPosition(
                                              desiredAccuracy: LocationAccuracy
                                                  .bestForNavigation)
                                          .then((e) async {
                                        var positieAdres = await Geolocator()
                                            .placemarkFromCoordinates(
                                                e.latitude, e.longitude,
                                                localeIdentifier: "nl_BE");
                                        setState(() {
                                          straatController.text =
                                              positieAdres.first.thoroughfare;
                                          nummerController.text = positieAdres
                                              .first.subThoroughfare;
                                          postcodeController.text =
                                              positieAdres.first.postalCode;
                                        });
                                      });
                                    },
                                    label: Text(
                                      "Huidig positie",
                                      style: TextStyle(
                                          color: GrijsDark,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    icon: Icon(
                                      Icons.person_pin,
                                      size: 25,
                                      color: GrijsDark,
                                    ),
                                  ),
                                  Padding(
                                      padding: EdgeInsets.only(
                                          top: 15, bottom: 20.0),
                                      child: TextFormField(
                                        controller: straatController,
                                        decoration: InputDecoration(
                                            errorStyle: TextStyle(
                                                fontWeight: FontWeight.w700),
                                            prefixIcon: Icon(
                                              Icons.pin_drop,
                                              color: Geel,
                                            ),
                                            fillColor: Colors.white,
                                            filled: true,
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Geel, width: 6),
                                            ),
                                            border: new UnderlineInputBorder(),
                                            errorBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.red, width: 6),
                                            ),
                                            labelText: 'Straat',
                                            hintText: 'E.g Voorstraat'),
                                        validator: (value) => value.isEmpty
                                            ? "Straat moet ingevuld zijn"
                                            : null,
                                        onSaved: (value) => _straat = value,
                                      )),
                                  Padding(
                                      padding: EdgeInsets.only(bottom: 20.0),
                                      child: TextFormField(
                                        controller: nummerController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: <TextInputFormatter>[
                                          WhitelistingTextInputFormatter
                                              .digitsOnly
                                        ],
                                        decoration: InputDecoration(
                                            errorStyle: TextStyle(
                                                fontWeight: FontWeight.w700),
                                            prefixIcon: Icon(
                                              Icons.looks_6,
                                              color: Geel,
                                            ),
                                            fillColor: Colors.white,
                                            filled: true,
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Geel, width: 6),
                                            ),
                                            border: new UnderlineInputBorder(),
                                            errorBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.red, width: 6),
                                            ),
                                            labelText: 'Nummer',
                                            hintText: 'E.g 24'),
                                        validator: (value) => value.isEmpty
                                            ? "Nummer moet ingevuld zijn"
                                            : null,
                                        onSaved: (value) => _nummer = value,
                                      )),
                                  Padding(
                                      padding: EdgeInsets.only(bottom: 20.0),
                                      child: TextFormField(
                                        controller: postcodeController,
                                        inputFormatters: <TextInputFormatter>[
                                          WhitelistingTextInputFormatter
                                              .digitsOnly
                                        ],
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                            errorStyle: TextStyle(
                                                fontWeight: FontWeight.w700),
                                            prefixIcon: Icon(
                                              Icons.map,
                                              color: Geel,
                                            ),
                                            fillColor: Colors.white,
                                            filled: true,
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Geel, width: 6),
                                            ),
                                            border: new UnderlineInputBorder(),
                                            errorBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.red, width: 6),
                                            ),
                                            labelText: 'Postcode',
                                            hintText: 'E.g 1070'),
                                        validator: (value) {
                                          if (value.isEmpty) {
                                            return "Postcode moet ingevuld zijn.";
                                          }

                                          if (value.length < 4) {
                                            return "Postcode is niet correct.";
                                          }

                                          return null;
                                        },
                                        onSaved: (value) => _postcode = value,
                                      )),
                                  Padding(
                                      padding: EdgeInsets.only(bottom: 15.0),
                                      child: TextFormField(
                                        maxLines: 3,
                                        decoration: InputDecoration(
                                            errorStyle: TextStyle(
                                                fontWeight: FontWeight.w700),
                                            prefixIcon: Icon(
                                              Icons.textsms,
                                              color: Geel,
                                            ),
                                            fillColor: Colors.white,
                                            filled: true,
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Geel, width: 6),
                                            ),
                                            border: new UnderlineInputBorder(),
                                            errorBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.red, width: 6),
                                            ),
                                            labelText: 'Additionele informatie',
                                            hintText: '...'),
                                        onSaved: (value) =>
                                            _additioneleInformatie = value,
                                      )),
                                  Divider(),
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 20.0, bottom: 0),
                                      child: Text(
                                        "PLAN EEN BEZORGTIJD",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: GrijsDark,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 20),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                      padding: EdgeInsets.only(
                                          top: 20, bottom: 50.0),
                                      child: DateTimeField(
                                        onShowPicker:
                                            (context, currentValue) async {
                                          final date = await showDatePicker(
                                              context: context,
                                              firstDate: DateTime.now(),
                                              initialDate: DateTime.now(),
                                              lastDate: DateTime(
                                                  (DateTime.now().year + 1)));
                                          if (date != null) {
                                            final time = await showTimePicker(
                                              context: context,
                                              initialTime:
                                                  TimeOfDay.fromDateTime(
                                                      currentValue ??
                                                          DateTime.now()),
                                            );
                                            return DateTimeField.combine(
                                                date, time);
                                          } else {
                                            return currentValue;
                                          }
                                        },
                                        format: DateFormat("dd-MM-yyyy HH:mm"),
                                        readOnly: true,
                                        decoration: InputDecoration(
                                            errorStyle: TextStyle(
                                                fontWeight: FontWeight.w700),
                                            prefixIcon: Icon(
                                              Icons.date_range,
                                              color: Geel,
                                            ),
                                            fillColor: Colors.white,
                                            filled: true,
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Geel, width: 6),
                                            ),
                                            border: new UnderlineInputBorder(),
                                            errorBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.red, width: 6),
                                            ),
                                            labelText: 'Datum & Tijd',
                                            hintText: 'E.g 24/02/2020 13:00'),
                                        validator: (value) =>
                                            value.toString().isEmpty
                                                ? "Datum moet ingevuld zijn"
                                                : null,
                                        onSaved: (value) => datum = value,
                                      )),
                                ]))
                      ],
                    ))),

                //EINDE TEXTVELDEN
              ])
        ]));
  }

  void finalisatieBestelling() async {
    if (valideerEnSave()) {
      String volledigAdres =
          _straat + " " + _nummer + ", " + _postcode + " Belgium";
      print(volledigAdres);
      try {
        var geoQuery = await Geolocator()
            .placemarkFromAddress(volledigAdres, localeIdentifier: 'nl_BE');
        //  print(geoQuery.first.position.longitude);
        adresPosition = {
          'latitude': geoQuery.first.position.latitude,
          'longitude': geoQuery.first.position.longitude
        };
        print(adresPosition);
        await Firestore.instance.collection("Commands").document().setData({
          'AdresPosition': adresPosition,
          'AanbodLijst': [],
          'Adres': _straat + " " + _nummer + ", " + _postcode,
          'AdditioneleInformatie': _additioneleInformatie,
          'BestellingLijst': bestellingLijst,
          'BezorgDatumEnTijd': datum,
          'BestellingStatus': 'AANVRAAG',
          'AankoperEmail': connectedUserMail,
          'BezorgerEmail': '',
          'isBeschikbaar': true,
          'VerzameldeProducten': []
        }).then((e) {
          var reference = Firestore.instance
              .collection("Users")
              .document(connectedUserMail);

          reference.updateData({"MomenteleBestelling": [], "ShoppingBag": []});
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => HomeAankoper()));
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return new AlertDialog(
                  title: Text('CONFIRMATIE BESTELLING',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  content: Container(
                      height: 85,
                      child: SingleChildScrollView(
                        child: Text(
                            "Super! Je bestelling is geplaatst, bekijk deze in je lijst en wacht tot dat je een aanbieding gekregen hebt"),
                      )),
                  contentPadding: EdgeInsets.all(20),
                  actions: <Widget>[
                    ButtonTheme(
                        minWidth: 400.0,
                        child: FlatButton(
                          color: Geel,
                          child: new Text(
                            "OK",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        )),
                  ],
                );
              });
        });
      } catch (e) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return new AlertDialog(
                title: Text('OEPS.. ONJUISTE ADRES',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                content: Container(
                    height: 85,
                    child: SingleChildScrollView(
                      child: Text(
                          "Je adres is onjuist, kijk deze goed na en probeer opnieuw.. \n \n" +
                              e.toString()),
                    )),
                contentPadding: EdgeInsets.all(20),
                actions: <Widget>[
                  ButtonTheme(
                      minWidth: 400.0,
                      child: FlatButton(
                        color: Geel,
                        child: new Text(
                          "OK",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      )),
                ],
              );
            });
        print('Error:$e');
      }
    }
  }

  bool valideerEnSave() {
    final form = _formKey.currentState;

    if (form.validate()) {
      form.save();
      print('Form is valid.');
      return true;
    }

    return false;
  }
}
