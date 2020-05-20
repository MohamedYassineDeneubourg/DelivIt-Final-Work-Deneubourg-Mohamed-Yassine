import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivit/globals.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StripeServices {
  static const PUBLISHABLE_KEY = "pk_test_BSPg6pigleBNqs9zFfQCDyAc00K4jhMtbI";
  static const SECRET_KEY = "sk_test_F5e3c7eflmciwcSsq2x6mJ0I00wfrDJjWo";
  static const PAYMENT_METHOD_URL = "https://api.stripe.com/v1/payment_methods";
  static const CUSTOMERS_URL = "https://api.stripe.com/v1/customers";
  static const CHARGE_URL = "https://api.stripe.com/v1/charges";
  Map<String, String> headers = {
    'Authorization': "Bearer  $SECRET_KEY",
    "Content-Type": "application/x-www-form-urlencoded"
  };

  Future<String> createStripeCustomer({String email, String userId}) async {
    Map<String, String> body = {
      'email': email,
    };

    String stripeId = await http
        .post(CUSTOMERS_URL, body: body, headers: headers)
        .then((response) {
      //print(response.body);
      String stripeId = jsonDecode(response.body)["id"];
      //print("The stripe id is: $stripeId");
      var reference = Firestore.instance.collection("Users").document(email);

      reference.updateData({"stripeId": stripeId});

      return stripeId;
    }).catchError((err) {
      //print("==== THERE WAS AN ERROR ====: ${err.toString()}");
      return null;
    });

    return stripeId;
  }

  Future<void> addCard({
    context,
    String cardNumber,
    String month,
    String year,
    String cvc,
    String stripeId,
    String email,
  }) async {
    //print('addCard..');
    Map<String, dynamic> body = {
      "type": "card",
      "card[number]": cardNumber,
      "card[exp_month]": month,
      "card[exp_year]": year,
      "card[cvc]": cvc,
    };

    //print("Await http...");
    await http
        .post(PAYMENT_METHOD_URL,
            body: body,
            headers: headers,
            encoding: Encoding.getByName("formUrlEncodedContentType"))
        .then((response) {
      ////print(response);

      Map data = json.decode(response.body);
      //print(data);
      if (data['error'] != null) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0))),
                title: new Text(
                  "Probleem met je kaart...",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: Text(
                    "Er is een probleem met je kaart, gelieve u informatie te wijzigen. " +
                        data['error']['code']),
                actions: <Widget>[
                  ButtonTheme(
                      minWidth: 400.0,
                      child: FlatButton(
                        color: Geel,
                        child: new Text(
                          "OK",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      )),
                ],
              );
            });
      } else {
        String paymentMethod = data['id'];
        //print("=== The payment mathod id id ===: $paymentMethod");
        http
            .post(
                "https://api.stripe.com/v1/payment_methods/$paymentMethod/attach",
                body: {"customer": stripeId},
                headers: headers)
            .then((response) {
          //print("CODE ZERO");
        }).catchError((err) {
          //print("ERROR ATTACHING CARD TO CUSTOMER");
          //print("ERROR: ${err.toString()}");
        });

        http
            .post("https://api.stripe.com/v1/setup_intents",
                body: {
                  "customer": stripeId,
                  "confirm": "true",
                  "payment_method": paymentMethod
                  // "default_payment_method": paymentMethod.toString(),
                },
                headers: headers)
            .then((response) {
          ////print(response.body.toString());
          body['type'] = data['card']['brand'];
          body['payment_method'] = paymentMethod;

          Map dataZ = json.decode(response.body);
          String id = dataZ['id'];
          //print(response.body.toString());
          //print('superoooook');
          http
              .post("https://api.stripe.com/v1/setup_intents/$id/confirm",
                  body: {"payment_method": paymentMethod}, headers: headers)
              .then((response) {
            //print(response.body.toString());
            //print('superok');
          }).catchError((err) {
            //print(err);
          });
          var reference =
              Firestore.instance.collection("Users").document(email);

          reference.updateData({"stripeCard": body});
          //print("OOOKKK!!");
          Navigator.of(context).pop();
        }).catchError((err) {
          //print("==== THERE WAS AN ERROR ====: ${err.toString()}");
        });
      }
    });
  }

  /* Future<void> charge({String customer, int amount}) async {
        Map<String, dynamic> data = {
          "amount": amount.toString(),
          "currency": "eur",
          "source": "pm_1G8Vh1BwklMzFWDBXP6FyFQg",
          "customer": customer
        };

        await http
            .post(
          CHARGE_URL,
          body: data,
          headers: headers,
        )
            .then((response) {
          //print(response.body.toString());
        }).catchError((err) {
          //print("There was an error charging the customer: ${err.toString()}");
        });
      } */

  Future<void> chargeIt(
      {context,
      String customer,
      int amount,
      String paymentMethod,
      String connectedUserEmail}) async {
    http
        .post("https://api.stripe.com/v1/payment_intents",
            body: {
              "amount": amount.toString(),
              "currency": "eur",
              "customer": customer,
              "confirm": "true",
              "payment_method": paymentMethod
              // "default_payment_method": paymentMethod.toString(),
            },
            headers: headers)
        .then((response) {
      ////print(response.body.toString());
      //  body['type'] = data['card']['brand'];
      //print(response.body.toString());
      //print('superoooook');
      Map dataZ = json.decode(response.body);
      String id = dataZ['id'];

      http
          .post("https://api.stripe.com/v1/setup_intents/$id/confirm",
              body: {
                "payment_method": paymentMethod
                // "default_payment_method": paymentMethod.toString(),
              },
              headers: headers)
          .then((response) {
        //print(response.body.toString());
        //print('superok');
        Firestore.instance
            .collection('Users')
            .document(connectedUserEmail)
            .updateData({
          "Portefeuille": (FieldValue.increment((amount / 100).toDouble())),
          "PortefeuilleHistoriek": FieldValue.arrayUnion(
            [
              {
                "BestellingId": "Kaart: Geld storting",
                "Datum": DateTime.now().toString(),
                "Type": "+",
                "TotalePrijs": (amount / 100).toDouble()
              },
            ],
          ),
        }).then((l) {
          //print('GELD IS GESTORT!');
          Navigator.pop(context);
        });
      }).catchError((err) {
        //print(err);
      });
    });
  }
}
