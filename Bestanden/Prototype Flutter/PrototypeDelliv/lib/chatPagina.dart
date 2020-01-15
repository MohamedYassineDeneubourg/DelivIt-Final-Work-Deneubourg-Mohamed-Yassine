import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo_yassine/betaalPersoon.dart';
import 'package:todo_yassine/chatMessages.dart';
import 'package:todo_yassine/dialog_modal.dart';

class ChatPagina extends StatefulWidget {
  ChatPagina({Key key, this.title}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() => new _ChatPaginaState();
}

class _ChatPaginaState extends State<ChatPagina> {
  String userId;
  void getCurrentUser() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    setState(() {
      userId = user.email;
    });

    showAlertDialog(
        context: context,
        title: "Betaling",
        description: "Voor betaling moet je lang op een gebruiker drukken!");
  }

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('Users').snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasData) {
          //print(snapshot.data.documents[0]["Naam"]);

          //List<Map> posts = List.from(snapshot.data);

          return Scaffold(
              body: ListView.builder(
            itemCount: snapshot.data.documents.length,
            itemBuilder: (_, index) {
              if (userId !=
                  snapshot.data.documents[index].documentID.toString()) {
                return Card(
                    child: ListTile(
                  onLongPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => BetaalPersoon(
                                persoonEmail: snapshot
                                    .data.documents[index].documentID
                                    .toString(),
                              ),
                          fullscreenDialog: true),
                    );
                  },
                  onTap: () {
                    goToConversation(
                        snapshot.data.documents[index].documentID.toString());
                  },
                  title: Text(snapshot.data.documents[index]['Naam']),
                  trailing: isOnline(snapshot.data.documents[index]['isOnline']),
                  leading: CircleAvatar(
                    
                    child: ClipOval(
                      child: (snapshot.data.documents[index]
                                  ['profileImageUrl'] !=
                              null)
                          ? Image.network(
                              snapshot.data.documents[index]['profileImageUrl'],
                              fit: BoxFit.fill)
                          : Image.network(
                              "https://www.autourdelacom.fr/wp-content/uploads/2018/03/default-user-image.png",
                              fit: BoxFit.fill),
                    ),
                  ),
                ));
              } else {
                return Card();
              }
            },
          ));
        } else {
          return Text("geen data");
        }
      },
    );
  }

  isOnline(bool isOnline) {
    if (isOnline) {
      return Padding(
          padding: EdgeInsets.only(top: 10),
          child: Column(children: <Widget>[
            Text(
              'Online!',
              style: TextStyle(fontSize: 10, color: Colors.green),
            ),
            Icon(
              Icons.fiber_manual_record,
              color: Colors.green,
              semanticLabel: 'Online',
            )
          ]));
    } else {
      return Padding(
          padding: EdgeInsets.only(top: 10),
          child: Column(children: <Widget>[
            Text(
              'Offline',
              style: TextStyle(fontSize: 10, color: Colors.red),
            ),
            Icon(
              Icons.fiber_manual_record,
              color: Colors.red,
              semanticLabel: 'Offline',
            )
          ]));
    }
  }

  goToConversation(String emailPartner) async {
    //print("user: " + userId);
    //print("Partner: " + emailPartner);

    final query = await Firestore.instance
        .collection("Conversations")
        .where('Users', arrayContains: userId)
        .getDocuments();

    List<DocumentSnapshot> documents = query.documents;
    DocumentSnapshot theDocument;

    documents.forEach((object) {
      if ((object.data['Users'].contains(emailPartner)) &&
          object.data['Users'].contains(userId)) {
        print('bestaat');

        theDocument = object;
      }
    });
    if (theDocument == null) {
      createConversationAndGo(emailPartner, userId);
      print("EersteCreatie");
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ChatMessages(
                conversationId: theDocument.documentID.toString(),
                emailPartner: emailPartner),
            fullscreenDialog: true),
      );
    }
  }
}

createConversationAndGo(String emailPartner, String userId) async {
  try {
    await Firestore.instance.collection("Conversations").document().setData({
      'Users': [userId, emailPartner],
      'Messages': [
        {
          'Auteur': userId,
          'Message': "Hey!",
          // 'TodoDatum': DateTime.now()
        }
      ]
    });
  } catch (e) {
    print('Error:$e');
  }
  print('Conversation creating...');
}
