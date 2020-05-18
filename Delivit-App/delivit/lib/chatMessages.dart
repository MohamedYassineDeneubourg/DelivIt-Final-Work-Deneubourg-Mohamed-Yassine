import 'dart:async';
import 'package:delivit/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bubble/bubble.dart';
import 'globals.dart';

class ChatMessages extends StatefulWidget {
  ChatMessages(
      {Key key,
      this.conversationId,
      this.emailPartner,
      this.connectedUserEmail,
      this.naamVoornaam,
      this.fotoUrl})
      : super(key: key);

  final String conversationId;
  final String emailPartner;
  final String connectedUserEmail;
  final String naamVoornaam;
  final String fotoUrl;

  @override
  _ChatMessagesState createState() => _ChatMessagesState(
      conversationId: conversationId,
      connectedUserEmail: connectedUserEmail,
      emailPartner: emailPartner,
      naamVoornaam: naamVoornaam,
      fotoUrl: fotoUrl);
}

class _ChatMessagesState extends State<ChatMessages> {
  _ChatMessagesState(
      {Key key,
      @required this.conversationId,
      @required this.emailPartner,
      @required this.naamVoornaam,
      @required this.connectedUserEmail,
      @required this.fotoUrl});

  final String conversationId;
  final String emailPartner;
  final String naamVoornaam;
  final String fotoUrl;
  final String connectedUserEmail;
  String _message;
  TextEditingController messageController = TextEditingController();
  ScrollController _scrollController = new ScrollController();
  final _formKey = new GlobalKey<FormState>();
  final _formKeyTwo = new GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    print(naamVoornaam);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown(context));

    return Scaffold(
        appBar: new AppBar(
            centerTitle: true,
            title: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  GestureDetector(
                      child: Padding(
                        padding: EdgeInsets.all(0),
                        child: ClipOval(
                            child: Image.network(
                          fotoUrl,
                          height: 35,
                          width: 35,
                          fit: BoxFit.fill,
                        )),
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            SlideTopRoute(
                                page: Profile(
                              userEmail: emailPartner,
                            )));
                      }),
                  Padding(
                    padding: EdgeInsets.only(right: size.width * 0.15),
                    child: Text(naamVoornaam.toString()),
                  )
                ],
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
              print('Scrol!');
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
                        Padding(
                            padding: EdgeInsets.all(12),
                            child: TextFormField(
                              controller: messageController,
                              decoration: InputDecoration(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      Icons.keyboard_arrow_right,
                                      size: 35,
                                    ),
                                    color: Geel,
                                    onPressed: () {
                                      sendMessage(false);
                                    },
                                  ),
                                  border: new OutlineInputBorder(
                                      borderSide:
                                          new BorderSide(color: Colors.teal),
                                      borderRadius: BorderRadius.circular(20)),
                                  hintText: 'Schrijf je bericht...'),
                              validator: (value) => value.isEmpty
                                  ? "Geen bericht werd geschreven.."
                                  : null,
                              onSaved: (value) => _message = value,
                            ))
                      ],
                    )),
              ));
            } else {
              return Text("Aucun message..");
            }
          },
        ));
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
            padding: EdgeInsets.only(top: 5, left: size.width * 0.90),
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
            padding: EdgeInsets.only(top: 5, right: size.width * 0.90),
            child: Text(
              time,
              style: TextStyle(color: GrijsDark, fontSize: 12),
            ),
          ),
        ],
      );
    }
  }

  Future sendMessage(bool automaticMessage) async {
    print("Sending message...");
    final form = _formKey.currentState;
    if (form.validate() && !automaticMessage) {
      form.save();
      print('validated!');
      final FirebaseUser userData = await FirebaseAuth.instance.currentUser();
      if (userData != null) {
        try {
          await Firestore.instance
              .collection("Conversations")
              .document(conversationId)
              .updateData({
            'Messages': FieldValue.arrayUnion([
              {
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

    if (automaticMessage) {
      final FirebaseUser userData = await FirebaseAuth.instance.currentUser();
      if (userData != null) {
        try {
          await Firestore.instance
              .collection("Conversations")
              .document(conversationId)
              .updateData({
            'Messages': FieldValue.arrayUnion([
              {
                'Auteur': userData.email,
                'Message': "Ik heb nu een automatische bericht sturen..",
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
    print('Scrolled');
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
      print('Form is valid.');
      return true;
    }

    return false;
  }
}
