/*
 Copyright 2018 Square Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:square_in_app_payments/models.dart';
import 'package:http/http.dart' as http;
import 'package:todo_yassine/order_sheet.dart';

// Replace this with the server host you create, if you have your own server running
// e.g. https://server-host.com
String chargeServerHost = "https://yassinetodobackend.herokuapp.com";
String chargeUrl = "$chargeServerHost/betaalGeld";

class ChargeException implements Exception {
  String errorMessage;
  ChargeException(this.errorMessage);
}

Future<void> chargeCard(CardDetails result) async {
  var body = jsonEncode({"nonce": result.nonce, "price": prijs});
  print(prijs);
  http.Response response;
  try {
    response = await http.post(chargeUrl, body: body, headers: {
      "Accept": "application/json",
      "content-type": "application/json"
    });
  } on SocketException catch (ex) {
    throw ChargeException(ex.message);
  }
  print('status:');
  print(response.statusCode);
  var responseBody = json.decode(response.body);
  if (response.statusCode == 200) {
    int gekregenPrijs = responseBody['amount_money']['amount'];
    double teSturenPrijs = gekregenPrijs / 100;
    final FirebaseUser userData = await FirebaseAuth.instance.currentUser();
    String currentUserEmail = userData.email;
    Firestore.instance
        .collection('Users')
        .document(currentUserEmail)
        .updateData({"GeldEuro": FieldValue.increment(teSturenPrijs)}).then(
            (l) {
      print('BETAALD EN TOEGEVOEGD AAN ACCOUNT!');
    
    });

    //HIER FIREBASE FUNCTIE OM VARIABELE "PRIJS" TOETEVOEGEN AAN DE PORTEMONEE!!
    return;
  } else {
    print("error...");
    print(responseBody);
    throw ChargeException(responseBody["errorMessage"]);
  }
}
