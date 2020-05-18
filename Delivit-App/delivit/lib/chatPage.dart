import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'chatMessages.dart';
import 'globals.dart';

class ChatPage extends StatefulWidget {
  ChatPage({Key key, this.isTutu}) : super(key: key);
  final bool isTutu;

  @override
  State<StatefulWidget> createState() =>
      new _ChatPageState(isTutu: this.isTutu);
}

class _ChatPageState extends State<ChatPage> {
  _ChatPageState({Key key, @required this.isTutu});
  final bool isTutu;
  String connectedUserEmail;
  List<Widget> cardList = [];

  setStateIt() {
    setState(() {
      cardList = cardList;
    });
  }

  List userList;
  void getCurrentUser() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    getList(user.email);
    setState(() {
      connectedUserEmail = user.email;
    });
  }

  void getList(email) async {
    await Firestore.instance
        .collection("Conversations")
        .where("Users", arrayContains: email)
        .getDocuments()
        .then((data) {
      print("CONNECTED USER EMAIL:");
      print(connectedUserEmail);
      setState(() {
        userList = data.documents;
      });
      cardList = [];
      print("LEEEENG:");
      print(userList.length);
      userList.forEach((data) async {
        print(data.documentID);
        //print(data);
        Map conv = data.data;
        // print(conv);
        Map user;
        var reference;
        if (conv['Users'][0] == connectedUserEmail) {
          reference = Firestore.instance
              .collection("Users")
              .document(conv['Users'][1])
              .get();
        } else {
          reference = Firestore.instance
              .collection("Users")
              .document(conv['Users'][0])
              .get();
        }
        await reference.then((data) {
          user = data.data;
          if (user != null) {
            print("CARD OK : ");
            print(user['Email']);
            setState(() {
              cardList.add(Card(
                  child: ListTile(
                onTap: () {
                  goToConversation(
                      user['Email'],
                      user['Naam'].toUpperCase() +
                          " " +
                          user['Voornaam'].toUpperCase(),
                      user['ProfileImage']);
                },
                title: Text(user['Naam'].toUpperCase() +
                    " " +
                    user['Voornaam'].toUpperCase()),
                // trailing: isOnline(user['isOnline']),
                leading: CircleAvatar(
                  child: ClipOval(
                      child: Image.network(user['ProfileImage'],
                          fit: BoxFit.fill)),
                ),
              )));
              print("CREATED!");
            });
          }
        });

        //print(etab);
      });
    }).then((e) {
      setState(() {
        cardList = cardList;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    //Size size = MediaQuery.of(context).size;

    return Scaffold(
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
          title: new Text("Messages"),
        ),
        body: (cardList.isNotEmpty)
            ? Container(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: ListView(
                    children: cardList,
                  ),
                ),
              )
            : Container(
                child: SpinKitDoubleBounce(
                  color: Geel,
                  size: 100,
                ),
              ));
  }

/*
SI IL ES EN LIGNE : FONCTIONNEL !
  isOnline(bool isOnline) {
    if (isOnline) {
      return Padding(
          padding: EdgeInsets.only(top: 10),
          child: Column(children: <Widget>[
            Text(
              'En ligne',
              style: TextStyle(fontSize: 10, color: Colors.green),
            ),
            Icon(
              Icons.fiber_manual_record,
              color: Colors.green,
              semanticLabel: 'En ligne',
            )
          ]));
    } else {
      return Padding(
          padding: EdgeInsets.only(top: 10),
          child: Column(children: <Widget>[
            Text(
              'Hors ligne',
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
*/
  goToConversation(
      String emailPartner, String naamVoornaam, String fotoUrl) async {
    //print("user: " + userId);
    //print("Partner: " + emailPartner);
    print(naamVoornaam);
    final query = await Firestore.instance
        .collection("Conversations")
        .where('Users', arrayContains: connectedUserEmail)
        .getDocuments();

    List<DocumentSnapshot> documents = query.documents;
    DocumentSnapshot theDocument;

    documents.forEach((object) {
      if ((object.data['Users'].contains(emailPartner)) &&
          object.data['Users'].contains(connectedUserEmail)) {
        print('bestaat');

        theDocument = object;
      }
    });
    if (theDocument == null) {
      createConversationAndGo(
          emailPartner, connectedUserEmail, naamVoornaam, fotoUrl);
      print("EersteCreatie");
    } else {
      Navigator.push(
          context,
          SlideTopRoute(
            page: ChatMessages(
              conversationId: theDocument.documentID.toString(),
              connectedUserEmail: connectedUserEmail,
              emailPartner: emailPartner,
              naamVoornaam: naamVoornaam,
              fotoUrl: fotoUrl,
            ),
          ));
    }
  }

  createConversationAndGo(String emailPartner, String userId,
      String naamVoornaam, String fotoUrl) async {
    try {
      await Firestore.instance.collection("Conversations").document().setData({
        'Users': [userId, emailPartner],
        'Messages': [
          {
            'Auteur': userId,
            'Message': "Hey " +
                naamVoornaam +
                " ! J'ai besoin de toi pour me filer un coup de main. Est-ce que tu es disponible ? À tout de suite !",
            'DateAndTime': DateTime.now(),
            // 'TodoDatum': DateTime.now()
          }
        ]
      }).then((e) {
        goToConversation(emailPartner, naamVoornaam, fotoUrl);
      });
    } catch (e) {
      print('Error:$e');
    }
    print('Conversation creating...');
  }
}
