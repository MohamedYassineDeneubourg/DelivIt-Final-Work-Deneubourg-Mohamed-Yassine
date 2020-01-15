import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:todo_yassine/LoginPagina.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:todo_yassine/buy_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:todo_yassine/order_sheet.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as Path;

class GebruikerPagina extends StatefulWidget {
  @override
  _GebruikerPaginaState createState() => _GebruikerPaginaState();
}

class _GebruikerPaginaState extends State<GebruikerPagina> {
  String userEmail = "";
  String userNaam = "";
  String userGeld = "";
  String profileImageUrl =
      "https://www.autourdelacom.fr/wp-content/uploads/2018/03/default-user-image.png";
  double addEuros = 5.0;
  File image;

  NumberPicker decimalNumberPicker;

  @override
  void initState() {
    _getUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print(profileImageUrl);
    return new Scaffold(
        appBar: new AppBar(
          centerTitle: true,
          title: new Text(userNaam),
        ),
        floatingActionButton: FloatingActionButton.extended(
            elevation: 4.0,
            icon: const Icon(Icons.directions_walk),
            label: const Text('Uitloggen'),
            onPressed: () {
              _signOut();
            }),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          child: new Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                icon: Icon(null),
                onPressed: () {},
              ),
            ],
          ),
        ),
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
              Stack(alignment: Alignment.bottomCenter, children: <Widget>[
                CircleAvatar(
                  radius: 80,
                  child: ClipOval(
                  
                    child: (image != null)
                        ? Image.file(image, fit: BoxFit.fill)
                        : Image.network(profileImageUrl, fit: BoxFit.fill),
                  ),
                ),
                RawMaterialButton(
                  onPressed: () {
                    fotoVeranderen(context);
                  },
                  child: new Icon(
                    Icons.camera_alt,
                    color: Colors.amber,
                    size: 15.0,
                  ),
                  shape: new CircleBorder(),
                  elevation: 2.0,
                  fillColor: Colors.white,
                ),
              ]),
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  "Email",
                  style: TextStyle(fontSize: 35),
                ),
              ),
              Text(userEmail, style: TextStyle(fontSize: 20)),
              Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text(
                    "Geldkrediet",
                    style: TextStyle(fontSize: 35),
                  )),
              Center(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  IconButton(
                    icon: Icon(
                      Icons.add_box,
                      color: Colors.green,
                    ),
                    onPressed: () {
                      _showDialog();
                    },
                  ),
                  Text("$userGeld Euro", style: TextStyle(fontSize: 20)),
                ],
              ))
            ])));
  }

  void _signOut() async {
    FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();
    Firestore.instance
        .collection('Users')
        .document(currentUser.email)
        .updateData({"isOnline": false});

    FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => LoginPagina(title: 'TodoApp - Login')),
        (Route<dynamic> route) => false);
  }

  void _getUser() async {
    final FirebaseUser userData = await FirebaseAuth.instance.currentUser();
    if (userData != null) {
      userEmail = userData.email;
      var reference =
          Firestore.instance.collection("Users").document(userData.email);

      reference.snapshots().listen((querySnapshot) {
        //print("SetState!");
        if (this.mounted) {
          setState(() {
            userEmail = querySnapshot.documentID;
            userNaam = querySnapshot.data['Naam'];
            userGeld = querySnapshot.data['GeldEuro'].toString();
            if (querySnapshot.data['profileImageUrl'] != null) {
              profileImageUrl = querySnapshot.data['profileImageUrl'];
            }
          });
          print(profileImageUrl);
        }
      });
    }
  }

  Future _showDialog() async {
    await showDialog<num>(
      context: context,
      builder: (BuildContext context) {
        return new NumberPickerDialog.decimal(
          minValue: 5,
          maxValue: 999,
          decimalPlaces: 2,
          initialDoubleValue: addEuros,
          title: new Text("Voeg geld toe"),
        );
      },
    ).then((num value) {
      print(value);
      if (value != null && value >= 5) {
        print("ADD $value to account");
        if (this.mounted) {
          setState(() => addEuros = value);
        }
        int prijs = (value * 100).toInt();
        setPrijs(prijs);
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => BuySheet()));
      }
    });
  }

  Future gellerijFoto() async {
    var imageFromLibrary =
        await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      image = imageFromLibrary;
    });
    if (imageFromLibrary != null) {
      uploadToStorage(imageFromLibrary);
    }
  }

  Future neemFoto() async {
    var imageFromCamera =
        await ImagePicker.pickImage(source: ImageSource.camera);
    setState(() {
      image = imageFromCamera;
    });
    if (imageFromCamera != null) {
      uploadToStorage(imageFromCamera);
    }
  }

  Future uploadToStorage(File image) async {
    String fileName = Path.basename(image.path);
    StorageReference firebaseStorageRef =
        FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = firebaseStorageRef.putFile(image);
    await uploadTask.onComplete;

    var dowurl = await (await uploadTask.onComplete).ref.getDownloadURL();
    var url = dowurl.toString();

    try {
      Firestore.instance
          .collection('Users')
          .document(userEmail)
          .updateData({"profileImageUrl": url});
    } catch (e) {
      print(e.message);
    }
  }

  fotoVeranderen(BuildContext context) {
    showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return CupertinoActionSheet(
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Annuleren"),
            ),
            actions: <Widget>[
              CupertinoActionSheetAction(
                onPressed: () {
                  neemFoto();
                  Navigator.of(context).pop();
                },
                child: Text("Camera"),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  gellerijFoto();
                  Navigator.of(context).pop();
                },
                child: Text("Gallerij"),
              )
            ],
          );
        });
  }
}
