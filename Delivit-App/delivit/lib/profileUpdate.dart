import 'dart:async';

import 'package:delivit/globals.dart';
import 'package:delivit/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keyboard_avoider/keyboard_avoider.dart';
import 'dart:io';
import 'package:path/path.dart' as Path;

class ProfileUpdate extends StatefulWidget {
  ProfileUpdate({Key key, this.title}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() => new _ProfileUpdateState();
}

class _ProfileUpdateState extends State<ProfileUpdate> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String connectedUserMail;
  Map gebruikerData;

  String profileImageUrl =
      "https://www.autourdelacom.fr/wp-content/uploads/2018/03/default-user-image.png";

  File image;

  String _biographie = "";
  String _etablissement;
  String _etudes;
  String _anneeEtude;

  List competencesChoisie = [];
  List competencesGrowingChoisie = [];
  List competencesGrowingStudying = [];

  List<DropdownMenuItem<String>> schoolList = [];
  List<DropdownMenuItem<String>> studiesList = [];
  List<DropdownMenuItem<String>> yearList = [];

  List<DropdownMenuItem> competList = [];

  List allCompetences = [];
  List allGrowingCompetences = [];

  final ScrollController _scrollController = ScrollController();
  var biographieController = TextEditingController();

  StreamSubscription<DocumentSnapshot> _getFirebaseSubscription;

  @override
  void dispose() {
    _getFirebaseSubscription.cancel();
    super.dispose();
  }

  @override
  void initState() {
    getCurrentUser();
    loadSchoolsAndStudies();
    super.initState();
  }

