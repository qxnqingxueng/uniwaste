import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class PaymentService {
  Map<String, dynamic>? paymentIntent;

  // 1. Main function to handle the entire payment flow
  Future<bool> makePayment(double amount, String currency) async {
    try {
      // A. Create Payment Intent
      paymentIntent = await createPaymentIntent(amount, currency);

      // B. Initialize the Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent!['client_secret'],
          style: ThemeMode.light,
          merchantDisplayName: 'UniWaste',

          // ✅ REQUIRED for GrabPay/Alipay (App Switching)
          returnURL: 'flutterstripe://redirect',

          // ✅ Enable Apple Pay / Google Pay if configured
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'MY',
            testEnv: true,
          ),
        ),
      );

      // C. Show the Payment Sheet
      await displayPaymentSheet();
      return true; // Success
    } catch (e) {
      print("Payment Failed: $e");
      return false; // Failed
    }
  }

  // 2. Helper to display the sheet
  Future<void> displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      print("Payment Successful!");
    } on StripeException catch (e) {
      print('Error: $e');
      throw Exception(e.error.localizedMessage);
    }
  }

  // 3. Helper to talk to Stripe API
  createPaymentIntent(double amount, String currency) async {
    try {
      // Stripe expects amount in "cents" (e.g., RM 10.00 = 1000)
      int amountInCents = (amount * 100).toInt();

      Map<String, dynamic> body = {
        'amount': amountInCents.toString(),
        'currency': currency,
        // ✅ NEW: Enable Automatic Payment Methods (Includes Card, GrabPay, Alipay)
        'automatic_payment_methods[enabled]': 'true',
      };

      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['STRIPE_SECRET_KEY']}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );
      return jsonDecode(response.body);
    } catch (err) {
      print('Error creating payment intent: $err');
      throw Exception(err.toString());
    }
  }
}
