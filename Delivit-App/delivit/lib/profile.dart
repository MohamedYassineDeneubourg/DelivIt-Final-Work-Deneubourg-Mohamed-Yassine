import 'dart:async';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:delivit/globals.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/profileUpdate.dart';
import 'package:expandable/expandable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:snaplist/snaplist.dart';

class Profile extends StatefulWidget {
  Profile({Key key, this.userEmail}) : super(key: key);
  final String userEmail;
  @override
  _ProfileState createState() => _ProfileState(userEmail: this.userEmail);
}

class _ProfileState extends State<Profile> with TickerProviderStateMixin {
  StreamSubscription<DocumentSnapshot> _getFirebaseSubscription;

  _ProfileState({Key key, @required this.userEmail});
  final String userEmail;
  num bezorgdeBestellingen = 0;
  num gekregenBestellingen = 0;
  Map gebruikerData;
  List ratingMessages = [];
  String connectedUserEmail;
  Size size;

  void getCurrentUser() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    setState(() {
      print(userEmail);
      connectedUserEmail = user.email;
    });
  }

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
    _getData();
    super.initState();
  }

  _getData() {
    print(userEmail);
    print("Getting data of user...");
    var reference =
        Firestore.instance.collection("Users").document(userEmail).snapshots();

    _getFirebaseSubscription = reference.listen((data) {
      if (this.mounted) {
        setState(() {
          // print("Refreshed");
          gebruikerData = data.data;
          ratingMessages = data.data['RatingMessages'];
          if (ratingMessages != null) {}
          //print(data.data);
        });
      }
    });

    Firestore.instance
        .collection('Commands')
        .where("BezorgerEmail", isEqualTo: userEmail)
        .getDocuments()
        .then((e) {
      e.documents.length;
      setState(() {
        bezorgdeBestellingen = e.documents.length;
      });
    });

    Firestore.instance
        .collection('Commands')
        .where("AankoperEmail", isEqualTo: userEmail)
        .getDocuments()
        .then((e) {
      e.documents.length;
      setState(() {
        gekregenBestellingen = e.documents.length;
      });
    });

    print(gebruikerData);
  }

  Widget _buildCoverImage(Size screenSize) {
    return Container(
        padding: EdgeInsets.only(top: size.height * 0.1),
        width: size.width,
        decoration: new BoxDecoration(
            image: DecorationImage(
                colorFilter:
                    ColorFilter.mode(Geel.withOpacity(0.05), BlendMode.srcOver),
                image: NetworkImage(
                  gebruikerData['ProfileImage'],
                ),
                fit: BoxFit.cover),
            color: Geel,
            borderRadius: new BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10))),
        child: Padding(
            padding: EdgeInsets.only(
                top: (size.aspectRatio > 0.57)
                    ? size.height / 5.5
                    : size.height / 4.7,
                left: 20,
                bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: AutoSizeText(
                          gebruikerData['Voornaam'].toUpperCase() +
                              " " +
                              gebruikerData['Naam'].toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.black,
                                  offset: Offset(
                                    5.0,
                                    5.0,
                                  ),
                                ),
                              ],
                              fontSize: 26),
                          textAlign: TextAlign.left),
                    ),
                    // getBadge(gebruikerData['RatingScore']),
                    // SizedBox(width: 8),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(top: 3, bottom: 0),
                      padding:
                          EdgeInsets.only(right: 8, left: 8, top: 2, bottom: 2),
                      decoration: new BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.all(Radius.circular(15))),
                      child: RatingBarIndicator(
                        rating: gebruikerData['RatingScore'].toDouble(),
                        unratedColor: GrijsDark,
                        itemBuilder: (context, index) => Icon(
                          Icons.star,
                          color: Geel,
                        ),
                        itemCount: 5,
                        itemSize: (size.aspectRatio > 0.57) ? 18 : 24.0,
                        direction: Axis.horizontal,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 5, bottom: 5),
                      padding: (size.aspectRatio > 0.57)
                          ? EdgeInsets.only(
                              right: 8, left: 8, top: 4, bottom: 4)
                          : EdgeInsets.only(
                              right: 8, left: 8, top: 6, bottom: 6),
                      decoration: new BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.all(Radius.circular(15))),
                      child: Text(
                        gebruikerData['RatingScore']
                                .toDouble()
                                .toStringAsFixed(2) +
                            "/5",
                        style: TextStyle(
                            color: White, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                )
              ],
            )));
  }

  Widget _buildStatItem(String label, String count) {
    TextStyle _statLabelTextStyle = TextStyle(
      color: GrijsDark,
      fontSize: 10.0,
      fontWeight: FontWeight.w800,
    );

    TextStyle _statCountTextStyle = TextStyle(
      color: Black,
      fontSize: 25.0,
      fontWeight: FontWeight.bold,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count,
          style: _statCountTextStyle,
        ),
        Text(
          label,
          style: _statLabelTextStyle,
        ),
        SizedBox(height: 5)
      ],
    );
  }

  Widget _buildStatContainer() {
    return Container(
      decoration: BoxDecoration(
        color: GrijsMidden.withOpacity(0.15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildStatItem(
                "BESTELLINGEN BEZORGD", bezorgdeBestellingen.toString()),
            /* _buildStatItem(
              "Besteld",
              gekregenBestellingen.toString(),
            )*/
          ],
        ),
      ),
    );
  }

  Widget competences(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    List competencesFull =
        gebruikerData['Competences'] + gebruikerData['CompetencesGrowing'];
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 10),
      child: Container(
        height: screenSize.height * 0.10,
        width: screenSize.width,
        child: GridView.builder(
          itemCount: competencesFull.length,
          itemBuilder: (BuildContext context, int index) => new Container(
            height: 5,
            padding: EdgeInsets.only(top: 5, left: 10, right: 10, bottom: 5),
            decoration: BoxDecoration(
                color: Geel.withOpacity(0.5),
                borderRadius: BorderRadius.circular(50)),
            child: Text(competencesFull[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            childAspectRatio: 3.9,
            crossAxisCount: 3,
            crossAxisSpacing: 3.0,
            mainAxisSpacing: 3.0,
          ),
        ),
      ),
    );
  }

  Widget reviewsComponent() {
    return Container(
        margin: EdgeInsets.only(top: 15),
        height: MediaQuery.of(context).size.height * 0.22,
        child: SnapList(
          sizeProvider: (index, data) => Size(
              ratingMessages.length == 1
                  ? MediaQuery.of(context).size.width * 0.9
                  : MediaQuery.of(context).size.width * 0.70,
              MediaQuery.of(context).size.height * 0.29),
          separatorProvider: (index, data) => Size(10.0, 10.0),
          builder: (context, index, data) {
            return Container(
              padding: EdgeInsets.all(16),
              decoration: new BoxDecoration(
                  color: GrijsMidden.withOpacity(0.15),
                  borderRadius: BorderRadius.all(Radius.circular(15))),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ExpandablePanel(
                    header: RatingBarIndicator(
                      rating: ratingMessages[index]['Score'].toDouble(),
                      unratedColor: GrijsDark,
                      itemBuilder: (context, index) => Icon(
                        Icons.star,
                        color: Geel,
                      ),
                      itemCount: 5,
                      itemSize: (size.aspectRatio > 0.57) ? 16 : 20.0,
                      direction: Axis.horizontal,
                    ),
                    collapsed: Text(
                        "« " + ratingMessages[index]['Message'] + " »",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.normal, fontSize: 20)),
                    expanded: Text(
                        "« " + ratingMessages[index]['Message'] + " »",
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.normal, fontSize: 20)),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AutoSizeText(ratingMessages[index]['Person'],
                          maxLines: 2,
                          style: TextStyle(
                              fontSize: 13,
                              color: GrijsDark,
                              fontWeight: FontWeight.bold)),
                      AutoSizeText(
                          getDatumToString(ratingMessages[index]['Datum']),
                          maxLines: 1,
                          style: TextStyle(
                              color: GrijsMidden,
                              fontWeight: FontWeight.w900,
                              fontSize: 17)),
                    ],
                  ),
                ],
              ),
            );
          },
          count: ratingMessages.length,
        ));
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: White),
        actionsIconTheme: IconThemeData(color: White),
        backgroundColor: Colors.transparent,
        actions: <Widget>[
          (userEmail == connectedUserEmail)
              ? Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: FloatingActionButton(
                      mini: true,
                      backgroundColor: White.withOpacity(0.6),
                      child: Icon(
                        Icons.edit,
                        size: 25,
                        color: GrijsDark,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context, SlideTopRoute(page: ProfileUpdate()));
                      }),
                )
              : Container(
                  width: 0,
                  height: 0,
                )
        ],
      ),
      body: (gebruikerData != null)
          ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _buildCoverImage(size),
                  _buildStatContainer(),
                  Container(
                    height: size.height * 0.35,
                    padding: EdgeInsets.only(left: 20),
                    color: Colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        (ratingMessages.length != 0)
                            ? Text(
                                "Beoordeling",
                                style: TextStyle(
                                    color: GrijsDark,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16),
                                textAlign: TextAlign.start,
                              )
                            : Text(
                                "Geen beoordeling...",
                                style: TextStyle(
                                    color: GrijsDark,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16),
                                textAlign: TextAlign.start,
                              ),
                        Container(
                          margin: EdgeInsets.only(top: 10),
                          height: 2,
                          width: 50,
                          color: Geel,
                        ),
                        (ratingMessages.length != 0)
                            ? reviewsComponent()
                            : Container(),
                      ],
                    ),
                  )
                ],
              ),
            )
          : Container(
              child: SpinKitDoubleBounce(
                color: Geel,
                size: 100,
              ),
            ),
    );
  }
}

