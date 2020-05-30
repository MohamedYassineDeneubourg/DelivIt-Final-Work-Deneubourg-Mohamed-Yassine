import 'dart:async';
import 'dart:core';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:delivit/Algemeen/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bubble/bubble.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:delivit/globals.dart';
class ChatMessages extends StatefulWidget {
  ChatMessages(
      {Key key,
      this.conversationId,
      this.emailPartner,
      this.connectedUserEmail,
      this.naamVoornaam,
      this.fotoUrl})
      : super(key: key);

  final String connectedUserEmail;
  final String conversationId;
  final String emailPartner;
  final String naamVoornaam;
  final String fotoUrl;

  @override
  _ChatMessagesState createState() => _ChatMessagesState(
        conversationId: conversationId,
        connectedUserEmail: connectedUserEmail,
        emailPartner: emailPartner,
        naamVoornaam: naamVoornaam,
        fotoUrl: fotoUrl,
      );
}

class _ChatMessagesState extends State<ChatMessages> {
  _ChatMessagesState(
      {Key key,
      @required this.conversationId,
      @required this.emailPartner,
      @required this.naamVoornaam,
      @required this.connectedUserEmail,
      @required this.fotoUrl});

  Map adresPosition;
  final String connectedUserEmail;
  final String conversationId;
  DateTime datum;
  final datumController = TextEditingController();
  final String emailPartner;
  TextEditingController messageController = TextEditingController();
  final String naamVoornaam;
  final nummerController = TextEditingController();
  final String fotoUrl;
  final postcodeController = TextEditingController();
  Map prestation;
  final straatController = TextEditingController();
  num tempsPrestation = 30;
  Map tutuForPrice;

  final _formKey = new GlobalKey<FormState>();
  final _formKeyTwo = new GlobalKey<FormState>();
  String _message;
  String _myName;
  ScrollController _scrollController = new ScrollController();

  @override
  void dispose() {
    leaveLive();
    if (mounted) {
      super.dispose();
    }
  }

  @override
  void initState() {
    _getMyData();

    goLive();

    super.initState();
  }

  _getMyData() {
    var reference = Firestore.instance
        .collection("Users")
        .document(connectedUserEmail)
        .snapshots();

    reference.listen((data) {
      if (this.mounted) {
        setState(() {
          _myName = data.data['Naam'].toUpperCase() +
              " " +
              data.data['Voornaam'].toUpperCase();
        });
      }
    });
  }

  void goLive() {
    Firestore.instance
        .collection('Users')
        .document(connectedUserEmail)
        .updateData({
      "inConversations": FieldValue.arrayUnion([conversationId])
    });
  }

  void leaveLive() {
    Firestore.instance
        .collection('Users')
        .document(connectedUserEmail)
        .updateData({
      "inConversations": FieldValue.arrayRemove([conversationId])
    });
  }

