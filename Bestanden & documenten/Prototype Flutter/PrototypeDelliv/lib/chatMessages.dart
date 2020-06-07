import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bubble/bubble.dart';

class ChatMessages extends StatefulWidget {
  ChatMessages({Key key, this.conversationId, this.emailPartner})
      : super(key: key);

  final String conversationId;
  final String emailPartner;

  @override
  _ChatMessagesState createState() => _ChatMessagesState(
      conversationId: conversationId, emailPartner: emailPartner);
}

class _ChatMessagesState extends State<ChatMessages> {
  _ChatMessagesState(
      {Key key, @required this.conversationId, @required this.emailPartner});

  final String conversationId;
  final String emailPartner;
  String _message;
  TextEditingController messageController = TextEditingController();
  ScrollController _scrollController = new ScrollController();
  final _formKey = new GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown(context));

    return Scaffold(
        appBar: new AppBar(
            centerTitle: true, title: new Text(emailPartner.toString())),
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
                padding: EdgeInsets.all(5.0),
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
                                    ['Message']);
                          },
                        )),
                        TextFormField(
                          controller: messageController,
                          decoration: InputDecoration(
                              suffixIcon: IconButton(
                                icon: Icon(Icons.send),
                                color: Colors.amber,
                                onPressed: sendMessage,
                              ),
                              border: new OutlineInputBorder(
                                  borderSide:
                                      new BorderSide(color: Colors.teal),
                                  borderRadius: BorderRadius.circular(20)),
                              hintText: 'Message...'),
                          validator: (value) =>
                              value.isEmpty ? "Moet ing" : null,
                          onSaved: (value) => _message = value,
                        )
                      ],
                    )),
              ));
            } else {
              return Text("geen data");
            }
          },
        ));
  }

  _showMessage(String auteur, String message) {
    if (auteur != emailPartner) {
      return Bubble(
        alignment: Alignment.topRight,
        stick: true,
        margin: BubbleEdges.only(top: 10),
        nip: BubbleNip.rightBottom,
        child: Text(message),
        color: Colors.amberAccent,
      );
    } else {
      return Bubble(
        alignment: Alignment.topLeft,
        margin: BubbleEdges.only(top: 10),
        nip: BubbleNip.leftBottom,
        child: Text(message),
      );
    }
  }

  Future sendMessage() async {
    print("Sending message...");
    final form = _formKey.currentState;
    if (form.validate()) {
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
  }

  _scrollDown(BuildContext context) {
    print('Scrolled');
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 10),
      curve: Curves.easeOut,
    );
  }
}
