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
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:square_in_app_payments/models.dart';
import 'package:square_in_app_payments/in_app_payments.dart';
import 'package:square_in_app_payments/google_pay_constants.dart'
    as google_pay_constants;
import 'package:todo_yassine/config.dart';
import 'package:todo_yassine/home.dart';
import 'package:uuid/uuid.dart';
import 'transaction_service.dart';
import 'dialog_modal.dart';
// We use a custom modal bottom sheet to override the default height (and remove it).
import 'modal_bottom_sheet.dart' as custom_modal_bottom_sheet;
import 'order_sheet.dart';

enum ApplePayStatus { success, fail, unknown }

class BuySheet extends StatefulWidget {
  static final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  @override
  BuySheetState createState() => BuySheetState();
}

class BuySheetState extends State<BuySheet> {
  static final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();
  bool applePayEnabled = true;
  bool googlePayEnabled = true;
  ApplePayStatus _applePayStatus = ApplePayStatus.unknown;

  bool get _chargeServerHostReplaced => chargeServerHost != "REPLACE_ME";

  bool get _squareLocationSet => squareLocationId != "REPLACE_ME";

  bool get _applePayMerchantIdSet => applePayMerchantId != "REPLACE_ME";

  Future<void> _initSquarePayment() async {
    await InAppPayments.setSquareApplicationId(squareApplicationId);
    var canUseApplePay = false;
    var canUseGooglePay = false;

    if (Platform.isAndroid) {
      await InAppPayments.initializeGooglePay(
          squareLocationId, google_pay_constants.environmentTest);
      canUseGooglePay = await InAppPayments.canUseGooglePay;
    } else if (Platform.isIOS) {
      //  await _setIOSCardEntryTheme();
      await InAppPayments.initializeApplePay(applePayMerchantId);
      canUseApplePay = await InAppPayments.canUseApplePay;
    }

    setState(() {
      applePayEnabled = canUseApplePay;
      googlePayEnabled = canUseGooglePay;
    });
  }

  @override
  void initState() {
    print("buysheet");
    _initSquarePayment();
    super.initState();
  }

  _showOrderSheet() async {
    print("show1");
    var selection =
        await custom_modal_bottom_sheet.showModalBottomSheet<PaymentType>(
            context: BuySheet.scaffoldKey.currentState.context,
            builder: (context) => OrderSheet(
                  applePayEnabled: applePayEnabled,
                  googlePayEnabled: googlePayEnabled,
                ));
    print("show2");
    switch (selection) {
      case PaymentType.cardPayment:
        await _onStartCardEntryFlow();
        break;
      case PaymentType.googlePay:
        if (_squareLocationSet && googlePayEnabled) {
          _onStartGooglePay();
        } else {
          _showSquareLocationIdNotSet();
        }
        break;
      case PaymentType.applePay:
        if (_applePayMerchantIdSet && applePayEnabled) {
          _onStartApplePay();
        } else {
          _showapplePayMerchantIdNotSet();
        }
        break;
    }

    print("show3");
  }

  void printCurlCommand(String nonce) {
    print('priiint');
    var hostUrl = 'https://connect.squareup.com';
    if (squareApplicationId.startsWith('sandbox')) {
      hostUrl = 'https://connect.squareupsandbox.com';
    }
    var uuid = Uuid().v4();
    print(
        'curl --request POST $hostUrl/v2/locations/$squareLocationId/transactions \\'
        '--header \"Content-Type: application/json\" \\'
        '--header \"Authorization: Bearer sandbox-sq0csb-R47LLWewScBKgpv04ZHA5y7rnshkV8hjUZsMi3cO3Zg\" \\'
        '--header \"Accept: application/json\" \\'
        '--data \'{'
        '\"idempotency_key\": \"$uuid\",'
        '\"amount_money\": {'
        '\"amount\": $prijs,'
        '\"currency\": \"USD\"},'
        '\"card_nonce\": \"$nonce\"'
        '}\'');
  }

  void _showUrlNotSetAndPrintCurlCommand(String nonce) {
    showAlertDialog(
        context: BuySheet.scaffoldKey.currentContext,
        title: "Nonce generated but not charged",
        description:
            "Check your console for a CURL command to charge the nonce, or replace CHARGE_SERVER_HOST with your server host.");
    printCurlCommand(nonce);
  }

  void _showSquareLocationIdNotSet() {
    showAlertDialog(
        context: BuySheet.scaffoldKey.currentContext,
        title: "Missing Square Location ID",
        description:
            "To request a Google Pay nonce, replace squareLocationId in main.dart with a Square Location ID.");
  }

  void _showapplePayMerchantIdNotSet() {
    showAlertDialog(
        context: BuySheet.scaffoldKey.currentContext,
        title: "Missing Apple Merchant ID",
        description:
            "To request an Apple Pay nonce, replace applePayMerchantId in main.dart with an Apple Merchant ID.");
  }

