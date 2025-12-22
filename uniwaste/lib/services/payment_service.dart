import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  Future<bool> makePayment(BuildContext context, double amount) async {
    try {
      print("⚠️ CHECKPOINT 1: Starting makePayment");

      // 1. Create Payment Intent (Updated for GrabPay/Alipay)
      final paymentIntent = await _createPaymentIntent(
        (amount * 100).toInt().toString(),
        'myr',
      );

      if (paymentIntent == null) throw "Payment Intent is NULL";

      // 2. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'UniWaste Market',
          style: ThemeMode.light,

          // ✅ REQUIRED for GrabPay/Alipay redirects
          // This tells the app where to return after the user pays in the other app.
          returnURL: 'flutterstripe://redirect',
        ),
      );

      // 3. Display Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Payment Successful!"),
          backgroundColor: Colors.green,
        ),
      );
      return true;
    } on StripeException catch (e) {
      if (context.mounted) {
        // "Canceled" is normal if user closes the sheet
        if (e.error.code == FailureCode.Canceled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Payment Cancelled"),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Stripe Error: ${e.error.localizedMessage}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return false;
    } catch (e) {
      print("❌ GENERAL ERROR: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> _createPaymentIntent(
    String amount,
    String currency,
  ) async {
    try {
      final secretKey = dotenv.env['STRIPE_SECRET_KEY'];
      final url = Uri.parse('https://api.stripe.com/v1/payment_intents');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        // ✅ UPDATED BODY: Explicitly list Card, GrabPay, and Alipay
        body: {
          'amount': amount,
          'currency': currency,
          'payment_method_types[0]': 'card',
          'payment_method_types[1]': 'grabpay',
          'payment_method_types[2]': 'alipay',
          // FPX is intentionally omitted
        },
      );

      if (response.statusCode != 200) {
        print("❌ API ERROR: ${response.body}");
        return null;
      }

      return jsonDecode(response.body);
    } catch (e) {
      print("❌ API EXCEPTION: $e");
      return null;
    }
  }
}