  void getCurrentUser() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    print(user);
    if (user != null) {
      setState(() {
        connectedUserMail = user.email;
      });

      _getData();
    }
  }

  _getData() {
    var reference = Firestore.instance
        .collection("Users")
        .document(connectedUserMail)
        .snapshots();

    _getFirebaseSubscription = reference.listen((data) {
      if (this.mounted) {
        setState(() {
          // print("Refreshed");
          gebruikerData = data.data;
          if (data.data['ProfileImage'] != null) {
            profileImageUrl = data.data['ProfileImage'];
          }

          biographieController.text = data.data['Biographie'];
          _biographie = data.data['Biographie'];
          _anneeEtude = data.data['AnneeEtude'];
          _etudes = data.data['Etudes'];
          _etablissement = data.data['Etablissement'];
          competencesChoisie = data.data['Competences'];
          competencesGrowingChoisie = data.data['CompetencesGrowing'];
          competencesGrowingStudying =
              competencesChoisie + competencesGrowingChoisie;
        });
      }
    });
  }

  void loadSchoolsAndStudies() async {
    schoolList = [];
    await Firestore.instance
        .collection("Global")
        .document('globalDocument')
        .get()
        .then((e) {
      // print(e.data);
      allCompetences = e.data['Competences'];
      allGrowingCompetences = e.data['CompetencesGrowing'];
      List etablissements = e.data['Etablissements'];
      List etudes = e.data['Etudes'];
      List annees = e.data['Annees'];

      etablissements.forEach((etab) {
        print(etab);
        schoolList.add(new DropdownMenuItem(
          child: new Text(etab),
          value: etab,
        ));
        //print(etab);
      });

      etudes.forEach((etud) {
        studiesList.add(new DropdownMenuItem(
          child: new Text(etud),
          value: etud,
        ));
        //print(etud);
      });

      annees.forEach((etab) {
        yearList.add(new DropdownMenuItem(
          child: new Text(etab),
          value: etab,
        ));
        //print(etab);
      });
    });
    setState(() {
      _etablissement = _etablissement;
      _etudes = _etudes;
      _anneeEtude = _anneeEtude;
    });
  }

  final _formKey = new GlobalKey<FormState>();
  final focus = FocusNode();

  @override
  Widget build(BuildContext context) {
    print(MediaQuery.of(context).viewInsets.bottom);
    Size size = MediaQuery.of(context).size;
    return KeyboardAvoider(
        child: Scaffold(
            appBar: new AppBar(
              backgroundColor: White,
              actionsIconTheme: IconThemeData(color: Geel),
              iconTheme: IconThemeData(color: Geel),
              textTheme: TextTheme(
                  headline6: TextStyle(
                      color: Geel,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      fontFamily: "Poppins")),
              centerTitle: true,
              title: new Text("MODIFIER SON PROFIL"),
            ),
            key: _scaffoldKey,
            resizeToAvoidBottomInset: false,
            resizeToAvoidBottomPadding: false,
            floatingActionButton: (MediaQuery.of(context).viewInsets.bottom !=
                    0)
                ? null
                : Padding(
                    padding: const EdgeInsets.only(bottom: 25.0),
                    child: FloatingActionButton.extended(
                      heroTag: "ENVOYER",
                      splashColor: GrijsDark,
                      elevation: 4.0,
                      backgroundColor: Geel,
                      icon: const Icon(
                        FontAwesomeIcons.save,
                        color: White,
                      ),
                      label: Text(
                        "SAUVEGARDER MODIFICATIONS",
                        style: TextStyle(
                            color: White, fontWeight: FontWeight.w800),
                      ),
                      onPressed: () async {
                        try {
                          await Firestore.instance
                              .collection("Users")
                              .document(connectedUserMail)
                              .updateData({
                            "Biographie": _biographie,
                            "Competences": competencesChoisie,
                            "CompetencesGrowing": competencesGrowingChoisie,
                            "Etablissement": _etablissement,
                            "Etudes": _etudes,
                            "AnneeEtude": _anneeEtude,
                          });

                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(12.0))),
                                title: new Text(
                                  "C'EST FAIT !",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(
                                      Icons.check_circle,
                                      size: 60,
                                      color: Geel,
                                    ),
                                    Text("Votre profil a été mis à jour !",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))
                                  ],
                                ),
                                actions: <Widget>[
                                  ButtonTheme(
                                      minWidth: 400.0,
                                      child: RaisedButton(
                                        color: GrijsDark,
                                        child: Text(
                                          "OK",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          Navigator.of(context).pop();
                                          Navigator.push(
                                              context,
                                              SlideTopRoute(
                                                  page: Profile(
                                                userEmail: connectedUserMail,
                                              )));
                                        },
                                      ))
                                ],
                              );
                            },
                          );
                        } catch (e) {
                          print(e);
                        }
                      },
                    ),
                  ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            body: Stack(children: <Widget>[
              ColorFiltered(
                  colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.6), BlendMode.srcOver),
                  child: Image.asset(
                    'assets/images/backgroundLogin.jpg',
                    width: size.width,
                    height: size.height,
                    fit: BoxFit.cover,
                  )),
              SingleChildScrollView(
                child: Container(
                  margin: EdgeInsets.only(top: 0),
                  height: size.height * 0.90,
                  width: size.width,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        //Box met titel BEGIN

                        // EINDE box met titel
                        //BEGIN TEXTVELDEN

                        Form(
                            key: _formKey,
                            child: Expanded(
                                child: ListView(
                              controller: _scrollController,
                              children: <Widget>[
                                Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: <Widget>[
                                      Center(
                                        child: Container(
                                          margin: EdgeInsets.only(top: 35),
                                          width: 200.0,
                                          height: 200.0,
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: (gebruikerData != null)
                                                  ? NetworkImage(gebruikerData[
                                                      'ProfileImage'])
                                                  : NetworkImage(""),
                                              fit: BoxFit.contain,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(100.0),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                      RawMaterialButton(
                                        onPressed: () {
                                          fotoVeranderen(context);
                                        },
                                        child: new Icon(
                                          Icons.camera_alt,
                                          color: Geel,
                                          size: 15.0,
                                        ),
                                        shape: new CircleBorder(),
                                        elevation: 2.0,
                                        fillColor: Colors.white,
                                      ),
                                    ]),
                                Padding(
                                    padding: EdgeInsets.only(
                                        bottom: 15.0,
                                        right: 20,
                                        left: 20,
                                        top: 35),
                                    child: TextFormField(
                                      controller: biographieController,
                                      maxLines: 5,
                                      decoration: InputDecoration(
                                          errorStyle: TextStyle(
                                              fontWeight: FontWeight.w700),
                                          prefixIcon: Icon(
                                            Icons.person_pin,
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
                                          labelText: 'Biographie & offre',
                                          hintText:
                                              'Qui êtes vous? Que pouvez-vous offrir aux Tutties? Decrivez tout en détail, vendez-vous..'),
                                      onChanged: (value) => _biographie = value,
                                      onSaved: (value) => _biographie = value,
                                    )),
                                Padding(
                                    padding: EdgeInsets.only(
                                        bottom: 20.0, right: 20, left: 20),
                                    child: DropdownButtonFormField(
                                      decoration: InputDecoration(
                                        errorStyle: TextStyle(
                                            fontWeight: FontWeight.w700),
                                        prefixIcon: Icon(
                                          Icons.school,
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
                                          borderSide: BorderSide(
                                              color: Colors.red, width: 6),
                                        ),
                                      ),
                                      isExpanded: true,
                                      value: _etablissement,
                                      hint: Text("Etablissement"),
                                      onChanged: (value) {
                                        print("changed");
                                        print(value);
                                        setState(() {
                                          _etablissement = value;
                                        });
                                        print(_etablissement);
                                      },
                                      validator: (value) {
                                        if (value == null) {
                                          return "L'etablissement doit être rempli";
                                        }
                                        return null;
                                      },
                                      items: schoolList,
                                    )),
                                Padding(
                                    padding: EdgeInsets.only(
                                        bottom: 20.0, right: 20, left: 20),
                                    child: DropdownButtonFormField(
                                      decoration: InputDecoration(
                                        errorStyle: TextStyle(
                                            fontWeight: FontWeight.w700),
                                        prefixIcon: Icon(
                                          Icons.school,
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
                                          borderSide: BorderSide(
                                              color: Colors.red, width: 6),
                                        ),
                                      ),
                                      isExpanded: true,
                                      value: _etudes,
                                      hint: Text("Filière"),
                                      onChanged: (value) {
                                        setState(() {
                                          _etudes = value;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null) {
                                          return "La filière doit être rempli";
                                        }
                                        return null;
                                      },
                                      items: studiesList,
                                    )),
                                Padding(
                                    padding: EdgeInsets.only(
                                        bottom: 20.0, right: 20, left: 20),
                                    child: DropdownButtonFormField(
                                      decoration: InputDecoration(
                                        errorStyle: TextStyle(
                                            fontWeight: FontWeight.w700),
                                        prefixIcon: Icon(
                                          Icons.school,
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
                                          borderSide: BorderSide(
                                              color: Colors.red, width: 6),
                                        ),
                                      ),
                                      isExpanded: true,
                                      value: _anneeEtude,
                                      hint: Text("Année"),
                                      onChanged: (value) {
                                        setState(() {
                                          _anneeEtude = value;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null) {
                                          return "L'année doit être rempli";
                                        }
                                        return null;
                                      },
                                      items: yearList,
                                    )),
                                Padding(
                                    padding: EdgeInsets.only(
                                        right: 20, left: 20, top: 0),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Padding(
                                              padding:
                                                  EdgeInsets.only(bottom: 20.0),
                                              child: TextFormField(
                                                autofocus: false,
                                                style:
                                                    TextStyle(color: GrijsDark),
                                                readOnly: true,
                                                onTap: () async {
                                                  await showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return StatefulBuilder(
                                                        builder: (context,
                                                            setState) {
                                                          return AlertDialog(
                                                            shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            12.0))),
                                                            title: Text(
                                                                "Choix de compétences"),
                                                            content: Container(
                                                              height:
                                                                  size.height,
                                                              width: size.width,
                                                              child: ListView
                                                                  .builder(
                                                                      shrinkWrap:
                                                                          true,
                                                                      itemCount:
                                                                          allCompetences
                                                                              .length,
                                                                      itemBuilder:
                                                                          (context,
                                                                              index) {
                                                                        var compet =
                                                                            allCompetences[index];
                                                                        return new Card(
                                                                            margin: EdgeInsets.only(
                                                                                right: 0,
                                                                                left: 0,
                                                                                bottom: 6),
                                                                            shape: UnderlineInputBorder(
                                                                              borderSide: BorderSide(color: Geel, width: 1),
                                                                            ),
                                                                            color: (competencesChoisie.contains(compet)) ? GrijsLicht : White,
                                                                            child: ListTile(
                                                                              contentPadding: EdgeInsets.only(top: 0, bottom: 0, right: 20, left: 45),
                                                                              dense: true,
                                                                              trailing: Icon(
                                                                                (competencesChoisie.contains(compet)) ? Icons.check_box : null,
                                                                                color: Geel,
                                                                              ),
                                                                              title: new Text(
                                                                                compet,
                                                                                style: TextStyle(fontSize: 15),
                                                                              ),
                                                                              onTap: () {
                                                                                setState(() {
                                                                                  print(compet);
                                                                                  if (competencesChoisie.contains(compet)) {
                                                                                    competencesChoisie.remove(compet);
                                                                                  } else {
                                                                                    competencesChoisie.add(compet);
                                                                                  }

                                                                                  competencesGrowingStudying = competencesChoisie + competencesGrowingChoisie;
                                                                                });
                                                                                FocusScope.of(context).unfocus();
                                                                              },
                                                                            ));
                                                                        //print(etab);
                                                                      }),
                                                            ),
                                                            actions: <Widget>[
                                                              ButtonTheme(
                                                                  minWidth:
                                                                      400.0,
                                                                  child:
                                                                      FlatButton(
                                                                    color: Geel,
                                                                    child:
                                                                        new Text(
                                                                      "CHOISIR",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white,
                                                                          fontWeight:
                                                                              FontWeight.bold),
                                                                    ),
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop();
                                                                      print(
                                                                          competencesChoisie);
                                                                      print(
                                                                          "oslm");
                                                                      setState(
                                                                          () {
                                                                        competencesChoisie =
                                                                            competencesChoisie;

                                                                        competencesChoisie.length =
                                                                            competencesChoisie.length;

                                                                        competencesGrowingStudying =
                                                                            competencesChoisie +
                                                                                competencesGrowingChoisie;
                                                                      });
                                                                      FocusScope.of(
                                                                              context)
                                                                          .unfocus();
                                                                    },
                                                                  )),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    },
                                                  ).then((e) {
                                                    setState(() {
                                                      competencesChoisie =
                                                          competencesChoisie;

                                                      competencesChoisie
                                                              .length =
                                                          competencesChoisie
                                                              .length;

                                                      competencesGrowingStudying =
                                                          competencesChoisie +
                                                              competencesGrowingChoisie;
                                                    });
                                                  });
                                                },
                                                scrollPadding:
                                                    EdgeInsets.all(3),
                                                decoration: InputDecoration(
                                                    labelText:
                                                        (competencesChoisie
                                                                    .length ==
                                                                0)
                                                            ? "Matière"
                                                            : competencesChoisie
                                                                    .length
                                                                    .toString() +
                                                                " Matière(s) ",
                                                    errorStyle: TextStyle(
                                                        fontWeight: FontWeight
                                                            .w700),
                                                    prefixIcon: Icon(
                                                      Icons.stars,
                                                      color: Geel,
                                                    ),
                                                    fillColor: Colors.white,
                                                    filled: true,
                                                    enabled: false,
                                                    focusedBorder:
                                                        UnderlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: Geel,
                                                          width: 6),
                                                    ),
                                                    border:
                                                        new UnderlineInputBorder(),
                                                    errorBorder:
                                                        UnderlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: Colors.red,
                                                          width: 6),
                                                    ),
                                                    suffixIcon: Icon(
                                                        Icons.arrow_drop_down)),
                                              )),
                                          Padding(
                                              padding:
                                                  EdgeInsets.only(bottom: 60.0),
                                              child: TextFormField(
                                                readOnly: true,
                                                onTap: () async {
                                                  setState(() {
                                                    competencesGrowingChoisie =
                                                        competencesGrowingChoisie;

                                                    competencesGrowingStudying =
                                                        competencesChoisie +
                                                            competencesGrowingChoisie;
                                                  });
                                                  await showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return StatefulBuilder(
                                                        builder: (context,
                                                            setState) {
                                                          return AlertDialog(
                                                            shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            12.0))),
                                                            title: Text(
                                                                "Choix de compétences"),
                                                            content: Container(
                                                              height:
                                                                  size.height,
                                                              width: size.width,
                                                              child: ListView
                                                                  .builder(
                                                                      shrinkWrap:
                                                                          true,
                                                                      itemCount:
                                                                          allGrowingCompetences
                                                                              .length,
                                                                      itemBuilder:
                                                                          (context,
                                                                              index) {
                                                                        var compet =
                                                                            allGrowingCompetences[index];
                                                                        return new Card(
                                                                            margin: EdgeInsets.only(
                                                                                right: 0,
                                                                                left: 0,
                                                                                bottom: 6),
                                                                            shape: UnderlineInputBorder(
                                                                              borderSide: BorderSide(color: Geel, width: 1),
                                                                            ),
                                                                            color: (competencesGrowingChoisie.contains(compet)) ? GrijsLicht : White,
                                                                            child: ListTile(
                                                                              contentPadding: EdgeInsets.only(top: 0, bottom: 0, right: 20, left: 45),
                                                                              dense: true,
                                                                              trailing: Icon(
                                                                                (competencesGrowingChoisie.contains(compet)) ? Icons.check_box : null,
                                                                                color: Geel,
                                                                              ),
                                                                              title: new Text(
                                                                                compet,
                                                                                style: TextStyle(fontSize: 15),
                                                                              ),
                                                                              onTap: () {
                                                                                setState(() {
                                                                                  print(compet);
                                                                                  if (competencesGrowingChoisie.contains(compet)) {
                                                                                    competencesGrowingChoisie.remove(compet);
                                                                                  } else {
                                                                                    competencesGrowingChoisie.add(compet);
                                                                                  }

                                                                                  competencesGrowingStudying = competencesChoisie + competencesGrowingChoisie;
                                                                                });
                                                                              },
                                                                            ));
                                                                        //print(etab);
                                                                      }),
                                                            ),
                                                            actions: <Widget>[
                                                              ButtonTheme(
                                                                  minWidth:
                                                                      400.0,
                                                                  child:
                                                                      FlatButton(
                                                                    color: Geel,
                                                                    child:
                                                                        new Text(
                                                                      "CHOISIR",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white,
                                                                          fontWeight:
                                                                              FontWeight.bold),
                                                                    ),
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop();
                                                                      setState(
                                                                          () {
                                                                        competencesGrowingChoisie =
                                                                            competencesGrowingChoisie;

                                                                        competencesGrowingStudying =
                                                                            competencesChoisie +
                                                                                competencesGrowingChoisie;
                                                                      });
                                                                      FocusScope.of(
                                                                              context)
                                                                          .unfocus();
                                                                    },
                                                                  )),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    },
                                                  ).then((e) {
                                                    setState(() {
                                                      print(competencesChoisie);
                                                      competencesChoisie =
                                                          competencesChoisie;

                                                      competencesGrowingStudying =
                                                          competencesChoisie +
                                                              competencesGrowingChoisie;
                                                    });
                                                  });
                                                },
                                                style:
                                                    TextStyle(color: GrijsDark),
                                                decoration: InputDecoration(
                                                  labelText: (competencesGrowingChoisie
                                                              .length ==
                                                          0)
                                                      ? "Développement personnel "
                                                      : competencesGrowingChoisie
                                                              .length
                                                              .toString() +
                                                          " Compétence(s)",
                                                  suffixIcon: Icon(
                                                      Icons.arrow_drop_down),
                                                  errorStyle: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700),
                                                  prefixIcon: Icon(
                                                    Icons.trending_up,
                                                    color: Geel,
                                                  ),
                                                  fillColor: Colors.white,
                                                  filled: true,
                                                  enabled: false,
                                                  focusedBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Geel, width: 6),
                                                  ),
                                                  border:
                                                      new UnderlineInputBorder(),
                                                  errorBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Colors.red,
                                                        width: 6),
                                                  ),
                                                ),
                                              )),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 100.0),
                                            child: Container(
                                                padding: EdgeInsets.only(
                                                    top: 10,
                                                    bottom: 0,
                                                    right: 20,
                                                    left: 20),
                                                width: size.width,
                                                decoration: new BoxDecoration(
                                                    color: GrijsLicht,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        blurRadius: 1.0,
                                                        color: GrijsMidden,
                                                        offset:
                                                            Offset(0.3, 0.3),
                                                      ),
                                                    ],
                                                    borderRadius:
                                                        new BorderRadius.all(
                                                            Radius.circular(
                                                                10.0))),
                                                child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: <Widget>[
                                                      (competencesGrowingChoisie
                                                                  .isEmpty &&
                                                              competencesChoisie
                                                                  .isEmpty)
                                                          ? Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                          .only(
                                                                      bottom:
                                                                          10.0),
                                                              child: Container(
                                                                padding: EdgeInsets
                                                                    .only(
                                                                        top: 5,
                                                                        left:
                                                                            10,
                                                                        right:
                                                                            10,
                                                                        bottom:
                                                                            5),
                                                                decoration: BoxDecoration(
                                                                    color: Geel
                                                                        .withOpacity(
                                                                            0.3),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            50)),
                                                                child: Center(
                                                                  child: Text(
                                                                      "Vous n'avez aucun filtre",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .black,
                                                                          fontWeight:
                                                                              FontWeight.w700)),
                                                                ),
                                                              ),
                                                            )
                                                          : Container(
                                                              width: 0,
                                                              height: 0),
                                                      competencesChoisie
                                                                  .isNotEmpty ||
                                                              competencesGrowingChoisie
                                                                  .isNotEmpty
                                                          ? Container(
                                                              height: 20 *
                                                                  (competencesGrowingStudying
                                                                          .length
                                                                          .toDouble() +
                                                                      1),
                                                              width: size.width,
                                                              child: GridView
                                                                  .builder(
                                                                itemCount:
                                                                    competencesGrowingStudying
                                                                        .length,
                                                                itemBuilder: (BuildContext
                                                                            context,
                                                                        int index) =>
                                                                    new Container(
                                                                  height: 5,
                                                                  padding: EdgeInsets
                                                                      .only(
                                                                          top:
                                                                              5,
                                                                          left:
                                                                              10,
                                                                          right:
                                                                              10,
                                                                          bottom:
                                                                              5),
                                                                  decoration: BoxDecoration(
                                                                      color: competencesChoisie.contains(competencesGrowingStudying[
                                                                              index])
                                                                          ? Geel.withOpacity(
                                                                              0.3)
                                                                          : Geel.withOpacity(
                                                                              0.5),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              50)),
                                                                  child: Text(
                                                                      competencesGrowingStudying[
                                                                          index],
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .black,
                                                                          fontWeight:
                                                                              FontWeight.w700)),
                                                                ),
                                                                gridDelegate:
                                                                    SliverGridDelegateWithFixedCrossAxisCount(
                                                                  childAspectRatio:
                                                                      5.6,
                                                                  crossAxisCount:
                                                                      2,
                                                                  crossAxisSpacing:
                                                                      5.0,
                                                                  mainAxisSpacing:
                                                                      5.0,
                                                                ),
                                                              ),
                                                            )
                                                          : Container(
                                                              width: 0,
                                                              height: 0),
                                                    ])),
                                          ),
                                        ]))
                              ],
                            ))),

                        //EINDE TEXTVELDEN
                      ]),
                ),
              )
            ])));
  }

  Future gellerijFoto() async {
    File imageGallerij = await ImagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxHeight: 1080,
        maxWidth: 1080);

    ImageProperties properties =
        await FlutterNativeImage.getImageProperties(imageGallerij.path);

    File croppedFile;
    int difference;
    if (properties.width < properties.height) {
      difference = properties.height - properties.width;

      croppedFile = await FlutterNativeImage.cropImage(imageGallerij.path, 0,
          (difference * 0.5).toInt(), properties.width, properties.width);
    } else {
      difference = properties.width - properties.height;
      croppedFile = await FlutterNativeImage.cropImage(imageGallerij.path,
          (difference * 0.5).toInt(), 0, properties.height, properties.height);
    }

    setState(() {
      image = croppedFile;
    });
    if (image != null) {
      uploadToStorage(croppedFile);
    }
  }

  Future neemFoto() async {
    var imageCamera = await ImagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxHeight: 1080,
        maxWidth: 1080);

    ImageProperties properties =
        await FlutterNativeImage.getImageProperties(imageCamera.path);

    File croppedFile;
    int difference;
    if (properties.width < properties.height) {
      difference = properties.height - properties.width;

      croppedFile = await FlutterNativeImage.cropImage(imageCamera.path, 0,
          (difference * 0.5).toInt(), properties.width, properties.width);
    } else {
      difference = properties.width - properties.height;
      croppedFile = await FlutterNativeImage.cropImage(imageCamera.path,
          (difference * 0.5).toInt(), 0, properties.height, properties.height);
    }
    setState(() {
      image = croppedFile;
    });
    if (croppedFile != null) {
      uploadToStorage(croppedFile);
    }
  }

  Future uploadToStorage(File image) async {
    setState(() {
      profileImageUrl = image.path;
    });
    print(image.path);
    String fileName = Path.basename(image.path);
    print(fileName);
    StorageReference firebaseStorageRef =
        FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = firebaseStorageRef.putFile(image);
    await uploadTask.onComplete;

    var dowurl = await (await uploadTask.onComplete).ref.getDownloadURL();
    var url = dowurl.toString();

    try {
      Firestore.instance
          .collection('Users')
          .document(connectedUserMail)
          .updateData({"ProfileImage": url});
    } catch (e) {
      print(e.message);
    }
  }

  fotoVeranderen(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12.0))),
          title: new Text(
            "Fais ton choix",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: new Text("Petit conseil: Choisi ta meilleure photo!"),
          actions: <Widget>[
            ButtonTheme(
                minWidth: 400.0,
                child: RaisedButton(
                  color: GeelAccent,
                  child: Text(
                    "CAMERA",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    neemFoto();
                    Navigator.of(context).pop();
                  },
                )),
            ButtonTheme(
                minWidth: 400.0,
                child: RaisedButton(
                  color: Geel,
                  child: Text(
                    "GALLERIE",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    gellerijFoto();
                    Navigator.of(context).pop();
                  },
                )),
            ButtonTheme(
                minWidth: 400.0,
                child: RaisedButton(
                  color: GrijsDark,
                  child: Text(
                    "ANNULER",
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