  _showMessage(String auteur, String message, var dateAndTime) {
    var date = (dateAndTime as Timestamp).toDate();

    Size size = MediaQuery.of(context).size;
    String time = date.hour.toString().padLeft(2, "0") +
        ":" +
        date.minute.toString().padLeft(2, "0");

    if (auteur != emailPartner) {
      return Column(
        children: <Widget>[
          Bubble(
            alignment: Alignment.topRight,
            stick: true,
            margin: BubbleEdges.only(top: 10, left: 25),
            nip: BubbleNip.rightBottom,
            child: Text(
              message,
              style: TextStyle(color: White, fontSize: 16),
            ),
            color: Geel,
            elevation: 3,
          ),
          Padding(
            padding: EdgeInsets.only(top: 5, left: size.width * 0.80),
            child: Text(
              time,
              style: TextStyle(color: GrijsDark, fontSize: 12),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: <Widget>[
          Bubble(
            alignment: Alignment.topLeft,
            margin: BubbleEdges.only(top: 10, right: 25),
            nip: BubbleNip.leftBottom,
            child: Text(
              message,
              style: TextStyle(fontSize: 16),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 5, right: size.width * 0.80),
            child: Text(
              time,
              style: TextStyle(color: GrijsDark, fontSize: 12),
            ),
          ),
        ],
      );
    }
  }

  Future sendMessage(
      bool automaticMessage, String automaticMessageString) async {
    final form = _formKey.currentState;
    if (!automaticMessage) {
      if (form.validate()) {
        form.save();
        final FirebaseUser userData = await FirebaseAuth.instance.currentUser();
        if (userData != null) {
          try {
            await Firestore.instance
                .collection("Conversations")
                .document(conversationId)
                .updateData({
              'LastMessageTime': DateTime.now(),
              'Messages': FieldValue.arrayUnion([
                {
                  'AuteurName': _myName,
                  'Auteur': userData.email,
                  'Message': _message,
                  'DateAndTime': DateTime.now()
                }
              ])
            });
          } catch (e) {
            print('Error:$e');
          }
        }

        messageController.text = "";
      }
    }

    if (automaticMessage) {
      final FirebaseUser userData = await FirebaseAuth.instance.currentUser();
      if (userData != null) {
        try {
          await Firestore.instance
              .collection("Conversations")
              .document(conversationId)
              .updateData({
            'LastMessageTime': DateTime.now(),
            'Messages': FieldValue.arrayUnion([
              {
                'AuteurName': _myName,
                'Auteur': userData.email,
                'Message': automaticMessageString,
                'DateAndTime': DateTime.now()
              }
            ])
          });
        } catch (e) {
          print('Error:$e');
        }
      }
    }
  }

  _scrollDown(BuildContext context) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 10),
        curve: Curves.easeOut,
      );
    }
  }

  bool validerEnSave() {
    final form = _formKeyTwo.currentState;

    if (form.validate()) {
      form.save();
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown(context));

    return Scaffold(
        appBar: new AppBar(
            backgroundColor: Geel,
            textTheme: TextTheme(
                headline6: TextStyle(
                    color: White,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    fontFamily: "Montserrat")),
            centerTitle: true,
            actions: <Widget>[
              GestureDetector(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: ClipOval(
                          child: Image.network(
                        fotoUrl,
                        height: size.height * 0.04,
                        width: size.height * 0.04,
                        fit: BoxFit.fill,
                      )),
                    ),
                  ),
                  onTap: () async {
                    Navigator.push(
                        context,
                        SlideTopRoute(
                            page: Profile(
                          userEmail: emailPartner,
                          comingFromMessage: true,
                        )));
                  }),
            ],
            title: Padding(
              padding: EdgeInsets.only(right: 0),
              child: AutoSizeText(
                naamVoornaam.toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )),
        body: StreamBuilder<DocumentSnapshot>(
          stream: Firestore.instance
              .collection('Conversations')
              .document(conversationId)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.hasData) {
              print(snapshot.data.data['Messages'].length);
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _scrollDown(context));

              return Scaffold(
                  body: Padding(
                padding:
                    EdgeInsets.only(top: 25.0, right: 5, left: 5, bottom: 15),
                child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        Expanded(
                            child: ListView.builder(
                          controller: _scrollController,
                          itemCount: snapshot.data.data['Messages'].length,
                          itemBuilder: (_, index) {
                            return _showMessage(
                                snapshot.data.data['Messages'][index]['Auteur'],
                                snapshot.data.data['Messages'][index]
                                    ['Message'],
                                snapshot.data.data['Messages'][index]
                                    ['DateAndTime']);
                          },
                        )),
                        SafeArea(
                            child: Padding(
                                padding: EdgeInsets.only(right: 5, left: 5),
                                child: TextFormField(
                                  minLines: 1,
                                  maxLines: 4,
                                  controller: messageController,
                                  decoration: InputDecoration(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          FontAwesomeIcons.arrowCircleRight,
                                          size: 30,
                                        ),
                                        color: Geel,
                                        onPressed: () {
                                          sendMessage(false, "");
                                        },
                                      ),
                                      border: new OutlineInputBorder(
                                          borderSide: new BorderSide(
                                              color: Colors.teal),
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      hintText: 'Schrijf je bericht...'),
                                  validator: (value) => value.isEmpty
                                      ? "Je hebt niets geschreven..."
                                      : null,
                                  onSaved: (value) => _message = value,
                                )))
                      ],
                    )),
              ));
            } else {
              return Text("Geen bericht...");
            }
          },
        ));
  }
}
