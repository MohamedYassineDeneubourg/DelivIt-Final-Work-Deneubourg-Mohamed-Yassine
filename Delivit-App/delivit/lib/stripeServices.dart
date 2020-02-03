import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      print(response.body);
      String stripeId = jsonDecode(response.body)["id"];
      print("The stripe id is: $stripeId");
      var reference = Firestore.instance.collection("Users").document(email);

      reference.updateData({"stripeId": stripeId});

      return stripeId;
    }).catchError((err) {
      print("==== THERE WAS AN ERROR ====: ${err.toString()}");
      return null;
    });

    return stripeId;
  }

  Future<void> addCard(
      {int cardNumber,
      int month,
      int year,
      int cvc,
      String stripeId,
      String email}) async {
    print('addCard..');
    Map<String, dynamic> body = {
      "type": "card",
      "card[number]": cardNumber.toString(),
      "card[exp_month]": month.toString(),
      "card[exp_year]":year.toString(),
      "card[cvc]":cvc.toString()
    };
    print("Await http...");
    await http
        .post(PAYMENT_METHOD_URL, body: body, headers: headers,encoding: Encoding.getByName("formUrlEncodedContentType"))
        .then((response) {
          //print(response);
      var reference = Firestore.instance.collection("Users").document(email);

      reference.updateData({"stripeCard": body});
      Map data = json.decode(response.body);
      print(data['id']);
      String paymentMethod = data['id'];
      print("=== The payment mathod id id ===: $paymentMethod");
      http
          .post(
              "https://api.stripe.com/v1/payment_methods/$paymentMethod/attach",
              body: {"customer": stripeId},
              headers: headers)
          .then((response) {
        print("CODE ZERO");
      }).catchError((err) {
        print("ERROR ATTACHING CARD TO CUSTOMER");
        print("ERROR: ${err.toString()}");
      });
//      attachCard();
    }).catchError((err) {
      print("==== THERE WAS AN ERROR ====: ${err.toString()}");
    });
  }

  Future<void> charge({String customer, int amount}) async {
    Map<String, dynamic> data = {
      "amount": amount.toString(),
      "currency": "eur",
      "customer": customer
    };

    await http
        .post(
      CHARGE_URL,
      body: data,
      headers: headers,
    )
        .then((response) {
      print(response.body.toString());
    }).catchError((err) {
      print("There was an error charging the customer: ${err.toString()}");
    });
  }
}
