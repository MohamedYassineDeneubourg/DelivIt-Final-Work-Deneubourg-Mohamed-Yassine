import 'package:delivit/colors.dart';
import 'package:delivit/keuze.dart';
import 'package:delivit/register.dart';

import 'package:flutter/material.dart';

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
      home: Keuze(),
      //home: DelivitHomePage(title: "DelivIt"),
    );
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
                                if (phoneNo.length > 3) {
                                
                                  Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Register(phoneNumber: phoneNo,),
                                      ),
                                      (Route<dynamic> route) => false);
                                }
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
