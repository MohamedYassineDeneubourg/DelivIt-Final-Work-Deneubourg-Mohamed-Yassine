
import 'package:delivit/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Profile extends StatefulWidget {
  Profile({Key key, this.userEmail}) : super(key: key);
  String userEmail;
  @override
  _ProfileState createState() => _ProfileState(userEmail: this.userEmail);
}

class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  _ProfileState({Key key, @required this.userEmail});
  final String userEmail;
  num coursDonner = 0;
  num coursRecu = 0;
  num _ratingScore = 2.5;
  Map gebruikerData;
  List ratingMessages = [];
  TabController _tabBarController;

  @override
  void initState() {
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
          print(gebruikerData['Functie']);
          ratingMessages = data.data['RatingMessages'];
          _tabBarController =
              TabController(length: ratingMessages.length, vsync: this);
          //print(data.data);
        });
      }
    });

    Firestore.instance
        .collection('Prestations')
        .where("TutuEmail", isEqualTo: userEmail)
        .getDocuments()
        .then((e) {
      e.documents.length;
      setState(() {
        coursDonner = e.documents.length;
      });
    });

    Firestore.instance
        .collection('Prestations')
        .where("EtudiantEmail", isEqualTo: userEmail)
        .getDocuments()
        .then((e) {
      e.documents.length;
      setState(() {
        coursRecu = e.documents.length;
      });
    });

    print(gebruikerData);
  }

  Widget _buildCoverImage(Size screenSize) {
    return Container(
      height: screenSize.height * 0.50,
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
          (gebruikerData["Functie"] == "Tutu")
              ? _buildRatingBars()
              : Container(),
          Text(gebruikerData['Etablissement'],
              style: TextStyle(shadows: [
                Shadow(
                  blurRadius: 10.0,
                  color: Colors.black,
                  offset: Offset(3.0, 3.0),
                ),
              ], color: White, fontWeight: FontWeight.w700, fontSize: 17),
              textAlign: TextAlign.center),
          Text(gebruikerData['Etudes'] + " - " + gebruikerData['AnneeEtude'],
              style: TextStyle(
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black,
                      offset: Offset(3.0, 3.0),
                    ),
                  ],
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String count) {
    TextStyle _statLabelTextStyle = TextStyle(
      color: Colors.black,
      fontSize: 16.0,
      fontWeight: FontWeight.w200,
    );

    TextStyle _statCountTextStyle = TextStyle(
      color: Colors.black54,
      fontSize: 24.0,
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
      margin: EdgeInsets.only(top: 15.0),
      decoration: BoxDecoration(
        color: Color(0xFFEFF4F7),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            (gebruikerData["Functie"] == "Tutu")
                ? _buildStatItem("Cours donné", coursDonner.toString())
                : _buildStatItem(
                    "Cours reçu",
                    coursRecu.toString(),
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
          Icons.school,
          color: Colors.amber,
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

  Widget _buildBio(BuildContext context, Size screenSize) {
    return Padding(
        padding: EdgeInsets.only(top: 25, left: 20, right: 20),
        child: Container(
          padding: EdgeInsets.all(5),
          decoration: BoxDecoration(
            border: Border.all(color: Geel.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          height: screenSize.height * 0.15,
          width: screenSize.width,
          child: SingleChildScrollView(
              child: Text(
            gebruikerData['Biographie'],
            style: TextStyle(color: Colors.black, fontSize: 14),
          )),
        ));
  }


  Widget _buildComments(BuildContext context) {
    return Container(
        height: MediaQuery.of(context).size.height * 0.10,
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
                          child: ListTile(
                            dense: true,
                            onTap: null,
                            subtitle: Text(
                                "Score: " + ratingMessage['Score'].toString(),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 10)),
                            title: Row(
                              children: <Widget>[
                                Text(ratingMessage['NomPrenom'] + " : ",
                                    style: TextStyle(
                                        color: GrijsDark,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                                Text(ratingMessage['Message'],
                                    style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 12))
                              ],
                            ),
                          ));
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
    Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          iconTheme: IconThemeData(color: White),
          actionsIconTheme: IconThemeData(color: White),
          backgroundColor: Colors.transparent),
      body: (gebruikerData != null)
          ? Stack(
              children: <Widget>[
                _buildCoverImage(screenSize),
                SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        _buildProfileImage(),
                        SizedBox(height: 10.0),
                        _buildFullName(),
                        _buildStatContainer(),
                        (gebruikerData["Functie"] == "Tutu")? Container(
                          color: White,
                          child: Column(
                            children: <Widget>[
                              
                              competences(context),
                             (ratingMessages.length != 0)? Text(
                                "Ce que les Tutties en pensent..",
                                textAlign: TextAlign.start,
                              ) : Text(
                                "Aucun avis n'a été déposé sur ce Tutu..",
                                textAlign: TextAlign.start,
                              ),
                             (ratingMessages.length != 0)? _buildComments(context) : Container(),
                            ],
                          ),
                        ) : Container(
                          color: White,
                          child: _buildBio(context, screenSize)),
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