getBadge(_ratingScore) {
  _ratingScore = _ratingScore.toDouble();

  if (_ratingScore < 2.5) {
    return SizedBox();
  }

  if (_ratingScore >= 2.5 && _ratingScore <= 3.4) {
    return Container(
      padding: EdgeInsets.all(4),
      child: Icon(FontAwesomeIcons.award,
          size: 28, color: Color(0xffcd7f32)), //BRONZE
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: GrijsDark,
              blurRadius: 10.0, // has the effect of softening the shadow
              spreadRadius: 2.0, // has the effect of extending the shadow
              offset: Offset(
                0.0, // horizontal, move right 10
                10.0, // vertical, move down 10
              ),
            )
          ],
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(30.0))),
    );
  }

  if (_ratingScore > 3.4 && _ratingScore <= 4.4) {
    return Container(
      padding: EdgeInsets.all(4),
      child: Icon(FontAwesomeIcons.award,
          size: 28, color: Color(0xffc0c0c0)), //BRONZE
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: GrijsDark,
              blurRadius: 10.0, // has the effect of softening the shadow
              spreadRadius: 2.0, // has the effect of extending the shadow
              offset: Offset(
                0.0, // horizontal, move right 10
                10.0, // vertical, move down 10
              ),
            )
          ],
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(30.0))),
    );
  }

  if (_ratingScore > 4.4 /*&& ratingScore <= 5.0*/) {
    return Container(
      padding: EdgeInsets.all(4),
      child: Icon(
        FontAwesomeIcons.award,
        size: 28,
        color: Colors.amber,
      ), //BRONZE
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: GrijsDark,
              blurRadius: 10.0, // has the effect of softening the shadow
              spreadRadius: 2.0, // has the effect of extending the shadow
              offset: Offset(
                0.0, // horizontal, move right 10
                10.0, // vertical, move down 10
              ),
            )
          ],
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(30.0))),
    );
  }
}
