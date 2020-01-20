import 'package:delivit/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:international_phone_input/international_phone_input.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Delivit',
      theme: ThemeData(
        fontFamily: "Montserrat",
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Delivit'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String phoneNumber;
  String phoneIsoCode;
  String confirmedNumber;
  Color buttonColor = GrijsDark;
  String phoneNo;
  String smsOTP;
  String verificationId;
  String errorMessage = '';
  FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> verifyPhone() async {
    final PhoneCodeSent smsOTPSent = (String verId, [int forceCodeResend]) {
      this.verificationId = verId;
      smsOTPDialog(context).then((value) {
        print('sign in');
      });
    };
    try {
      await _auth.verifyPhoneNumber(
          phoneNumber: this.phoneNo, // PHONE NUMBER TO SEND OTP
          codeAutoRetrievalTimeout: (String verId) {
            //Starts the phone number verification process for the given phone number.
            //Either sends an SMS with a 6 digit code to the phone number specified, or sign's the user in and [verificationCompleted] is called.
            this.verificationId = verId;
          },
          codeSent:
              smsOTPSent, // WHEN CODE SENT THEN WE OPEN DIALOG TO ENTER OTP.
          timeout: const Duration(seconds: 20),
          verificationCompleted: (AuthCredential phoneAuthCredential) {
            print(phoneAuthCredential);
          },
          verificationFailed: (AuthException exceptio) {
            print('${exceptio.message}');
          });
    } catch (e) {
      handleError(e);
    }
  }

  Future<bool> smsOTPDialog(BuildContext context) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text('VOEG JE SMS-CODE',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: Container(
              height: 85,
              child: Column(children: [
                TextField(
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25),
                  onChanged: (value) {
                    this.smsOTP = value;
                  },
                ),
                (errorMessage != ''
                    ? Flexible(
                        child: Text(
                        errorMessage,
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 8,
                            fontWeight: FontWeight.bold),
                      ))
                    : Container())
              ]),
            ),
            contentPadding: EdgeInsets.all(20),
            actions: <Widget>[
              ButtonTheme(
                  minWidth: 400.0,
                  child: RaisedButton(
                    color: Geel,
                    child: Text(
                      "BEVESTIG CODE",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      _auth.currentUser().then((user) {
                        print("clickkk!");
                        if (user != null) {
                          print(user.email);
                          print(user.getIdToken());
                          print("Connected!");
                          Navigator.of(context).pop();
                          //  Navigator.of(context).pushReplacementNamed('/homepage');
                        } else {
                          signIn();
                        }
                      });
                    },
                  ))
            ],
          );
        });
  }

  signIn() async {
    try {
      print("yeah!");
      final AuthCredential credential = PhoneAuthProvider.getCredential(
        verificationId: verificationId,
        smsCode: smsOTP,
      );
      final FirebaseUser user =
          (await _auth.signInWithCredential(credential)).user;
      final FirebaseUser currentUser = await _auth.currentUser();
      assert(user.uid == currentUser.uid);
      Navigator.of(context).pop();

      //   Navigator.of(context).pushReplacementNamed('/homepage');
    } catch (e) {
      handleError(e);
    }
  }

  handleError(PlatformException error) {
    print(error);
    switch (error.code) {
      case 'ERROR_INVALID_VERIFICATION_CODE':
        FocusScope.of(context).requestFocus(new FocusNode());
        setState(() {
          errorMessage = 'De code is niet correct..';
        });
        Navigator.of(context).pop();
        smsOTPDialog(context).then((value) {
          print('sign in');
        });
        break;
      default:
        setState(() {
          errorMessage = error.message;
        });

        break;
    }
  }

  void onPhoneNumberChange(
      String number, String internationalizedPhoneNumber, String isoCode) {
    buttonColor = Geel;
    setState(() {
      phoneNumber = number;
      phoneIsoCode = isoCode;
      if (phoneIsoCode == "BE") {
        phoneNo = "+32" + phoneNumber;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Image.asset(
            'assets/images/backgroundLogin.jpg',
            width: size.width,
            height: size.height * 0.85,
            fit: BoxFit.cover,
          ),
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image(
                  image: AssetImage("assets/images/logo.png"),
                  width: size.width * 0.80,
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
                  bottom: size.height * 0.06, right: 20, left: 30),
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
                      borderRadius:
                          new BorderRadius.all(Radius.circular(10.0))),
                  child: Padding(
                      padding: EdgeInsets.only(right: 10, left: 10),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: InternationalPhoneInput(
                                hintText: "Bv. 486 65 53 74",
                                errorText: "Foute gsm-nummer..",
                                onPhoneNumberChange: onPhoneNumberChange,
                                initialPhoneNumber: phoneNumber,
                                initialSelection: "BE"),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.send,
                              color: buttonColor,
                            ),
                            onPressed: () {
                              if (phoneIsoCode == "BE") {
                                verifyPhone();
                                print("+32" + phoneNumber);
                              }
                            },
                          )
                        ],
                      ))),
            ),
          )
        ],
      ),
    );
  }
}
