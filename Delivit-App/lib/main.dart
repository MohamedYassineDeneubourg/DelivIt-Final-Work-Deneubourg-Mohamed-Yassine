import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/Algemeen/keuze.dart';
import 'package:delivit/UI-elementen/loadingScreen.dart';
import 'package:delivit/globals.dart';
import 'package:delivit/login.dart';
import 'package:delivit/register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';

import 'package:international_phone_input/international_phone_input.dart';
import 'package:rxdart/rxdart.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Streams are created so that app can respond to notification-related events since the plugin is initialised in the `main` function
final BehaviorSubject<ReceivedNotification> didReceiveLocalNotificationSubject =
    BehaviorSubject<ReceivedNotification>();

final BehaviorSubject<String> selectNotificationSubject =
    BehaviorSubject<String>();

NotificationAppLaunchDetails notificationAppLaunchDetails;

class ReceivedNotification {
  ReceivedNotification({
    @required this.id,
    @required this.title,
    @required this.body,
    @required this.payload,
  });

  final String body;
  final int id;
  final String payload;
  final String title;
}

void startListeningToNotifications() {
  String connectedUserEmail;
  FirebaseAuth.instance.currentUser().then((data) {
    if (data != null) {
      connectedUserEmail = data.email;
      Firestore.instance
          .collection("Users")
          .document(data.email)
          .snapshots()
          .listen((e) {
        _gebruikerData = e.data;
      });
    }
  }).then((e) {
    if (connectedUserEmail != null) {
      //initPlatformState(connectedUserEmail);
      checkForNewMessages(connectedUserEmail);
      checkForCommandsUpdates(connectedUserEmail);
    }
  });
}

var _gebruikerData;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  notificationAppLaunchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  // Note: permissions aren't requested here just to demonstrate that can be done later using the `requestPermissions()` method
  // of the `IOSFlutterLocalNotificationsPlugin` class
  var initializationSettingsIOS = IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification:
          (int id, String title, String body, String payload) async {
        didReceiveLocalNotificationSubject.add(ReceivedNotification(
            id: id, title: title, body: body, payload: payload));
      });
  var initializationSettings = InitializationSettings(
      initializationSettingsAndroid, initializationSettingsIOS);
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onSelectNotification: (String payload) async {
      if (payload != null) {}
      selectNotificationSubject.add(payload);
    },
  );
  startListeningToNotifications();

  runApp(Main());
}

void checkForNewMessages(email) async {
  bool firstChecked = true;

  Firestore.instance
      .collection("Conversations")
      .where("Users", arrayContains: email)
      .snapshots()
      .listen((e) {
    e.documentChanges.forEach((e) {
      List messages = e.document.data["Messages"];
      List inConversations = _gebruikerData['inConversations']..addAll([]);
      if (!firstChecked &&
          messages.last['Auteur'] != email &&
          !(inConversations.contains(e.document.documentID))) {
        var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
          'com.example.delivit',
          'DelivIt',
          'Levering van boodschappen',
          playSound: true,
          enableVibration: true,
          importance: Importance.Max,
          priority: Priority.High,
        );
        var iOSPlatformChannelSpecifics = IOSNotificationDetails();
        var platformChannelSpecifics = NotificationDetails(
            androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

        flutterLocalNotificationsPlugin.show(
          0,
          messages.last['AuteurName'],
          messages.last['Message'],
          platformChannelSpecifics,
          payload: 'item x',
        );
      }
    });

    firstChecked = false;
  });
}

