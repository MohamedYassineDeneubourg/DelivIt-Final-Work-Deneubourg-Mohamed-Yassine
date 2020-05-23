import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/Controller/chatFunctions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'globals.dart';

class ChatPage extends StatefulWidget {
  ChatPage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String connectedUserEmail;
  List<Widget> cardList = [];
  List userList;
  void getCurrentUser() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    setState(() {
      connectedUserEmail = user.email;
    });
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: White,
            textTheme: TextTheme(
                headline6: TextStyle(
                    color: Geel,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    fontFamily: "Montserrat")),
            centerTitle: true,
            title: Text("BERICHTEN")),
        body: (connectedUserEmail != null)
            ? Container(
                color: GrijsMidden.withOpacity(0.1),
                child: StreamBuilder<QuerySnapshot>(
                    stream: Firestore.instance
                        .collection("Conversations")
                        .where("Messages", isGreaterThan: [])
                        .where("Users", arrayContains: connectedUserEmail)
                        .snapshots(),
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasData) {
                        List listChats = snapshot.data.documents;
                        print("lenght:" + listChats.length.toString());
                        listChats.sort((a, b) => a.data['LastMessageTime']
                            .compareTo(b.data['LastMessageTime']));
                        print(snapshot);
                        return Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: ListView.builder(
                              itemCount: listChats.length,
                              itemBuilder: (_, index) {
                                print(index);
                                var conv = listChats[index].data;
                                String partner;
                                String lastMessage =
                                    conv['Messages'].last['Message'];
                                if (conv['Users'][0] == connectedUserEmail) {
                                  partner = conv['Users'][1];
                                } else {
                                  partner = conv['Users'][0];
                                }

                                return StreamBuilder<DocumentSnapshot>(
                                    stream: Firestore.instance
                                        .collection('Users')
                                        .document(partner)
                                        .snapshots(),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<DocumentSnapshot>
                                            userData) {
                                      print(userData);
                                      if (userData.hasData) {
                                        var user = userData.data;
                                        return Card(
                                            child: ListTile(
                                          onTap: () {
                                            goToConversation(
                                                user['Email'],
                                                user['Naam'].toUpperCase() +
                                                    " " +
                                                    user['Voornaam']
                                                        .toUpperCase(),
                                                user['ProfileImage'],
                                                connectedUserEmail,
                                                context,
                                                false);
                                          },
                                          title: Text(
                                            user['Naam'].toUpperCase() +
                                                " " +
                                                user['Voornaam'].toUpperCase(),
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                          trailing: isOnline(user['isOnline']),
                                          leading: CircleAvatar(
                                            child: ClipOval(
                                                child: Image.network(
                                                    user['ProfileImage'],
                                                    fit: BoxFit.fill)),
                                          ),
                                          subtitle: Text(
                                            lastMessage,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ));
                                      } else {
                                        return Container(
                                          color: GrijsMidden,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.05,
                                        );
                                      }
                                    });
                              }),
                        );
                      } else {
                        return Center(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.message,
                              size: 45,
                              color: Geel,
                            ),
                            Text("Je hebt geen gesprekken uitgevoerd...",
                                style: TextStyle(fontWeight: FontWeight.bold))
                          ],
                        ));
                      }
                    }),
              )
            : Center(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.message,
                    size: 45,
                    color: Geel,
                  ),
                  Text("Je hebt geen gesprekken uitgevoerd...",
                      style: TextStyle(fontWeight: FontWeight.bold))
                ],
              )));
  }

  isOnline(bool isOnline) {
    if (isOnline) {
      return Padding(
          padding: EdgeInsets.only(top: 15),
          child: Column(children: <Widget>[
            Icon(
              Icons.fiber_manual_record,
              color: Colors.green.withOpacity(0.5),
              semanticLabel: 'Online',
            )
          ]));
    } else {
      return Padding(
          padding: EdgeInsets.only(top: 15),
          child: Column(children: <Widget>[
            Icon(
              Icons.fiber_manual_record,
              color: Colors.red.withOpacity(0.5),
              semanticLabel: 'Offline',
            )
          ]));
    }
  }
}
