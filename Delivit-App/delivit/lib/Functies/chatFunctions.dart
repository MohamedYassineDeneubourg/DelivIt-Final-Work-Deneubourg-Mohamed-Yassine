import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/Algemeen/chatMessages.dart';
import 'package:delivit/globals.dart';
import 'package:flutter/material.dart';

goToConversation(
    String emailPartner,
    String naamVoornaamPartner,
    String fotoUrl,
    String connectedUserEmail,
    BuildContext context,
    bool comingFromMessage) async {
  final query = await Firestore.instance
      .collection("Conversations")
      .where('Users', arrayContains: connectedUserEmail)
      .getDocuments();

  List<DocumentSnapshot> documents = query.documents;
  DocumentSnapshot theDocument;

  documents.forEach((object) {
    if ((object.data['Users'].contains(emailPartner)) &&
        object.data['Users'].contains(connectedUserEmail)) {
      theDocument = object;
    }
  });
  if (theDocument == null) {
    createConversationAndGo(emailPartner, connectedUserEmail,
        naamVoornaamPartner, fotoUrl, context, comingFromMessage);
  } else {
    if (comingFromMessage == null || comingFromMessage == false) {
      Navigator.push(
          context,
          SlideTopRoute(
              page: ChatMessages(
                  conversationId: theDocument.documentID.toString(),
                  connectedUserEmail: connectedUserEmail,
                  emailPartner: emailPartner,
                  naamVoornaam: naamVoornaamPartner,
                  fotoUrl: fotoUrl)));
    } else {
      Navigator.pop(context);
    }
  }
}

createConversationAndGo(
    String emailPartner,
    String userId,
    String naamVoornaamPartner,
    String fotoUrl,
    BuildContext context,
    bool comingFromMessage) async {
  try {
    await Firestore.instance.collection("Conversations").document().setData({
      'LastMessageTime': DateTime.now(),
      'Users': [userId, emailPartner],
      'Messages': []
    }).then((e) {
      goToConversation(emailPartner, naamVoornaamPartner, fotoUrl, userId,
          context, comingFromMessage);
    });
  } catch (e) {
    print('Error:$e');
  }
}

checkIfOnline(state, email) async {
  print('chck');
  if (email != null) {
    var reference = Firestore.instance.collection("Users").document(email);
    if (state == AppLifecycleState.resumed) {
      await reference.updateData({'isOnline': true});
    } else {
      await reference.updateData({'isOnline': false});
    }
  }
}
