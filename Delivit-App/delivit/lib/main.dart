import 'package:delivit/colors.dart';
import 'package:flutter/material.dart';
import 'package:international_phone_input/international_phone_input.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
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

  void onPhoneNumberChange(
      String number, String internationalizedPhoneNumber, String isoCode) {
        buttonColor = Geel;
    setState(() {
      phoneNumber = number;
      phoneIsoCode = isoCode;
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
                          Expanded(child: 
                          InternationalPhoneInput(
                              hintText: "Bv. 486 65 53 74",
                              errorText: "Foute gsm-nummer..",
                              onPhoneNumberChange: onPhoneNumberChange,
                              initialPhoneNumber: phoneNumber,
                              initialSelection: phoneIsoCode),),
                          IconButton(
                            icon: Icon(Icons.send,color: buttonColor,),
                            onPressed: () {},
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
