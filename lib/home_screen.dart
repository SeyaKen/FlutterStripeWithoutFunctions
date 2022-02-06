import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Mapを使うことで辞書型を作成できる。
  // Map<keyの値, valueの値>
  Map<String, dynamic>? paymentIntentData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stripe Payment'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InkWell(
              onTap: () async {
                await makePayment();
              },
              child: Container(
                  height: 50,
                  width: 200,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                  ),
                  child: const Center(child: Text('Pay'))),
            )
          ],
        ),
      ),
    );
  }

  Future<void> makePayment() async {
    try {
      paymentIntentData = await createPaymentIntent('20', 'JPY');
      print('payment intent'+paymentIntentData!['id'].toString());
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData!['client_secret'],
          applePay: false,
          googlePay: false,
          testEnv: true,
          style: ThemeMode.light,
          merchantCountryCode: 'JP',
          merchantDisplayName: 'My name',
        ),
      );
      displayPaymentSheet();
    } catch (e) {
      print('エラー' + e.toString());
    }
  }

  displayPaymentSheet() async {
    try {
      await Stripe.instance
          .presentPaymentSheet(
              parameters: PresentPaymentSheetParameters(
        clientSecret: paymentIntentData!['client_secret'],
        confirmPayment: true,
      ))
          .then((value) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Paid successfully')));

        paymentIntentData = null;
      });
    } on StripeException catch (e) {
      print(e.toString());
      showDialog(
          context: context,
          builder: (_) => const AlertDialog(
                content: Text('Cancelled'),
              ));
    }
  }

  createPaymentIntent(String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount),
        'currency': currency,
        'payment_method_types[]': 'card',
      };

      var response = await http.post(
          // ※テスト用URL
          Uri.parse('https://api.stripe.com/v1/payment_intents'),
          body: body,
          headers: {
            'Authorization':
                'Bearer ここにPrivaetKey',
            'Content-Type': 'application/x-www-form-urlencoded',
          });
      // jsonEncode=>json形式にデータを変換する
      // jsonDecode=>json形式のデータを元に戻す
      return jsonDecode(response.body.toString());
    } catch (e) {
      print('エラー' + e.toString());
    }
  }

  calculateAmount(String amount) {
    // int.parseで文字列を数字にする。
    final price = int.parse(amount) * 100;
    return price.toString();
  }
}