  void _onCardEntryComplete() {
    if (_chargeServerHostReplaced) {
      showAlertDialog(
          context: BuySheet.scaffoldKey.currentContext,
          title: "Betaling is voldaan.",
          description: "Betaling is voldaan. Check je account.");
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Home()),
          (Route<dynamic> route) => false);
    }
  }

  void _onCardEntryCardNonceRequestSuccess(CardDetails result) async {
    if (!_chargeServerHostReplaced) {
      InAppPayments.completeCardEntry(
          onCardEntryComplete: _onCardEntryComplete);
      return;
    }
    try {
      await chargeCard(result);
      InAppPayments.completeCardEntry(
          onCardEntryComplete: _onCardEntryComplete);
    } on ChargeException catch (ex) {
      InAppPayments.showCardNonceProcessingError(ex.errorMessage);
    }
  }

  Future<void> _onStartCardEntryFlow() async {
    await InAppPayments.startCardEntryFlow(
        onCardNonceRequestSuccess: _onCardEntryCardNonceRequestSuccess,
        onCardEntryCancel: _onCancelCardEntryFlow,
        collectPostalCode: true);
  }

  void _onCancelCardEntryFlow() {
    _showOrderSheet();
  }

  void _onStartGooglePay() async {
    try {
      await InAppPayments.requestGooglePayNonce(
          priceStatus: google_pay_constants.totalPriceStatusFinal,
          price: getPrijs(),
          currencyCode: 'USD',
          onGooglePayNonceRequestSuccess: _onGooglePayNonceRequestSuccess,
          onGooglePayNonceRequestFailure: _onGooglePayNonceRequestFailure,
          onGooglePayCanceled: onGooglePayEntryCanceled);
    } on PlatformException catch (ex) {
      showAlertDialog(
          context: BuySheet.scaffoldKey.currentContext,
          title: "Failed to start GooglePay",
          description: ex.toString());
    }
  }

  void _onGooglePayNonceRequestSuccess(CardDetails result) async {
    if (!_chargeServerHostReplaced) {
      _showUrlNotSetAndPrintCurlCommand(result.nonce);
      return;
    }
    try {
      await chargeCard(result);
      showAlertDialog(
          context: BuySheet.scaffoldKey.currentContext,
          title: "Your order was successful",
          description:
              "Go to your Square dashbord to see this order reflected in the sales tab.");
    } on ChargeException catch (ex) {
      showAlertDialog(
          context: BuySheet.scaffoldKey.currentContext,
          title: "Error processing GooglePay payment",
          description: ex.errorMessage);
    }
  }

  void _onGooglePayNonceRequestFailure(ErrorInfo errorInfo) {
    showAlertDialog(
        context: BuySheet.scaffoldKey.currentContext,
        title: "Failed to request GooglePay nonce",
        description: errorInfo.toString());
  }

  void onGooglePayEntryCanceled() {
    _showOrderSheet();
  }

  void _onStartApplePay() async {
    try {
      await InAppPayments.requestApplePayNonce(
          price: getPrijs(),
          summaryLabel: 'CREDIT TOEGEVOEGD YASS-TODOAPP',
          countryCode: 'USA',
          currencyCode: 'USD',
          paymentType: ApplePayPaymentType.finalPayment,
          onApplePayNonceRequestSuccess: _onApplePayNonceRequestSuccess,
          onApplePayNonceRequestFailure: _onApplePayNonceRequestFailure,
          onApplePayComplete: _onApplePayEntryComplete);
    } on PlatformException catch (ex) {
      showAlertDialog(
          context: BuySheet.scaffoldKey.currentContext,
          title: "Failed to start ApplePay",
          description: ex.toString());
    }
  }

  void _onApplePayNonceRequestSuccess(CardDetails result) async {
    if (!_chargeServerHostReplaced) {
      await InAppPayments.completeApplePayAuthorization(isSuccess: false);
      _showUrlNotSetAndPrintCurlCommand(result.nonce);
      return;
    }
    try {
      await chargeCard(result);
      _applePayStatus = ApplePayStatus.success;
      showAlertDialog(
          context: BuySheet.scaffoldKey.currentContext,
          title: "Your order was successful",
          description:
              "Go to your Square dashbord to see this order reflected in the sales tab.");
      await InAppPayments.completeApplePayAuthorization(isSuccess: true);
    } on ChargeException catch (ex) {
      await InAppPayments.completeApplePayAuthorization(
          isSuccess: false, errorMessage: ex.errorMessage);
      showAlertDialog(
          context: BuySheet.scaffoldKey.currentContext,
          title: "Error processing ApplePay payment",
          description: ex.errorMessage);
      _applePayStatus = ApplePayStatus.fail;
    }
  }

  void _onApplePayNonceRequestFailure(ErrorInfo errorInfo) async {
    _applePayStatus = ApplePayStatus.fail;
    await InAppPayments.completeApplePayAuthorization(
        isSuccess: false, errorMessage: errorInfo.message);
    showAlertDialog(
        context: BuySheet.scaffoldKey.currentContext,
        title: "Error request ApplePay nonce",
        description: errorInfo.toString());
  }

  void _onApplePayEntryComplete() {
    if (_applePayStatus == ApplePayStatus.unknown) {
      // the apple pay is canceled
      _showOrderSheet();
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
        key: BuySheet.scaffoldKey,
        appBar: new AppBar(
          centerTitle: true, 
          title: new Text("Betaling"),
        ),
        floatingActionButton: FloatingActionButton.extended(
            elevation: 4.0,
            icon: const Icon(Icons.payment),
            label: const Text('Bevestig bedrag'),
            onPressed: _showOrderSheet),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          child: new Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                icon: Icon(null),
                onPressed: () {},
              ),
            ],
          ),
        ),
        body: Builder(
            builder: (context) => Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                      Icon(Icons.monetization_on, size: 200),
                      Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Text(
                            "Geldkrediet",
                            style: TextStyle(fontSize: 45),
                          )),
                      Text(getPrijs(), style: TextStyle(fontSize: 20)),
                    ]))));
  }
}