void checkForCommandsUpdates(email) async {
  bool firstChecked = true;
  Firestore.instance
      .collection("Commands")
      .where("Users", arrayContains: email)
      .snapshots()
      .listen((e) {
    e.documentChanges.forEach((e) {
      if (!firstChecked) {
        var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
          'be.hitutu.HiTutu',
          'HiTutu',
          'your channel description',
          playSound: true,
          enableVibration: true,
          importance: Importance.Max,
          priority: Priority.High,
        );
        var iOSPlatformChannelSpecifics = IOSNotificationDetails();
        var platformChannelSpecifics = NotificationDetails(
            androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
        flutterLocalNotificationsPlugin.show(
          0,
          "BESTELLING: " + e.document.data['BestellingStatus'],
          getDatumEnTijdToString(e.document.data['BezorgDatumEnTijd']) +
              " " +
              e.document.data['Adres'],
          platformChannelSpecifics,
          payload: 'item x',
        );
      }
    });

    firstChecked = false;
  });
}

class Main extends StatefulWidget {
  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> {
  bool userLoaded = false;
  Widget functie;
  String connectedUserMail;
  final navigatorKey = GlobalKey<NavigatorState>();
  void getCurrentUser() {
    FirebaseAuth.instance.currentUser().then((e) {
      setState(() {
        if (e != null) {
          setState(() {
            connectedUserMail = e.email;
          });

          //print(e.email);
        }

        setState(() {
          userLoaded = true;
        });
      });
    });
  }

  @override
  void initState() {
    getCurrentUser();

    super.initState();
  }

  redirectGebruiker() {
    if (userLoaded) {
      if (connectedUserMail != null) {
        //return getFunctie();
        return Keuze(
          connectedUserMail: connectedUserMail,
          redirect: true,
        );
      } else {
        return DelivitHomePage();
      }
    } else {
      return Scaffold(
          body: Container(
        child: SpinKitDoubleBounce(
          color: Geel,
          size: 100,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Delivit',
        theme: ThemeData(
          fontFamily: "Montserrat",
          primarySwatch: MaterialColor(Geel.value, {
            50: Colors.grey.shade50,
            100: Colors.grey.shade100,
            200: Colors.grey.shade200,
            300: Colors.grey.shade300,
            400: Colors.grey.shade400,
            500: Colors.grey.shade500,
            600: Colors.grey.shade600,
            700: Colors.grey.shade700,
            800: Colors.grey.shade800,
            900: Colors.grey.shade900
          }),
        ),
        debugShowCheckedModeBanner: false,
        home: redirectGebruiker());
    //home: Portefeuille());
  }
}

class DelivitHomePage extends StatefulWidget {
  DelivitHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _DelivitHomePageState createState() => _DelivitHomePageState();
}

class _DelivitHomePageState extends State<DelivitHomePage> {
  String phoneNumber;
  String phoneIsoCode;
  String confirmedNumber;
  Color buttonColor = GrijsDark;
  String phoneNo;
  bool isLoading = false;
  String connectedUserMail;
  Animation<double> animation;
  AnimationController animationController;
  BuildContext loadingContext;
  void getCurrentUser() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    //print(user);
    if (user != null) {
      setState(() {
        connectedUserMail = user.email;
      });
    } else {
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          isLoading = false;
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void onValidPhoneNumber(
      String number, String internationalizedPhoneNumber, String isoCode) {
    if (this.mounted) {
      setState(() {
        confirmedNumber = internationalizedPhoneNumber;
      });
    }
  }

  void onPhoneNumberChange(
      String number, String internationalizedPhoneNumber, String isoCode) {
    //VERWIJDER DE 0 ALS ER EEN IS IN HET BEGIN :
    if (number != "") {
      if (number[0] == "0" && number.length > 9) {
        number = number.substring(1);
      }
    }

    if (this.mounted) {
      setState(() {
        phoneNumber = number;

        phoneIsoCode = isoCode;
        if (phoneIsoCode == "BE") {
          phoneNo = "+32" + phoneNumber;
        }
        if (phoneNumber.length >= 9) {
          buttonColor = Geel;
        } else {
          buttonColor = GrijsDark;
        }
      });
    }
  }

  numerExists(phoneNumber) async {
    //print(phoneNumber);
    final query = await Firestore.instance
        .collection("Users")
        .where('PhoneNumber', isEqualTo: phoneNumber)
        .getDocuments();
    //print(query.documents.length);

    if (query.documents.length == 0) {
      //print('Nummer Bestaat niet!');
      setState(() {
        isLoading = false;
      });
      if (loadingContext != null) {
        Navigator.of(loadingContext).pop();
        loadingContext = null;
      }
      Navigator.push(
          context,
          SlideTopRoute(
            page: Register(
              phoneNumber: phoneNo,
            ),
          ));

      return null;
    }
    List<DocumentSnapshot> documents = query.documents;
    documents.forEach((object) {
      String emailVoorLogin = object.data['Email'];
      setState(() {
        isLoading = false;
      });
      if (loadingContext != null) {
        Navigator.of(loadingContext).pop();
        loadingContext = null;
      }
      Navigator.push(
          context,
          SlideTopRoute(
            page: Login(
              email: emailVoorLogin,
            ),
          ));

      return object.data['Email'];
    });
    //return null;
  }

  @override
  void dispose() {
    if (mounted) {
      super.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    //print("Builded..");
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: isLoading
          ? loadingScreen
          : GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(new FocusNode());
              },
              child: SingleChildScrollView(
                child: Center(
                  child: Column(
                    children: <Widget>[
                      AnimatedContainer(
                        margin: EdgeInsets.only(bottom: size.height*0.01),
                        decoration: BoxDecoration(
                            image: DecorationImage(
                          image: AssetImage(
                            'assets/images/backgroundLogin.jpg',
                          ),
                          fit: BoxFit.cover,
                        )),
                        height: size.height * ((MediaQuery.of(context).viewInsets.bottom == 0) ? 0.85 : 0.5),
                        padding: EdgeInsets.all(size.width * 0.1),
                        duration: Duration(milliseconds: 500),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Image(
                              image: AssetImage("assets/images/logo.png"),
                            ),
                            Text("Thuis, wat en wanneer je wilt",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10.0,
                                        color: Colors.black,
                                        offset: Offset(3.0, 3.0),
                                      ),
                                    ])),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: size.height * 0.03, right: 20, left: 30,),
                          child: Container(
                              decoration: new BoxDecoration(
                                  border: Border.all(color: GrijsLicht),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 1.0,
                                      color: GrijsMidden,
                                      offset: Offset(0.3, 0.3),
                                    ),
                                  ],
                                  borderRadius: new BorderRadius.all(
                                      Radius.circular(10.0))),
                              child: Padding(
                                  padding: EdgeInsets.only(right: 10, left: 10),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: !mounted
                                            ? null
                                            : InternationalPhoneInput(
                                                hintText: "Bv. 486 65 53 74",
                                                errorText: "Foute gsm-nummer..",
                                                onPhoneNumberChange:
                                                    onPhoneNumberChange,
                                                initialPhoneNumber: phoneNumber,
                                                initialSelection: "BE"),
                                      ),
                                      IconButton(
                                        enableFeedback: true,
                                        icon: Icon(
                                          FontAwesomeIcons.arrowAltCircleRight,
                                          color: buttonColor,
                                        ),
                                        onPressed: () {
                                          if (phoneIsoCode == "BE") {
                                            if (phoneNo.length > 8) {
                                              showDialog(
                                                barrierDismissible: false,
                                                context: context,
                                                builder: (BuildContext context) {
                                                  loadingContext = context;
                                                  return Container(
                                                    width: 200,
                                                    height: 200,
                                                    alignment: Alignment.center,
                                                    child: SpinKitDoubleBounce(
                                                      color: Geel,
                                                      size: 50,
                                                    ),
                                                  );
                                                },
                                              );
                                              Future.delayed(
                                                  const Duration(
                                                      milliseconds: 500), () {
                                                numerExists(phoneNo);
                                              });
                                            }
                                          }
                                        },
                                      )
                                    ],
                                  ))),
                        ),
                      )
                    ],
                  ),
                ),
              )),
    );
  }
}
