import 'dart:async';

import 'package:delivit/UI-elementen/popups.dart';
import 'package:delivit/globals.dart';
import 'package:delivit/Algemeen/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/main.dart';
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

  List competencesChoisie = [];
  List competencesGrowingChoisie = [];
  List competencesGrowingStudying = [];

  List<DropdownMenuItem<String>> schoolList = [];
  List<DropdownMenuItem<String>> studiesList = [];
  List<DropdownMenuItem<String>> yearList = [];

  List<DropdownMenuItem> competList = [];

  List allCompetences = [];
  List allGrowingCompetences = [];

  var biographieController = TextEditingController();

  StreamSubscription<DocumentSnapshot> _getFirebaseSubscription;

  bool userDeleted = false;

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
      if (this.mounted && !userDeleted) {
        setState(() {
          // print("Refreshed");
          gebruikerData = data.data;
          if (data.data['ProfileImage'] != null) {
            profileImageUrl = data.data['ProfileImage'];
          }
        });
      }
    });
  }

  final focus = FocusNode();

  @override
  Widget build(BuildContext context) {
    print(MediaQuery.of(context).viewInsets.bottom);
    Size size = MediaQuery.of(context).size;
    return KeyboardAvoider(
        child: Scaffold(
            appBar: AppBar(
                backgroundColor: White,
                textTheme: TextTheme(
                    headline6: TextStyle(
                        color: Geel,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        fontFamily: "Montserrat")),
                centerTitle: true,
                title: Text("PROFIEL WIJZIGEN")),
            key: _scaffoldKey,
            resizeToAvoidBottomInset: false,
            resizeToAvoidBottomPadding: false,
            floatingActionButton: (MediaQuery.of(context).viewInsets.bottom !=
                    0)
                ? null
                : Padding(
                    padding: const EdgeInsets.only(bottom: 25.0),
                    child: FloatingActionButton.extended(
                      heroTag: "SEND",
                      splashColor: GrijsDark,
                      elevation: 4.0,
                      backgroundColor: Geel,
                      icon: const Icon(
                        FontAwesomeIcons.save,
                        color: White,
                      ),
                      label: Text(
                        "UPDATEN",
                        style: TextStyle(
                            color: White, fontWeight: FontWeight.w800),
                      ),
                      onPressed: () async {
                        try {
                          uploadToStorage(image);
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(12.0))),
                                title: new Text(
                                  "IN ORDE !",
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
                                    Text("Je profiel is aangepast!",
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
                      Colors.white.withOpacity(0.9), BlendMode.srcOver),
                  child: Image.asset(
                    'assets/images/backgroundLogin.jpg',
                    width: size.width,
                    height: size.height,
                    fit: BoxFit.cover,
                  )),
              SingleChildScrollView(
                child: Center(
                  child: Container(
                    margin: EdgeInsets.only(
                      top: 0,
                    ),
                    height: size.height * 0.90,
                    width: size.width * 0.8,
                    child: Column(
                      children: <Widget>[
                        Stack(
                            alignment: Alignment.bottomCenter,
                            children: <Widget>[
                              Center(
                                child: Container(
                                  margin: EdgeInsets.only(
                                    top: 35,
                                  ),
                                  width: size.width * 0.6,
                                  height: size.width * 0.6,
                                  decoration: BoxDecoration(
                                    image: (gebruikerData != null)
                                        ? DecorationImage(
                                            image: (image != null)
                                                ? FileImage(image)
                                                : NetworkImage(profileImageUrl),
                                            fit: BoxFit.contain,
                                          )
                                        : null,
                                    borderRadius:
                                        BorderRadius.circular(size.width / 2),
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
                                  size: 20.0,
                                ),
                                shape: new CircleBorder(),
                                elevation: 2.0,
                                fillColor: Colors.white,
                              ),
                            ]),
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: ButtonTheme(
                              minWidth: 400.0,
                              child: RaisedButton(
                                color: GrijsDark,
                                child: Text(
                                  "WACHTWOORD WIJZIGEN",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  passwordreset(connectedUserMail, context);
                                },
                              )),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5.0),
                          child: ButtonTheme(
                              minWidth: 400.0,
                              child: RaisedButton(
                                color: Colors.red[400],
                                child: Text(
                                  "ACCOUNT VERWIJDEREN",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  //print("bevestiged code!");

                                  //  signIn();
                                },
                              )),
                        )
                      ],
                    ),
                  ),
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

    if (croppedFile != null) {
      setState(() {
        image = croppedFile;
        profileImageUrl = croppedFile.path;
      });
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
    if (croppedFile != null) {
      setState(() {
        image = croppedFile;
        profileImageUrl = croppedFile.path;
      });
    }
  }

  Future uploadToStorage(image) async {
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
            "MAAK JE KEUZE",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: new Text("Tip: Kies je beste foto!"),
          actions: <Widget>[
            ButtonTheme(
                minWidth: 400.0,
                child: RaisedButton(
                  color: Geel,
                  child: Text(
                    "NEEM EEN FOTO",
                    style: TextStyle(
                        color: GrijsDark, fontWeight: FontWeight.bold),
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
                    "GALLERIJ",
                    style: TextStyle(
                        color: GrijsDark, fontWeight: FontWeight.bold),
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
                    "ANNULEREN",
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

  deleteMyaccount() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12.0))),
          title: new Text(
            "ACCOUNT VERWIJDEREN",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.warning, size: 50, color: Colors.orange),
              Text(
                  "Weet je zeker dat u uw account permanent wilt verwijderen? Al je gegevens worden automatisch vernietigd.",
                  style: TextStyle(fontWeight: FontWeight.bold))
            ],
          ),
          actions: <Widget>[
            ButtonTheme(
                minWidth: 400.0,
                child: RaisedButton(
                  color: Colors.red,
                  child: Text(
                    "OUI",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();

                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12.0))),
                          title: new Text(
                            "ACCOUNT VERWIJDEREN",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.warning,
                                  size: 50, color: Colors.orange),
                              Text("Er is geen weg terug mogelijk.",
                                  style: TextStyle(fontWeight: FontWeight.bold))
                            ],
                          ),
                          actions: <Widget>[
                            ButtonTheme(
                                minWidth: 400.0,
                                child: RaisedButton(
                                  color: Colors.red,
                                  child: Text(
                                    "SUPPRIMER MON COMPTE",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () async {
                                    userDeleted = true;
                                    Firestore.instance
                                        .collection('Users')
                                        .document(connectedUserMail)
                                        .setData({
                                      'Naam': "USER",
                                      "Voornaam": "VERWIJDERD",
                                      "RatingScore": 0,
                                      "PhoneNumber": "000",
                                      "ShoppingBag": [],
                                      "Functie": null,
                                      "ProfileImage":
                                          "http://hitutu.be/profile.jpg",
                                      'isOnline': false,
                                      'Position': null,
                                    });
                                    var user = await FirebaseAuth.instance
                                        .currentUser();

                                    user.delete().then((e) {
                                      FirebaseAuth.instance.signOut();
                                      Navigator.pop(context);
                                      Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => Main()));
                                    });
                                  },
                                )),
                            ButtonTheme(
                                minWidth: 400.0,
                                child: RaisedButton(
                                  color: GrijsDark,
                                  child: Text(
                                    "ANNULER",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ))
                          ],
                        );
                      },
                    );
                  },
                )),
            ButtonTheme(
                minWidth: 400.0,
                child: RaisedButton(
                  color: GrijsDark,
                  child: Text(
                    "NON",
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
