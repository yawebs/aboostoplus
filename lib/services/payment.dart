import 'package:flutter/material.dart';

import 'package:flutterwave_standard_smart/flutterwave.dart';

import '../const/constant.dart';

class Payment {
  Future payWithFlutterwave(
      BuildContext ctx, double amount, currency, email) async {
    // var keys = await DatabaseServices.flutterwaveKeys();
    // print('keys are ${keys['encryption']}');
    // String encryption = keys['encryption'];
    // String publicKey = keys['public'];
    // String encryptionTest = keys['test_encryption'];
    String publicKeyTest = 'YOUR_FLUTTERWAVE_TEST_PUBLIC_KEY';
    String testSecret = '' /* never put a Flutterwave secret key in the app */;
    String publicKeyLive = 'YOUR_FLUTTERWAVE_LIVE_PUBLIC_KEY';

    try {
      final Flutterwave flutterwave = Flutterwave(
        context: ctx,
        publicKey: publicKeyTest,
        currency: 'Ngn',
        redirectUrl: "www.google.com",
        txRef: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount.toString(),
        customer: Customer(email: email),
        paymentOptions: "ussd, card, barter, payattitude",
        customization: Customization(title: "My Payment"),
        isTestMode: true,
      );

      final ChargeResponse response = await flutterwave.charge();
      debugPrint('flutterwave response is $response');
      showToast(response.status!);
      return response;
    } catch (error) {
      // errorSn("Payment failed");
      print('Flutterwave Error $error');
      // return false;
    }
  }
}
