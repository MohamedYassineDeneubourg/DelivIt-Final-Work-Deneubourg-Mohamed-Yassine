import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Portefeuille extends StatefulWidget {
  @override
  _PortefeuilleState createState() => _PortefeuilleState();
}

class _PortefeuilleState extends State<Portefeuille> {
  List portefeuilleHistoriek = [];
  String connectedUserMail;
  Map gebruikerData;
  @override
  void initState() {
    getCurrentUser();

    super.initState();
  }

  void setError(dynamic error) {
//Handle your errors
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

  void portefeuilleAanvullen() async {
  }

  _getData() {
    var reference = Firestore.instance
        .collection("Users")
        .document(connectedUserMail)
        .snapshots();

    reference.listen((data) {
      if (this.mounted) {
        setState(() {
          print("Refreshed");
          gebruikerData = data.data;
          print(data.data);
          portefeuilleHistoriek = []
            ..addAll(data.data['PortefeuilleHistoriek']);
        });
      }
    });
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
          title: Text("PORTEFEUILLE")),
      body: (gebruikerData != null)
          ? Container(
              padding: new EdgeInsets.only(
                  top: 8.0, bottom: 20, right: 15, left: 15),
              child: new Column(
                children: <Widget>[
                  Padding(
                      padding: EdgeInsets.only(
                        bottom: 15,
                        top: 10,
                      ),
                      child: Container(
                          width: size.width,
                          decoration: new BoxDecoration(
                              color: Geel,
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 1.0,
                                  color: GrijsMidden,
                                  offset: Offset(0.3, 0.3),
                                ),
                              ],
                              borderRadius:
                                  new BorderRadius.all(Radius.circular(10.0))),
                          child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                "€" +
                                    gebruikerData['Portefeuille']
                                        .toStringAsFixed(2),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontSize: 50),
                              )))),
                  Container(
                    height: size.height * 0.50,
                    child: new ListView.builder(
                      itemCount: portefeuilleHistoriek.length,
                      itemBuilder: (context, index) {
                        return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: ListTile(
                              onTap: null,
                              trailing: Text(
                                  portefeuilleHistoriek[index]['Type'] +
                                      " € " +
                                      portefeuilleHistoriek[index]
                                              ['TotalePrijs']
                                          .toStringAsFixed(2),
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              leading: Icon(FontAwesomeIcons.moneyBill),
                              title: Text(
                                  portefeuilleHistoriek[index]['BestellingId'],
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ));
                      },
                    ),
                  ),
                  Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(right: 15.0),
                          child: ButtonTheme(
                            shape: RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(10.0)),
                            padding: const EdgeInsets.all(0.0),
                            child: RaisedButton(
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      new BorderRadius.circular(10.0)),
                              child: Stack(
                                  alignment: Alignment.center,
                                  children: <Widget>[
                                    ColorFiltered(
                                        colorFilter: ColorFilter.mode(
                                            Geel.withOpacity(0.75),
                                            BlendMode.srcOver),
                                        child: ClipRRect(
                                          child: Image.asset(
                                            'assets/images/geldToevoegen.jpg',
                                            width: size.width * 0.40,
                                            height: size.width * 0.40,
                                            fit: BoxFit.cover,
                                          ),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10.0)),
                                        )),
                                    Center(
                                        child: Column(
                                      children: <Widget>[
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 20.0),
                                          child: Text(
                                            "Portefeuille",
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                                fontSize: 20,
                                                shadows: [
                                                  Shadow(
                                                    blurRadius: 10.0,
                                                    color: Colors.black,
                                                    offset: Offset(3.0, 3.0),
                                                  ),
                                                ]),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Text(
                                          "Aanvullen",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              fontSize: 22,
                                              shadows: [
                                                Shadow(
                                                  blurRadius: 10.0,
                                                  color: Colors.black,
                                                  offset: Offset(3.0, 3.0),
                                                ),
                                              ]),
                                          textAlign: TextAlign.center,
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Icon(
                                            FontAwesomeIcons.arrowCircleDown,
                                            color: White,
                                            size: 30,
                                          ),
                                        )
                                      ],
                                    ))
                                  ]),
                              onPressed: portefeuilleAanvullen,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 15.0),
                          child: ButtonTheme(
                            shape: RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(12.0)),
                            padding: const EdgeInsets.all(0.0),
                            child: RaisedButton(
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      new BorderRadius.circular(20.0)),
                              child: Stack(
                                  alignment: Alignment.center,
                                  children: <Widget>[
                                    ColorFiltered(
                                        colorFilter: ColorFilter.mode(
                                            GrijsDark.withOpacity(0.75),
                                            BlendMode.srcOver),
                                        child: ClipRRect(
                                          child: Image.asset(
                                            'assets/images/geldAanvragen.jpg',
                                            width: size.width * 0.40,
                                            height: size.width * 0.40,
                                            fit: BoxFit.cover,
                                          ),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10.0)),
                                        )),
                                    Center(
                                        child: Column(
                                      children: <Widget>[
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 20.0),
                                          child: Text(
                                            "€" +
                                                gebruikerData['Portefeuille']
                                                    .toStringAsFixed(2),
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                                fontSize: 20,
                                                shadows: [
                                                  Shadow(
                                                    blurRadius: 10.0,
                                                    color: Colors.black,
                                                    offset: Offset(3.0, 3.0),
                                                  ),
                                                ]),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Text(
                                          "Afhalen",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              fontSize: 22,
                                              shadows: [
                                                Shadow(
                                                  blurRadius: 10.0,
                                                  color: Colors.black,
                                                  offset: Offset(3.0, 3.0),
                                                ),
                                              ]),
                                          textAlign: TextAlign.center,
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Icon(
                                            FontAwesomeIcons.arrowCircleUp,
                                            color: White,
                                            size: 30,
                                          ),
                                        )
                                      ],
                                    ))
                                  ]),
                              onPressed: () {},
                            ),
                          ),
                        )
                      ])
                ],
              ))
          : Container(
              child: SpinKitDoubleBounce(
                color: Geel,
                size: 100,
              ),
            ),
    );
  }
}
