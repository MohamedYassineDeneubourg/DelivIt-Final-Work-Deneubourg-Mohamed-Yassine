import 'package:delivit/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/profileUpdate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Profile extends StatefulWidget {
  Profile({Key key, this.userEmail}) : super(key: key);
  final String userEmail;
  @override
  _ProfileState createState() => _ProfileState(userEmail: this.userEmail);
}

class _ProfileState extends State<Profile> with TickerProviderStateMixin {
  _ProfileState({Key key, @required this.userEmail});
  final String userEmail;
  num bezorgdeBestellingen = 0;
  num gekregenBestellingen = 0;
  num _ratingScore = 2.5;
  Map gebruikerData;
  List ratingMessages = [];
  TabController _tabBarController;
  String connectedUserEmail;

  void getCurrentUser() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    setState(() {
      connectedUserEmail = user.email;
    });
  }

  @override
  void initState() {
    _tabBarController = TabController(length: 0, vsync: this);
    _getData();
    super.initState();
  }

  _getData() {
    print(userEmail);
    print("Getting data of user...");
    var reference =
        Firestore.instance.collection("Users").document(userEmail).snapshots();

    reference.listen((data) {
      if (this.mounted) {
        setState(() {
          // print("Refreshed");
          gebruikerData = data.data;
          ratingMessages = data.data['RatingMessages'];
          if (ratingMessages != null) {
            setState(() {
              _tabBarController =
                  TabController(length: ratingMessages.length, vsync: this);
            });
          }
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
      height: screenSize.height * 0.60,
      decoration: BoxDecoration(
        color: Geel.withOpacity(0.7),
        image: DecorationImage(
          image: NetworkImage(gebruikerData['ProfileImage']),
          fit: BoxFit.cover,
          colorFilter:
              ColorFilter.mode(Geel.withOpacity(0.6), BlendMode.srcOver),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Container(
        width: 140.0,
        height: 140.0,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(gebruikerData['ProfileImage']),
            fit: BoxFit.contain,
          ),
          borderRadius: BorderRadius.circular(80.0),
          border: Border.all(
            color: Colors.white,
            width: 10.0,
          ),
        ),
      ),
    );
  }

  Widget _buildFullName() {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(gebruikerData['Voornaam'] + " " + gebruikerData['Naam'],
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black,
                      offset: Offset(3.0, 3.0),
                    ),
                  ],
                  fontSize: 26),
              textAlign: TextAlign.center),
          _buildRatingBars()
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String count) {
    TextStyle _statLabelTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 20.0,
      fontWeight: FontWeight.w200,
    );

    TextStyle _statCountTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 30.0,
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
      ],
    );
  }

  Widget _buildStatContainer() {
    return Container(
      margin: EdgeInsets.only(top: 20.0),
      decoration: BoxDecoration(color: GrijsDark.withOpacity(0.2)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildStatItem("Bezorgd", bezorgdeBestellingen.toString()),
            _buildStatItem(
              "Besteld",
              gekregenBestellingen.toString(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBars() {
    return Container(
      margin: EdgeInsets.only(top: 8.0, bottom: 8),
      padding: EdgeInsets.only(right: 8, left: 8),
      decoration: new BoxDecoration(
          color: White.withOpacity(0.5),
          borderRadius: BorderRadius.all(Radius.circular(15))),
      child: RatingBarIndicator(
        rating: _ratingScore,
        itemBuilder: (context, index) => Icon(
          Icons.star,
          color: GrijsDark,
        ),
        itemCount: 5,
        itemSize: 35.0,
        direction: Axis.horizontal,
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

  Widget _buildComments(BuildContext context) {
    return Container(
        height: MediaQuery.of(context).size.height * 0.15,
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: EdgeInsets.only(top: 8.0, right: 15, left: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.arrow_back_ios),
              onPressed: () {
                print("back");
                if (_tabBarController.index > 0 &&
                    (_tabBarController.index < _tabBarController.length)) {
                  print(_tabBarController.index.toString() +
                      ' : ' +
                      _tabBarController.length.toString());
                  _tabBarController.animateTo(_tabBarController.index - 1);
                } else {}
              },
            ),
            Expanded(
                child: TabBarView(
                    controller: _tabBarController,
                    children: ratingMessages.map((var ratingMessage) {
                      return Card(
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: Geel.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Container(
                              padding: EdgeInsets.all(15),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(ratingMessage['Person'] + " : ",
                                      style: TextStyle(
                                          color: GrijsDark,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                  Text(
                                      "Score: " +
                                          ratingMessage['Score'].toString(),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10)),
                                  Expanded(
                                    child: Text(
                                        ratingMessage['Message'] +
                                            "dfcghjkfvbifsdf hqdshf hdsdfbjh shjdfj sjfhbhsq dfsbjhf qsfhjbqs dhfhj fbhjdfj sjfhbhsq dfsbjhf qsfhjbqs dhfhj fbhjdfj sjfhbhsq dfsbjhf qsfhjbqs dhfhj fbhjdfj sjfhbhsq dfsbjhf qsfhjbqs dhfhj fbhjdfj sjfhbhsq dfsbjhf qsfhjbqs dhfhj fbhjdfj sjfhbhsq dfsbjhf qsfhjbqs dhfhj fbhjdfj sjfhbhsq dfsbjhf qsfhjbqs dhfhj fbhjdfj sjfhbhsq dfsbjhf qsfhjbqs dhfhj fbhjdfj sjfhbhsq dfsbjhf qsfhjbqs dhfhj fbhjdfj sjfhbhsq dfsbjhf qsfhjbqs dhfhj fbhjdfj sjfhbhsq dfsbjhf qsfhjbqs dhfhj fbhjdfj sjfhbhsq dfsbjhf qsfhjbqs dhfhj fbhjdfj sjfhbhsq dfsbjhf qsfhjbqs dhfhj fbhjdfj sjfhbhsq dfsbjhf qsfhjbqs dhfhj fbh",
                                        maxLines: 12,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: true,
                                        style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontSize: 12)),
                                  )
                                ],
                              )));
                    }).toList())),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios),
              onPressed: () {
                if (_tabBarController.index >= 0 &&
                    (_tabBarController.index < _tabBarController.length - 1)) {
                  print(_tabBarController.index.toString() +
                      ' : ' +
                      _tabBarController.length.toString());
                  _tabBarController.animateTo(_tabBarController.index + 1);
                } else {}
              },
            )
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
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
                      backgroundColor: White.withOpacity(0.5),
                      child: Icon(
                        Icons.edit,
                        size: 25,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ProfileUpdate(),
                                fullscreenDialog: true));
                      }),
                )
              : Container(
                  width: 0,
                  height: 0,
                )
        ],
      ),
      body: (gebruikerData != null)
          ? Stack(
              children: <Widget>[
                _buildCoverImage(size),
                SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        _buildProfileImage(),
                        SizedBox(height: 10.0),
                        _buildFullName(),
                        _buildStatContainer(),
                        Container(
                          height: size.height * 0.55,
                          color: Colors.transparent,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              (ratingMessages.length != 0)
                                  ? Text(
                                      "Commentaar beoordeling aankopers..",
                                      textAlign: TextAlign.start,
                                    )
                                  : Text(
                                      "Er is geen beoordeling gemaakt..",
                                      textAlign: TextAlign.start,
                                    ),
                              (ratingMessages.length != 0)
                                  ? _buildComments(context)
                                  : Container(),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
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
